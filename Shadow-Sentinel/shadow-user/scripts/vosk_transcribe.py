"""
Vosk offline speech-to-text transcription script.
Called by Shadow Sentinel's SpeechToTextService.

Usage:
    python vosk_transcribe.py <model_path> <wav_path>

Outputs the recognised text to stdout (one line).

Accuracy features:
  - Audio volume normalisation (peak → -3 dBFS)
  - Low-confidence word filtering (drops words < 0.35 confidence)
  - Larger frame reads (8000) for better decoder context
"""

import sys
import json
import wave
import os
import struct
import io

# ── Audio Preprocessing ────────────────────────────────────

def rms_energy(raw_bytes, sample_width):
    """Compute RMS energy of 16-bit PCM audio."""
    if sample_width != 2 or len(raw_bytes) < 2:
        return 0.0
    fmt = "<{}h".format(len(raw_bytes) // 2)
    samples = struct.unpack(fmt, raw_bytes)
    if not samples:
        return 0.0
    sum_sq = sum(s * s for s in samples)
    return (sum_sq / len(samples)) ** 0.5


# Threshold: below this RMS the audio is considered silence/noise.
# 16-bit range is 0–32767; typical quiet room noise is ~50–200 RMS.
SILENCE_RMS_THRESHOLD = 250


def normalize_audio(raw_bytes, sample_width):
    """Normalise audio volume so the peak reaches ~-3 dBFS."""
    if sample_width == 2:
        fmt = "<{}h".format(len(raw_bytes) // 2)
        samples = list(struct.unpack(fmt, raw_bytes))
    else:
        return raw_bytes  # only handle 16-bit PCM

    peak = max(abs(s) for s in samples) if samples else 0
    if peak == 0:
        return raw_bytes  # silence

    # Target: 70 % of max int16 (~-3 dBFS)
    target = int(32767 * 0.70)
    factor = target / peak
    # Don't amplify more than 10× to avoid boosting pure noise
    factor = min(factor, 10.0)
    normalised = [max(-32768, min(32767, int(s * factor))) for s in samples]
    return struct.pack(fmt, *normalised)


def preprocess_wav(wav_path):
    """Read a WAV, normalise volume, return (audio_bytes, params)."""
    wf = wave.open(wav_path, "rb")
    params = wf.getparams()
    raw = wf.readframes(wf.getnframes())
    wf.close()

    if params.nchannels != 1:
        print(f"Expected mono audio, got {params.nchannels} channels", file=sys.stderr)
        sys.exit(1)

    normalised = normalize_audio(raw, params.sampwidth)
    return normalised, params


# ── Confidence Filtering ───────────────────────────────────

MIN_WORD_CONFIDENCE = 0.35  # drop words below this confidence


def filter_by_confidence(result_dict):
    """
    If the result contains per-word confidence scores, discard
    low-confidence words and return the cleaned text.
    Falls back to the plain 'text' field when word info is absent.
    """
    words = result_dict.get("result", [])
    if not words:
        return result_dict.get("text", "").strip()

    kept = [w["word"] for w in words if w.get("conf", 1.0) >= MIN_WORD_CONFIDENCE]
    return " ".join(kept).strip()


# Common hallucination patterns Vosk produces on near-silence
HALLUCINATION_PATTERNS = {
    "the", "the the", "a", "i", "it", "but", "and", "in",
    "is", "to", "that", "of", "on", "he", "she", "we",
}


def is_hallucination(text):
    """Return True if the transcribed text is likely a noise hallucination."""
    cleaned = text.strip().lower()
    if not cleaned:
        return True
    # Very short text that matches known filler hallucinations
    if cleaned in HALLUCINATION_PATTERNS:
        return True
    words = cleaned.split()
    # All words identical (e.g. "the the the")
    if len(set(words)) == 1 and len(words) <= 6:
        return True
    # Fewer than 4 meaningful words in a 30-second chunk is suspicious
    if len(words) < 4:
        return True
    # Mostly filler words (>70% are hallucination words)
    filler_count = sum(1 for w in words if w in HALLUCINATION_PATTERNS)
    if len(words) > 0 and filler_count / len(words) > 0.70:
        return True
    return False


# ── Main ───────────────────────────────────────────────────

def main():
    if len(sys.argv) < 3:
        print("Usage: vosk_transcribe.py <model_path> <wav_path>", file=sys.stderr)
        sys.exit(1)

    model_path = sys.argv[1]
    wav_path = sys.argv[2]

    if not os.path.isdir(model_path):
        print(f"Model not found: {model_path}", file=sys.stderr)
        sys.exit(1)

    if not os.path.isfile(wav_path):
        print(f"WAV file not found: {wav_path}", file=sys.stderr)
        sys.exit(1)

    # Import vosk here so errors are caught cleanly
    try:
        from vosk import Model, KaldiRecognizer, SetLogLevel
    except ImportError:
        print("vosk package not installed. Run: pip install vosk", file=sys.stderr)
        sys.exit(1)

    # Suppress Vosk's internal logging to keep stdout clean
    SetLogLevel(-1)

    # 1. Preprocess: read audio and check for silence
    audio_bytes, params = preprocess_wav(wav_path)
    sample_rate = params.framerate
    sample_width = params.sampwidth

    # Skip near-silent audio (avoids hallucinations on quiet chunks)
    energy = rms_energy(audio_bytes, sample_width)
    if energy < SILENCE_RMS_THRESHOLD:
        # Audio is too quiet — likely no speech
        sys.exit(0)  # exit cleanly with no output

    # 2. Normalise volume
    audio_bytes = normalize_audio(audio_bytes, sample_width)

    # 3. Load model & recognizer
    model = Model(model_path)
    rec = KaldiRecognizer(model, sample_rate)
    rec.SetWords(True)

    # 3. Feed audio in larger chunks (8000 frames ≈ 0.5s) for better context
    frame_size = sample_width  # bytes per frame for mono
    chunk_frames = 8000
    chunk_bytes = chunk_frames * frame_size
    offset = 0
    results = []

    while offset < len(audio_bytes):
        data = audio_bytes[offset : offset + chunk_bytes]
        offset += chunk_bytes
        if rec.AcceptWaveform(data):
            result = json.loads(rec.Result())
            text = filter_by_confidence(result)
            if text:
                results.append(text)

    # Get any remaining audio
    final = json.loads(rec.FinalResult())
    text = filter_by_confidence(final)
    if text:
        results.append(text)

    full_text = " ".join(results)
    # Filter out hallucinations from near-silent audio
    if full_text and not is_hallucination(full_text):
        print(full_text)


if __name__ == "__main__":
    main()
