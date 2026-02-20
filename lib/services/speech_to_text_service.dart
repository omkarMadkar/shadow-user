import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Transcribes .wav audio files using **OpenAI Whisper** (via faster-whisper)
/// for top-tier offline speech recognition accuracy.
///
/// Uses the `medium` model (~1.5 GB, auto-downloaded on first run).
/// CTranslate2 backend with int8 quantization for fast CPU inference.
///
/// Non-English audio is automatically detected and rejected in a single pass.
///
/// Requirements (installed once):
///   pip install faster-whisper
///
/// No external API keys, no internet (after model download) — runs entirely offline.
class SpeechToTextService {
  static String? _scriptPath;
  static String? _pythonExe;

  /// Default Whisper model size. Options: tiny, base, small, medium, large-v3
  static const String _whisperModel = 'medium';

  // ── Persistent Server State ─────────────────────────────
  // Keeps the Whisper model loaded in memory between transcription
  // requests, eliminating 3-8s of model-load overhead per chunk.
  static Process? _serverProcess;
  static StreamSubscription<String>? _stdoutSub;
  static StreamSubscription<String>? _stderrSub;
  static Completer<String>? _pendingResult;
  static bool _serverReady = false;
  static bool _serverStarting = false;

  /// Locate the Python executable and transcription script. Cached across calls.
  static Future<void> _ensurePaths() async {
    if (_scriptPath != null && _pythonExe != null) return;

    // Python script ships in the project's scripts/ folder.
    // Try several common locations:
    final candidates = <String>[
      // 1. In current working directory (flutter run from project root)
      p.join(Directory.current.path, 'scripts', 'whisper_transcribe.py'),
      // 2. Next to the executable (release / MSIX)
      p.join(
        p.dirname(Platform.resolvedExecutable),
        'scripts',
        'whisper_transcribe.py',
      ),
    ];

    for (final c in candidates) {
      if (File(c).existsSync()) {
        _scriptPath = c;
        break;
      }
    }

    // If none found, write an embedded copy into a temp location.
    _scriptPath ??= await _writeEmbeddedScript();

    // Resolve Python
    _pythonExe = await _findPython();
  }

