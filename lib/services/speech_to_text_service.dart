import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Transcribes .wav audio files using the **Vosk** offline speech recognition
/// engine via a small Python helper script.
///
/// Requirements (installed once):
///   pip install vosk
///   Vosk model at: <Documents>/shadow_sentinel/vosk_model/
///
/// No external API keys, no internet — runs entirely offline.
class SpeechToTextService {
  static String? _modelPath;
  static String? _scriptPath;
  static String? _pythonExe;

  /// Locate the Vosk model directory, Python executable, and transcription
  /// script. Cached across calls.
  static Future<void> _ensurePaths() async {
    if (_modelPath != null && _scriptPath != null && _pythonExe != null) return;

    // Model lives next to the voice_chunks folder
    final appDir = await getApplicationDocumentsDirectory();
    _modelPath = p.join(appDir.path, 'shadow_sentinel', 'vosk_model');

    // Python script ships in the project's scripts/ folder.
    // At runtime the working directory is the project root, so we can
    // resolve the script relative to the executable's directory or use
    // the absolute path baked at build time.  For dev mode (flutter run)
    // we use the workspace-relative path.
    //
    // Try several common locations:
    final candidates = <String>[
      // 1. In current working directory (flutter run from project root)
      p.join(Directory.current.path, 'scripts', 'vosk_transcribe.py'),
      // 2. Next to the executable (release / MSIX)
      p.join(
        p.dirname(Platform.resolvedExecutable),
        'scripts',
        'vosk_transcribe.py',
      ),
      // 3. Fallback — asset copy beside model
      p.join(appDir.path, 'shadow_sentinel', 'vosk_transcribe.py'),
    ];

    for (final c in candidates) {
      if (File(c).existsSync()) {
        _scriptPath = c;
        break;
      }
    }

    // If none found, write an embedded copy into the documents folder.
    _scriptPath ??= await _writeEmbeddedScript(appDir.path);

    // Resolve Python
    _pythonExe = await _findPython();
  }

  /// Try to find a working Python 3 executable **with Vosk installed**.
  /// Prefers the project .venv first, then falls back to system Python.
  static Future<String> _findPython() async {
    // 1. Check the project .venv (works in dev mode via flutter run)
    final venvCandidates = <String>[
      p.join(Directory.current.path, '.venv', 'Scripts', 'python.exe'),
      p.join(Directory.current.path, '.venv', 'bin', 'python'),
      p.join(
        p.dirname(Platform.resolvedExecutable),
        '.venv',
        'Scripts',
        'python.exe',
      ),
    ];

    for (final venv in venvCandidates) {
      if (File(venv).existsSync()) {
        // Verify Vosk is importable
        try {
          final r = await Process.run(venv, [
            '-c',
            'import vosk',
          ], runInShell: true);
          if (r.exitCode == 0) {
            debugPrint('[SpeechToText] Using venv Python: $venv');
            return venv;
          }
        } catch (_) {}
      }
    }

    // 2. Fallback: system Python (user may have installed vosk globally)
    for (final exe in ['python', 'python3', 'py -3']) {
      try {
        final r = await Process.run(exe.split(' ').first, [
          ...exe.split(' ').skip(1),
          '-c',
          'import vosk',
        ], runInShell: true);
        if (r.exitCode == 0) return exe;
      } catch (_) {}
    }

    debugPrint('[SpeechToText] WARNING: could not find Python with Vosk');
    return 'python'; // fallback
  }

  /// Write the Vosk transcription script into the documents directory
  /// as a fallback if the scripts/ folder is not found at runtime.
  static Future<String> _writeEmbeddedScript(String appDirPath) async {
    final dest = p.join(appDirPath, 'shadow_sentinel', 'vosk_transcribe.py');
    final file = File(dest);
    if (!file.existsSync()) {
      await file.writeAsString(_embeddedPython);
      debugPrint('[SpeechToText] Wrote embedded Vosk script → $dest');
    }
    return dest;
  }

  /// Transcribe a PCM `.wav` file at [wavPath] into text using Vosk.
  ///
  /// Returns the transcribed text, or an empty string if nothing was
  /// recognised or an error occurred.
  static Future<String> transcribeWav(String wavPath) async {
    try {
      // Verify the file exists and has content
      final file = File(wavPath);
      if (!await file.exists()) {
        debugPrint('[SpeechToText] File not found: $wavPath');
        return '';
      }
      final fileSize = await file.length();
      if (fileSize < 1000) {
        debugPrint('[SpeechToText] File too small ($fileSize bytes): $wavPath');
        return '';
      }

      await _ensurePaths();

      // Verify model directory exists
      if (!Directory(_modelPath!).existsSync()) {
        debugPrint('[SpeechToText] Vosk model not found at: $_modelPath');
        return '';
      }

      debugPrint('[SpeechToText] Transcribing: $wavPath ($fileSize bytes)');

      final args = <String>[
        ..._pythonExe!.split(' ').skip(1),
        _scriptPath!,
        _modelPath!,
        wavPath,
      ];
      final exe = _pythonExe!.split(' ').first;

      final result = await Process.run(exe, args, runInShell: true);

      if (result.exitCode == 0) {
        final text = (result.stdout as String).trim();
        if (text.isNotEmpty) {
          debugPrint('[SpeechToText] Result: $text');
        } else {
          debugPrint('[SpeechToText] No speech recognised in audio');
        }
        return text;
      } else {
        final err = (result.stderr as String).trim();
        debugPrint('[SpeechToText] Vosk error (exit ${result.exitCode}): $err');
        return '';
      }
    } catch (e) {
      debugPrint('[SpeechToText] Exception: $e');
      return '';
    }
  }

  // ── Embedded Python script (fallback) ────────────────────
  static const _embeddedPython = r'''
import sys, json, wave, os
def main():
    if len(sys.argv) < 3:
        print("Usage: vosk_transcribe.py <model_path> <wav_path>", file=sys.stderr)
        sys.exit(1)
    model_path, wav_path = sys.argv[1], sys.argv[2]
    if not os.path.isdir(model_path):
        print(f"Model not found: {model_path}", file=sys.stderr); sys.exit(1)
    if not os.path.isfile(wav_path):
        print(f"WAV not found: {wav_path}", file=sys.stderr); sys.exit(1)
    try:
        from vosk import Model, KaldiRecognizer, SetLogLevel
    except ImportError:
        print("vosk not installed", file=sys.stderr); sys.exit(1)
    SetLogLevel(-1)
    model = Model(model_path)
    wf = wave.open(wav_path, "rb")
    rec = KaldiRecognizer(model, wf.getframerate())
    rec.SetWords(True)
    results = []
    while True:
        data = wf.readframes(4000)
        if len(data) == 0: break
        if rec.AcceptWaveform(data):
            r = json.loads(rec.Result())
            t = r.get("text","").strip()
            if t: results.append(t)
    final = json.loads(rec.FinalResult())
    t = final.get("text","").strip()
    if t: results.append(t)
    wf.close()
    full = " ".join(results)
    if full: print(full)
if __name__=="__main__": main()
''';
}
