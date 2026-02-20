"""
OpenAI Whisper offline speech-to-text transcription script.
Called by Shadow Sentinel's SpeechToTextService.

Uses `faster-whisper` (CTranslate2 backend) for 4× faster inference
than the official OpenAI Whisper implementation, with identical accuracy.

Usage:
    python whisper_transcribe.py <wav_path> [--model medium] [--language en]

Outputs the recognised text to stdout (one line).
Prints [LANG_REJECT] to stderr and exits cleanly if non-English is detected.

Features:
  - OpenAI Whisper medium model (best accuracy/speed trade-off for real-time)
  - Auto-downloads model on first run (~1.5 GB for medium)
  - Single-pass language detection + transcription (no double processing)
  - Silence detection to skip empty chunks
  - VAD filtering to remove non-speech segments
  - Hallucination detection (phrases, n-gram loops, filler ratio)
  - Word-level confidence filtering
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


SILENCE_RMS_THRESHOLD = 200


def read_wav_pcm(wav_path):
    """Read a WAV file and return (raw_bytes, params)."""
    wf = wave.open(wav_path, "rb")
    params = wf.getparams()
    raw = wf.readframes(wf.getnframes())
    wf.close()
    return raw, params


# ── Hallucination Detection ────────────────────────────────

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
    cleaned = re.sub(r'[^\w\s\']', '', text.strip().lower()).strip()

    if not cleaned:
        return True

    if cleaned in HALLUCINATION_PHRASES:
        return True

    for phrase in HALLUCINATION_PHRASES:
        if cleaned.startswith(phrase) and len(cleaned) < len(phrase) + 15:
            return True

    words = cleaned.split()

    if len(words) < 3:
        return True

    if len(set(words)) == 1 and len(words) <= 8:
        return True

    filler_count = sum(1 for w in words if w in FILLER_WORDS)
    if len(words) > 0 and filler_count / len(words) > 0.65:
        return True

    # Repeated halves
    if len(words) >= 6:
        half = len(words) // 2
        if " ".join(words[:half]) == " ".join(words[half:half * 2]):
            return True

    # Detect repeating n-gram loops
    for ngram_size in range(2, min(6, len(words) // 2 + 1)):
        ngram = " ".join(words[:ngram_size])
        repeat_count = 0
        for i in range(0, len(words) - ngram_size + 1, ngram_size):
            if " ".join(words[i:i + ngram_size]) == ngram:
                repeat_count += 1
        if repeat_count >= 3:
            return True

    return False


# ── Main ───────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Whisper offline speech-to-text for Shadow Sentinel"
    )
    parser.add_argument("wav_path", help="Path to the WAV file to transcribe")
    parser.add_argument(
        "--model", default="medium",
        help="Whisper model size (default: medium)"
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

    # 1. Quick silence check
    raw_bytes, params = read_wav_pcm(wav_path)
    energy = rms_energy(raw_bytes, params.sampwidth)
    if energy < SILENCE_RMS_THRESHOLD:
        sys.exit(0)

    # 2. Import faster-whisper
    try:
        from faster_whisper import WhisperModel
    except ImportError:
        print("faster-whisper not installed. Run: pip install faster-whisper",
              file=sys.stderr)
        sys.exit(1)

    # 3. Load model (cached in ~/.cache/huggingface/)
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

    # 4. Single-pass transcription with auto language detection
    #    We let Whisper detect the language in the SAME pass as transcription.
    #    No separate detection pass = no double processing.
    expected_lang = args.language.lower()

    segments, info = model.transcribe(
        wav_path,
        language=None,  # Auto-detect language in this same pass
        beam_size=3,
        best_of=2,
        patience=1.2,
        vad_filter=True,
        vad_parameters=dict(
            min_silence_duration_ms=300,
            speech_pad_ms=250,
            threshold=0.35,
            min_speech_duration_ms=200,
        ),
        condition_on_previous_text=False,
        no_speech_threshold=0.5,
        log_prob_threshold=-0.8,
        compression_ratio_threshold=2.2,
        temperature=[0.0, 0.2, 0.4],
        word_timestamps=True,
        initial_prompt=(
            "This is a real-time voice monitoring system recording. "
            "The speaker is using natural conversational English. "
            "Transcribe exactly what is said, including any profanity or hostile language."
        ),
    )

    # 5. Collect results with confidence filtering
    #    We consume the generator and also check language after first segment.
    all_text_parts = []
    language_checked = False

    for segment in segments:
        # Check language from info after first segment is yielded
        if not language_checked:
            language_checked = True
            detected_lang = info.language
            lang_prob = info.language_probability

            if detected_lang != expected_lang:
                print(
                    f"[LANG_REJECT] Detected '{detected_lang}' "
                    f"(conf: {lang_prob:.2f}), expected '{expected_lang}'",
                    file=sys.stderr,
                )
                sys.exit(0)

            if lang_prob < 0.5:
                print(
                    f"[LANG_REJECT] {expected_lang} confidence too low: "
                    f"{lang_prob:.2f}",
                    file=sys.stderr,
                )
                sys.exit(0)

        text = segment.text.strip()
        if not text:
            continue

        if segment.no_speech_prob > 0.45:
            continue

        if segment.words:
            avg_conf = sum(w.probability for w in segment.words) / len(segment.words)
            if avg_conf < 0.45:
                continue

            good_words = [
                w.word.strip() for w in segment.words
                if w.probability >= 0.40
            ]
            text = " ".join(good_words).strip()

        if text:
            all_text_parts.append(text)

    full_text = " ".join(all_text_parts).strip()

    # 6. Clean up artifacts
    full_text = re.sub(r'\s+', ' ', full_text)
    full_text = re.sub(r'[^\w\s\',.\-!?]', '', full_text).strip()

    # 7. Final hallucination check
    if full_text and not is_hallucination(full_text):
        print(full_text)


if __name__ == "__main__":
    main()