  /// Try to find a working Python 3 executable **with faster-whisper installed**.
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
        // Verify faster-whisper is importable
        try {
          final r = await Process.run(venv, [
            '-c',
            'import faster_whisper',
          ], runInShell: true);
          if (r.exitCode == 0) {
            debugPrint('[SpeechToText] Using venv Python: $venv');
            return venv;
          }
        } catch (_) {}
      }
    }

    // 2. Fallback: system Python
    for (final exe in ['python', 'python3', 'py -3']) {
      try {
        final r = await Process.run(exe.split(' ').first, [
          ...exe.split(' ').skip(1),
          '-c',
          'import faster_whisper',
        ], runInShell: true);
        if (r.exitCode == 0) return exe;
      } catch (_) {}
    }

    debugPrint(
      '[SpeechToText] WARNING: could not find Python with faster-whisper',
    );
    return 'python'; // fallback
  }

  /// Write the Whisper transcription script into a temp directory
  /// as a fallback if the scripts/ folder is not found at runtime.
  static Future<String> _writeEmbeddedScript() async {
    final tempDir = Directory.systemTemp;
    final dest = p.join(tempDir.path, 'shadow_sentinel_whisper_transcribe.py');
    final file = File(dest);
    if (!file.existsSync()) {
      await file.writeAsString(_embeddedPython);
      debugPrint('[SpeechToText] Wrote embedded Whisper script → $dest');
    }
    return dest;
  }

  // ── Persistent Server Management ────────────────────────

  /// Locate the persistent server script (whisper_server.py).
  static String? _findServerScript() {
    final candidates = <String>[
      p.join(Directory.current.path, 'scripts', 'whisper_server.py'),
      p.join(
        p.dirname(Platform.resolvedExecutable),
        'scripts',
        'whisper_server.py',
      ),
    ];
    for (final c in candidates) {
      if (File(c).existsSync()) return c;
    }
    return null;
  }

  /// Start the persistent Whisper server subprocess.
  ///
  /// The server loads the model once and keeps it in memory,
  /// accepting transcription requests via stdin/stdout protocol.
  /// Returns `true` if the server is ready to accept requests.
  static Future<bool> _startServer() async {
    if (_serverReady && _serverProcess != null) return true;
    if (_serverStarting) return false;
    _serverStarting = true;

    try {
      await _ensurePaths();
      final serverScript = _findServerScript();
      if (serverScript == null) {
        debugPrint(
          '[SpeechToText] Server script not found, using one-shot mode',
        );
        _serverStarting = false;
        return false;
      }

      final exe = _pythonExe!.split(' ').first;
      final args = <String>[
        ..._pythonExe!.split(' ').skip(1),
        serverScript,
        '--model',
        _whisperModel,
        '--language',
        'en',
      ];

      debugPrint('[SpeechToText] Starting persistent Whisper server...');
      _serverProcess = await Process.start(exe, args, runInShell: true);

      final readyCompleter = Completer<bool>();

      // Listen for server responses on stdout
      _stdoutSub = _serverProcess!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            if (line == 'READY' && !readyCompleter.isCompleted) {
              debugPrint('[SpeechToText] Persistent server READY');
              _serverReady = true;
              readyCompleter.complete(true);
            } else if (line == 'BYE') {
              debugPrint('[SpeechToText] Server acknowledged shutdown');
            } else if (_pendingResult != null && !_pendingResult!.isCompleted) {
              _pendingResult!.complete(line);
            }
          });

      // Forward server stderr for debugging
      _stderrSub = _serverProcess!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            debugPrint('[SpeechToText/Server] $line');
          });

      // Handle unexpected process exit
      _serverProcess!.exitCode.then((code) {
        debugPrint('[SpeechToText] Server process exited (code $code)');
        _serverReady = false;
        _serverProcess = null;
        _stdoutSub?.cancel();
        _stderrSub?.cancel();
        if (!readyCompleter.isCompleted) readyCompleter.complete(false);
      });

      // Wait for READY signal (model loading can take 10-30s on first run)
      final ready = await readyCompleter.future.timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          debugPrint('[SpeechToText] Server startup timed out');
          return false;
        },
      );

      _serverStarting = false;
      return ready;
    } catch (e) {
      debugPrint('[SpeechToText] Failed to start persistent server: $e');
      _serverStarting = false;
      return false;
    }
  }

  /// Transcribe via the persistent server subprocess.
  /// Sends the wav path on stdin and reads the result from stdout.
  static Future<String> _transcribeViaServer(String wavPath) async {
    if (!_serverReady || _serverProcess == null) {
      throw StateError('Server not running');
    }

    _pendingResult = Completer<String>();
    _serverProcess!.stdin.writeln('TRANSCRIBE:$wavPath');
    await _serverProcess!.stdin.flush();

    final response = await _pendingResult!.future.timeout(
      const Duration(seconds: 120),
      onTimeout: () => 'ERROR:Transcription timed out',
    );

    if (response.startsWith('RESULT:')) {
      final text = response.substring(7);
      debugPrint('[SpeechToText] Server result: $text');
      return text;
    } else if (response.startsWith('EMPTY:')) {
      debugPrint('[SpeechToText] Server: no speech detected');
      return '';
    } else if (response.startsWith('ERROR:')) {
      debugPrint('[SpeechToText] Server error: ${response.substring(6)}');
      return '';
    }
    return '';
  }

  // ── Public API ──────────────────────────────────────────

  /// Transcribe a PCM `.wav` file at [wavPath] into text using Whisper.
  ///
  /// Tries the **persistent server** first (model stays loaded in memory,
  /// ~2-4s per 15s chunk). Falls back to **one-shot mode** (spawns a new
  /// process per chunk, ~5-12s) if the server is unavailable.
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

      debugPrint(
        '[SpeechToText] Transcribing with Whisper ($_whisperModel): '
        '$wavPath ($fileSize bytes)',
      );

      // ── Try persistent server first ──
      try {
        if (!_serverReady) {
          await _startServer();
        }
        if (_serverReady) {
          return await _transcribeViaServer(wavPath);
        }
      } catch (e) {
        debugPrint('[SpeechToText] Persistent server failed: $e');
        _serverReady = false;
      }

      // ── Fallback: one-shot mode ──
      debugPrint('[SpeechToText] Falling back to one-shot mode');
      return await _transcribeOneShot(wavPath);
    } catch (e) {
      debugPrint('[SpeechToText] Exception: $e');
      return '';
    }
  }

  /// One-shot transcription: spawns a new Python process per chunk.
  /// Used as fallback when the persistent server is unavailable.
  static Future<String> _transcribeOneShot(String wavPath) async {
    await _ensurePaths();

    final args = <String>[
      ..._pythonExe!.split(' ').skip(1),
      _scriptPath!,
      wavPath,
      '--model',
      _whisperModel,
      '--language',
      'en',
    ];
    final exe = _pythonExe!.split(' ').first;

    final result = await Process.run(exe, args, runInShell: true);

    if (result.exitCode == 0) {
      final text = (result.stdout as String).trim();
      if (text.isNotEmpty) {
        debugPrint('[SpeechToText] Whisper result: $text');
      } else {
        debugPrint('[SpeechToText] No speech recognised in audio');
      }
      return text;
    } else {
      final err = (result.stderr as String).trim();
      debugPrint(
        '[SpeechToText] Whisper error (exit ${result.exitCode}): $err',
      );
      return '';
    }
  }

  /// Gracefully shut down the persistent server process.
  ///
  /// Should be called when the app is closing or the voice module
  /// is being disposed to free the ~1.5 GB of model memory.
  static Future<void> shutdown() async {
    if (_serverProcess != null) {
      debugPrint('[SpeechToText] Shutting down persistent server...');
      try {
        _serverProcess!.stdin.writeln('QUIT');
        await _serverProcess!.stdin.flush();
        // Give the server 5 seconds to exit gracefully
        await _serverProcess!.exitCode.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('[SpeechToText] Server did not exit, killing process');
            _serverProcess?.kill();
            return -1;
          },
        );
      } catch (_) {
        _serverProcess?.kill();
      }
      _serverProcess = null;
      _serverReady = false;
      _serverStarting = false;
      await _stdoutSub?.cancel();
      await _stderrSub?.cancel();
      _stdoutSub = null;
      _stderrSub = null;
      debugPrint('[SpeechToText] Server shutdown complete');
    }
  }

  // ── Embedded Python script (fallback) ────────────────────
  // Minified version of scripts/whisper_transcribe.py
  static const _embeddedPython = r'''
import sys,os,struct,wave,argparse,re
SILENCE_RMS=200
HALLU={"thank you","thanks for watching","thanks for listening","please subscribe","like and subscribe","you","the","i","it","a","bye","thank you for watching","see you next time","subtitles by the amara.org community","transcribed by https","translated by","so","okay","ok","yeah","yes","no","hmm","um","uh","ah","oh","music","music playing"}
FILLER={"the","a","i","it","is","to","that","of","on","and","in","but","he","she","we","you","so","um","uh","hmm","oh","ah","like","just"}
def rms(raw,sw):
    if sw!=2 or len(raw)<2: return 0.0
    n=len(raw)//2; fmt="<{}h".format(n); s=struct.unpack(fmt,raw)
    return (sum(x*x for x in s)/len(s))**0.5
def is_hallu(t):
    c=re.sub(r'[^\w\s\']','',t.strip().lower()).strip()
    if not c or c in HALLU: return True
    for p in HALLU:
        if c.startswith(p) and len(c)<len(p)+15: return True
    w=c.split()
    if len(w)<3: return True
    if len(set(w))==1 and len(w)<=8: return True
    fc=sum(1 for x in w if x in FILLER)
    if len(w)>0 and fc/len(w)>0.65: return True
    if len(w)>=6:
        h=len(w)//2
        if " ".join(w[:h])==" ".join(w[h:h*2]): return True
    for ng in range(2,min(6,len(w)//2+1)):
        gram=" ".join(w[:ng]); rc=0
        for i in range(0,len(w)-ng+1,ng):
            if " ".join(w[i:i+ng])==gram: rc+=1
        if rc>=3: return True
    return False
def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("wav_path")
    parser.add_argument("--model",default="medium")
    parser.add_argument("--language",default="en")
    parser.add_argument("--model-dir",default=None)
    args=parser.parse_args()
    if not os.path.isfile(args.wav_path):
        print(f"WAV not found: {args.wav_path}",file=sys.stderr); sys.exit(1)
    wf=wave.open(args.wav_path,"rb"); params=wf.getparams(); raw=wf.readframes(wf.getnframes()); wf.close()
    if rms(raw,params.sampwidth)<SILENCE_RMS: sys.exit(0)
    try:
        from faster_whisper import WhisperModel
    except ImportError:
        print("faster-whisper not installed",file=sys.stderr); sys.exit(1)
    mk={"model_size_or_path":args.model,"device":"cpu","compute_type":"int8"}
    if args.model_dir: mk["download_root"]=args.model_dir
    model=WhisperModel(**mk)
    el=args.language.lower()
    segs,info=model.transcribe(args.wav_path,language=None,beam_size=3,best_of=2,patience=1.2,vad_filter=True,vad_parameters=dict(min_silence_duration_ms=300,speech_pad_ms=250,threshold=0.35,min_speech_duration_ms=200),condition_on_previous_text=False,no_speech_threshold=0.5,log_prob_threshold=-0.8,compression_ratio_threshold=2.2,temperature=[0.0,0.2,0.4],word_timestamps=True,initial_prompt="This is a real-time voice monitoring system recording. The speaker is using natural conversational English. Transcribe exactly what is said, including any profanity or hostile language.")
    parts=[]; lc=False
    for seg in segs:
        if not lc:
            lc=True
            if info.language!=el:
                print(f"[LANG_REJECT] Detected '{info.language}' (conf:{info.language_probability:.2f})",file=sys.stderr); sys.exit(0)
            if info.language_probability<0.5:
                print(f"[LANG_REJECT] conf too low: {info.language_probability:.2f}",file=sys.stderr); sys.exit(0)
        t=seg.text.strip()
        if not t or seg.no_speech_prob>0.45: continue
        if seg.words:
            avg=sum(w.probability for w in seg.words)/len(seg.words)
            if avg<0.45: continue
            t=" ".join(w.word.strip() for w in seg.words if w.probability>=0.40).strip()
        if t: parts.append(t)
    full=re.sub(r'\s+',' '," ".join(parts)).strip()
    full=re.sub(r'[^\w\s\',\.\-!?]','',full).strip()
    if full and not is_hallu(full): print(full)
if __name__=="__main__": main()
''';
}
