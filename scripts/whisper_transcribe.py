"""
OpenAI Whisper offline speech-to-text transcription script.
Called by Shadow Sentinel's SpeechToTextService.

Uses `faster-whisper` (CTranslate2 backend) for 4× faster inference
than the official OpenAI Whisper implementation, with identical accuracy.

Usage:
    python whisper_transcribe.py <wav_path> [--model large-v3] [--language en]

Outputs the recognised text to stdout (one line).

Features:
  - OpenAI Whisper large-v3 model (best accuracy available)
  - Auto-downloads model on first run (~3 GB for large-v3)
  - Language detection: automatically rejects non-English audio
  - Silence detection to skip empty chunks
  - VAD filtering to remove non-speech segments
  - Hallucination detection for near-silence
  - Word-level confidence filtering
  - Repetition / looping detection
  - Runs entirely offline after model download
"""

import sys
import os
import struct
import wave
import argparse
import re

# ── Audio Preprocessing ────────────────────────────────────

def rms_energy(raw_bytes, sample_width):
    """Compute RMS energy of 16-bit PCM audio."""
    if sample_width != 2 or len(raw_bytes) < 2:
        return 0.0
    n_samples = len(raw_bytes) // 2
    fmt = "<{}h".format(n_samples)
    samples = struct.unpack(fmt, raw_bytes)
    if not samples:
        return 0.0
    sum_sq = sum(s * s for s in samples)
    return (sum_sq / len(samples)) ** 0.5


# Threshold: below this RMS the audio is considered silence/noise.
SILENCE_RMS_THRESHOLD = 180  # Slightly lower for large-v3 — handles quiet audio better


def read_wav_pcm(wav_path):
    """Read a WAV file and return (raw_bytes, params)."""
    wf = wave.open(wav_path, "rb")
    params = wf.getparams()
    raw = wf.readframes(wf.getnframes())
    wf.close()
    return raw, params


# ── Hallucination Detection ────────────────────────────────

# Common Whisper hallucination phrases on near-silence or noise
HALLUCINATION_PHRASES = {
    "thank you", "thanks for watching", "thanks for listening",
    "please subscribe", "like and subscribe",
    "you", "the", "i", "it", "a", "bye",
    "thank you for watching", "see you next time",
    "subtitles by the amara.org community",
    "transcribed by https", "translated by",
    "amara org", "this video is",
    "so", "okay", "ok", "yeah", "yes", "no",
    "hmm", "um", "uh", "ah", "oh",
    "music", "music playing",
}

FILLER_WORDS = {
    "the", "a", "i", "it", "is", "to", "that", "of", "on",
    "and", "in", "but", "he", "she", "we", "you", "so",
    "um", "uh", "hmm", "oh", "ah", "like", "just",
}


