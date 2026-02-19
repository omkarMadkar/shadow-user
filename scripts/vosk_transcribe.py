"""
Vosk offline speech-to-text transcription script.
Called by Shadow Sentinel's SpeechToTextService.

Usage:
    python vosk_transcribe.py <model_path> <wav_path>

Outputs the recognised text to stdout (one line).
"""

import sys
import json
import wave
import os

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

    model = Model(model_path)
    wf = wave.open(wav_path, "rb")

    # Verify format
    if wf.getnchannels() != 1:
        print(f"Expected mono audio, got {wf.getnchannels()} channels", file=sys.stderr)
        sys.exit(1)

    sample_rate = wf.getframerate()
    rec = KaldiRecognizer(model, sample_rate)
    rec.SetWords(True)

    results = []
    while True:
        data = wf.readframes(4000)
        if len(data) == 0:
            break
        if rec.AcceptWaveform(data):
            result = json.loads(rec.Result())
            text = result.get("text", "").strip()
            if text:
                results.append(text)

    # Get any remaining audio
    final = json.loads(rec.FinalResult())
    text = final.get("text", "").strip()
    if text:
        results.append(text)

    wf.close()

    full_text = " ".join(results)
    if full_text:
        print(full_text)


if __name__ == "__main__":
    main()
