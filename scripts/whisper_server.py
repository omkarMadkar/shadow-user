"""
Persistent Whisper transcription server for Shadow Sentinel.

Keeps the Whisper model loaded in memory between transcription requests,
eliminating 3-8s of model-load overhead per chunk.

Protocol (line-based, over stdin/stdout):
  Server → Client:  READY                     (model loaded, ready for requests)
  Client → Server:  TRANSCRIBE:<wav_path>      (request transcription)
  Server → Client:  RESULT:<text>              (transcription succeeded)
  Server → Client:  EMPTY:                     (no speech / silence / hallucination)
  Server → Client:  ERROR:<message>            (error occurred)
  Client → Server:  QUIT                       (shutdown server)
  Server → Client:  BYE                        (acknowledging shutdown)

Usage:
    python whisper_server.py [--model medium] [--language en]

The model is loaded ONCE on startup and reused for all subsequent requests.
This saves 3-8 seconds of model-loading overhead per transcription.
"""

import sys
import os
import struct
import wave
import argparse
import re


# ── Audio Preprocessing ────────────────────────────────────

SILENCE_RMS_THRESHOLD = 200


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


# ── Single-Chunk Transcription ─────────────────────────────

def transcribe_wav(model, wav_path, expected_lang):
    """Transcribe a single WAV file using an already-loaded model.

    Returns the transcribed text, or an empty string if nothing was
    recognised, the audio was silent, or a hallucination was detected.
    """
    if not os.path.isfile(wav_path):
        raise FileNotFoundError(f"WAV file not found: {wav_path}")

    # Quick silence check
    raw_bytes, params = read_wav_pcm(wav_path)
    energy = rms_energy(raw_bytes, params.sampwidth)
    if energy < SILENCE_RMS_THRESHOLD:
        return ""

    # Single-pass transcription with auto language detection
    segments, info = model.transcribe(
        wav_path,
        language=None,
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
            "Transcribe exactly what is said, including any profanity "
            "or hostile language."
        ),
    )

    all_text_parts = []
    language_checked = False

    for segment in segments:
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
                return ""

            if lang_prob < 0.5:
                print(
                    f"[LANG_REJECT] {expected_lang} confidence too low: "
                    f"{lang_prob:.2f}",
                    file=sys.stderr,
                )
                return ""

        text = segment.text.strip()
        if not text:
            continue

        if segment.no_speech_prob > 0.45:
            continue

        if segment.words:
            avg_conf = (
                sum(w.probability for w in segment.words) / len(segment.words)
            )
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

    # Clean up artifacts
    full_text = re.sub(r'\s+', ' ', full_text)
    full_text = re.sub(r'[^\w\s\',.\-!?]', '', full_text).strip()

    # Final hallucination check
    if full_text and not is_hallucination(full_text):
        return full_text

    return ""


# ── Server Main Loop ──────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Persistent Whisper transcription server for Shadow Sentinel"
    )
    parser.add_argument(
        "--model", default="medium",
        help="Whisper model size (default: medium)",
    )
    parser.add_argument(
        "--language", default="en",
        help="Expected language code (default: en)",
    )
    parser.add_argument(
        "--model-dir", default=None,
        help="Directory to cache downloaded models (default: auto)",
    )

    args = parser.parse_args()
    expected_lang = args.language.lower()

    # ── Load model ONCE ────────────────────────────────────
    try:
        from faster_whisper import WhisperModel
    except ImportError:
        print("ERROR:faster-whisper not installed", flush=True)
        sys.exit(1)

    model_kwargs = {
        "model_size_or_path": args.model,
        "device": "cpu",
        "compute_type": "int8",
    }
    if args.model_dir:
        model_kwargs["download_root"] = args.model_dir

    try:
        print(
            f"Loading Whisper model '{args.model}'...",
            file=sys.stderr,
        )
        model = WhisperModel(**model_kwargs)
        print(
            f"Model '{args.model}' loaded successfully.",
            file=sys.stderr,
        )
    except Exception as e:
        print(f"ERROR:Failed to load model: {e}", flush=True)
        sys.exit(1)

    # ── Signal ready ───────────────────────────────────────
    print("READY", flush=True)

    # ── Process requests ───────────────────────────────────
    while True:
        try:
            line = sys.stdin.readline()
            if not line:
                # stdin closed (parent process died)
                break

            line = line.strip()
            if not line:
                continue

            if line == "QUIT":
                print("BYE", flush=True)
                break

            if line.startswith("TRANSCRIBE:"):
                wav_path = line[len("TRANSCRIBE:"):]
                try:
                    text = transcribe_wav(model, wav_path, expected_lang)
                    if text:
                        print(f"RESULT:{text}", flush=True)
                    else:
                        print("EMPTY:", flush=True)
                except FileNotFoundError as e:
                    print(f"ERROR:{e}", flush=True)
                except Exception as e:
                    print(f"ERROR:Transcription failed: {e}", flush=True)
            else:
                print(f"ERROR:Unknown command: {line}", flush=True)

        except KeyboardInterrupt:
            break
        except Exception as e:
            print(f"ERROR:Server error: {e}", flush=True)


if __name__ == "__main__":
    main()