def is_hallucination(text):
    """Return True if the transcribed text is likely a Whisper hallucination."""
    cleaned = text.strip().lower()
    # Strip any special characters that Whisper sometimes inserts
    cleaned = re.sub(r'[^\w\s\']', '', cleaned).strip()

    if not cleaned:
        return True

    # Known Whisper hallucination phrases
    if cleaned in HALLUCINATION_PHRASES:
        return True

    # Check if text starts with a known hallucination prefix
    for phrase in HALLUCINATION_PHRASES:
        if cleaned.startswith(phrase) and len(cleaned) < len(phrase) + 15:
            return True

    words = cleaned.split()

    # Very short transcriptions from 30-second chunks are suspicious
    if len(words) < 3:
        return True

    # All words identical (e.g. "the the the")
    if len(set(words)) == 1 and len(words) <= 8:
        return True

    # Mostly filler words (>65% are common noise words)
    filler_count = sum(1 for w in words if w in FILLER_WORDS)
    if len(words) > 0 and filler_count / len(words) > 0.65:
        return True

    # Repeated exact phrases — Whisper sometimes loops
    if len(words) >= 6:
        half = len(words) // 2
        first_half = " ".join(words[:half])
        second_half = " ".join(words[half:half * 2])
        if first_half == second_half:
            return True

    # Detect repeating n-gram loops (e.g., "hello world hello world hello world")
    for ngram_size in range(2, min(6, len(words) // 2 + 1)):
        ngram = " ".join(words[:ngram_size])
        repeat_count = 0
        for i in range(0, len(words) - ngram_size + 1, ngram_size):
            chunk = " ".join(words[i:i + ngram_size])
            if chunk == ngram:
                repeat_count += 1
        if repeat_count >= 3:
            return True

    return False


# ── Language Detection ─────────────────────────────────────

# Minimum confidence that the detected language is English.
ENGLISH_CONFIDENCE_THRESHOLD = 0.5


def detect_language_quick(model, wav_path):
    """
    Use Whisper's built-in language detection on the audio.
    Returns (language_code, probability).
    """
    try:
        segments, info = model.transcribe(
            wav_path,
            language=None,  # Auto-detect
            beam_size=1,    # Fast detection pass
            best_of=1,
            vad_filter=True,
            vad_parameters=dict(
                min_silence_duration_ms=500,
                threshold=0.40,
            ),
        )
        # Consume first segment to populate info
        _ = next(segments, None)
        return info.language, info.language_probability
    except Exception as e:
        print(f"Language detection error: {e}", file=sys.stderr)
        return "en", 0.0


# ── Main ───────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Whisper offline speech-to-text for Shadow Sentinel"
    )
    parser.add_argument("wav_path", help="Path to the WAV file to transcribe")
    parser.add_argument(
        "--model", default="large-v3",
        help="Whisper model size: tiny, base, small, medium, large-v3 (default: large-v3)"
    )
    parser.add_argument(
        "--language", default="en",
        help="Expected language code — non-matching audio is rejected (default: en)"
    )
    parser.add_argument(
        "--model-dir", default=None,
        help="Directory to cache downloaded models (default: auto)"
    )

    args = parser.parse_args()

    wav_path = args.wav_path
    if not os.path.isfile(wav_path):
        print(f"WAV file not found: {wav_path}", file=sys.stderr)
        sys.exit(1)

    # 1. Quick silence check — skip processing if audio is nearly silent
    raw_bytes, params = read_wav_pcm(wav_path)
    energy = rms_energy(raw_bytes, params.sampwidth)
    if energy < SILENCE_RMS_THRESHOLD:
        sys.exit(0)  # Exit cleanly with no output

    # 2. Import faster-whisper
    try:
        from faster_whisper import WhisperModel
    except ImportError:
        print("faster-whisper not installed. Run: pip install faster-whisper",
              file=sys.stderr)
        sys.exit(1)

    # 3. Load model
    #    - "large-v3" is ~3GB, auto-downloaded from HuggingFace on first run
    #    - Uses int8 quantization on CPU for speed
    #    - Model is cached in ~/.cache/huggingface/ by default
    model_kwargs = {
        "model_size_or_path": args.model,
        "device": "cpu",
        "compute_type": "int8",
    }
    if args.model_dir:
        model_kwargs["download_root"] = args.model_dir

    try:
        model = WhisperModel(**model_kwargs)
    except Exception as e:
        print(f"Failed to load Whisper model '{args.model}': {e}", file=sys.stderr)
        sys.exit(1)

    # 4. Language detection gate — reject non-English audio
    expected_lang = args.language.lower()
    detected_lang, lang_prob = detect_language_quick(model, wav_path)

    if detected_lang != expected_lang:
        print(
            f"[LANG_REJECT] Detected '{detected_lang}' (conf: {lang_prob:.2f}), "
            f"expected '{expected_lang}'. Ignoring.",
            file=sys.stderr,
        )
        sys.exit(0)

    if lang_prob < ENGLISH_CONFIDENCE_THRESHOLD:
        print(
            f"[LANG_REJECT] English confidence too low: {lang_prob:.2f}. Ignoring.",
            file=sys.stderr,
        )
        sys.exit(0)

    # 5. Full transcription with maximum accuracy settings
    segments, info = model.transcribe(
        wav_path,
        language=expected_lang,       # Force English for accurate transcription
        beam_size=5,
        best_of=5,
        patience=2.0,                 # More patient = more thorough beam search
        vad_filter=True,
        vad_parameters=dict(
            min_silence_duration_ms=400,
            speech_pad_ms=350,
            threshold=0.30,            # Lower to catch softer speech
            min_speech_duration_ms=250,
        ),
        condition_on_previous_text=False,
        no_speech_threshold=0.5,
        log_prob_threshold=-0.8,
        compression_ratio_threshold=2.2,
        temperature=[0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
        word_timestamps=True,
        repetition_penalty=1.2,
        initial_prompt=(
            "This is a real-time voice monitoring system recording. "
            "The speaker is using natural conversational English. "
            "Transcribe exactly what is said, including any profanity or hostile language."
        ),
    )

    # 6. Collect results with strict confidence filtering
    all_text_parts = []
    for segment in segments:
        text = segment.text.strip()
        if not text:
            continue

        # Filter high no-speech probability segments
        if segment.no_speech_prob > 0.45:
            continue

        # Filter by average word confidence
        if segment.words:
            avg_conf = sum(w.probability for w in segment.words) / len(segment.words)
            if avg_conf < 0.45:
                continue

            # Filter out individual low-confidence words
            good_words = [
                w.word.strip() for w in segment.words
                if w.probability >= 0.40
            ]
            text = " ".join(good_words).strip()

        if text:
            all_text_parts.append(text)

    full_text = " ".join(all_text_parts).strip()

    # 7. Clean up common Whisper artifacts
    full_text = re.sub(r'\s+', ' ', full_text)
    full_text = re.sub(r'[^\w\s\',.\-!?]', '', full_text).strip()

    # 8. Final hallucination check
    if full_text and not is_hallucination(full_text):
        print(full_text)


if __name__ == "__main__":
    main()
