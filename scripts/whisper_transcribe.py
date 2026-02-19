"""
OpenAI Whisper offline speech-to-text transcription script.
Called by Shadow Sentinel's SpeechToTextService.

Uses `faster-whisper` (CTranslate2 backend) for 4× faster inference
than the official OpenAI Whisper implementation, with identical accuracy.

Usage:
    python whisper_transcribe.py <wav_path> [--model medium] [--language en]

Outputs the recognised text to stdout (one line).

Features:
  - OpenAI Whisper model (medium by default — best accuracy/speed balance)
  - Auto-downloads model on first run (~1.5 GB for medium)
  - Silence detection to skip empty chunks
  - VAD filtering to remove non-speech segments
  - Hallucination detection for near-silence
  - Runs entirely offline after model download
"""

import sys
import os
import struct
import wave
import argparse

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
SILENCE_RMS_THRESHOLD = 200  # Slightly lower than Vosk — Whisper handles quiet audio better


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
    "transcribed by https",
}

FILLER_WORDS = {
    "the", "a", "i", "it", "is", "to", "that", "of", "on",
    "and", "in", "but", "he", "she", "we", "you", "so",
}


def is_hallucination(text):
    """Return True if the transcribed text is likely a Whisper hallucination."""
    cleaned = text.strip().lower()
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
    if len(set(words)) == 1 and len(words) <= 6:
        return True

    # Mostly filler words (>70% are common noise words)
    filler_count = sum(1 for w in words if w in FILLER_WORDS)
    if len(words) > 0 and filler_count / len(words) > 0.70:
        return True

    # Repeated exact phrases — Whisper sometimes loops
    if len(words) >= 6:
        half = len(words) // 2
        first_half = " ".join(words[:half])
        second_half = " ".join(words[half:half * 2])
        if first_half == second_half:
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
        help="Whisper model size: tiny, base, small, medium, large-v3 (default: medium)"
    )
    parser.add_argument(
        "--language", default="en",
        help="Language code (default: en)"
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
    #    - "medium" is ~1.5GB, auto-downloaded from HuggingFace on first run
    #    - Uses int8 quantization on CPU for speed
    #    - Model is cached in ~/.cache/huggingface/ by default
    model_kwargs = {
        "model_size_or_path": args.model,
        "device": "cpu",
        "compute_type": "int8",  # Fast on CPU, minimal quality loss
    }
    if args.model_dir:
        model_kwargs["download_root"] = args.model_dir

    try:
        model = WhisperModel(**model_kwargs)
    except Exception as e:
        print(f"Failed to load Whisper model '{args.model}': {e}", file=sys.stderr)
        sys.exit(1)

    # 4. Transcribe with optimised settings
    #    - beam_size=5 for better accuracy (default is 1 for speed)
    #    - vad_filter=True to skip non-speech segments (reduces hallucinations)
    #    - condition_on_previous_text=False to prevent hallucination loops
    segments, info = model.transcribe(
        wav_path,
        language=args.language,
        beam_size=5,
        best_of=5,
        patience=1.5,
        vad_filter=True,
        vad_parameters=dict(
            min_silence_duration_ms=500,
            speech_pad_ms=300,
            threshold=0.35,
        ),
        condition_on_previous_text=False,
        no_speech_threshold=0.6,
        log_prob_threshold=-1.0,
        compression_ratio_threshold=2.4,
        temperature=[0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
        word_timestamps=True,
    )

    # 5. Collect results with confidence filtering
    all_text_parts = []
    for segment in segments:
        text = segment.text.strip()
        if not text:
            continue

        # Filter low-confidence segments
        if segment.no_speech_prob > 0.5:
            continue

        # Filter by average word confidence if available
        if segment.words:
            avg_conf = sum(w.probability for w in segment.words) / len(segment.words)
            if avg_conf < 0.40:
                continue

            # Also filter out individual low-confidence words
            good_words = [
                w.word.strip() for w in segment.words
                if w.probability >= 0.35
            ]
            text = " ".join(good_words).strip()

        if text:
            all_text_parts.append(text)

    full_text = " ".join(all_text_parts).strip()

    # 6. Final hallucination check
    if full_text and not is_hallucination(full_text):
        print(full_text)


if __name__ == "__main__":
    main()
