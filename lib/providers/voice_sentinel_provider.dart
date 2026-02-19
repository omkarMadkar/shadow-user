import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/models.dart';
import '../database/voice_database.dart';
import '../services/mic_monitor_service.dart';
import '../services/speech_to_text_service.dart';

/// Voice Sentinel provider — manages mic monitoring, language analysis,
/// waveform data, and persists voice sessions/alerts to SQLite via Drift.
///
/// Records **real audio in 30-second chunks** via the `record` package,
/// transcribes each chunk using the Windows built-in Speech Recognition
/// engine (System.Speech.Recognition), and feeds the real transcription
/// into the live translation display and summary cards.
class VoiceSentinelProvider extends ChangeNotifier {
  final Random _rng = Random();
  final VoiceDatabase _db = VoiceDatabase();

  // ── Real Recording ───────────────────────────────────────
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  String? _chunksDir;

  /// Currently playing chunk file path (null if not playing).
  String? _playingChunkPath;
  String? get playingChunkPath => _playingChunkPath;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  // ── OS Mic Monitor ───────────────────────────────────────
  final MicMonitorService _micMonitor = MicMonitorService();
  StreamSubscription<List<MicUsageInfo>>? _micMonitorSub;
  List<MicUsageInfo> _externalMicApps = [];
  List<MicUsageInfo> get externalMicApps => List.unmodifiable(_externalMicApps);
  bool get externalMicDetected => _externalMicApps.isNotEmpty;

  bool _autoProtectEnabled = true;
  bool get autoProtectEnabled => _autoProtectEnabled;

  // ── Live Transcription ───────────────────────────────────
  final List<TranscriptionSegment> _transcriptSegments = [];
  List<TranscriptionSegment> get transcriptSegments =>
      List.unmodifiable(_transcriptSegments);

  String _liveTranscriptBuffer = '';
  String get liveTranscriptBuffer => _liveTranscriptBuffer;

  bool _isTranscribing = false;
  bool get isTranscribing => _isTranscribing;

  Timer? _wordTimer;
  int _currentWordIndex = 0;
  List<String> _currentWords = [];

  // ── Translation Summaries ────────────────────────────────
  final List<TranslationSummary> _translationSummaries = [];
  List<TranslationSummary> get translationSummaries =>
      List.unmodifiable(_translationSummaries);

  // ── Chunk Recording ──────────────────────────────────────
  /// Duration in seconds for each audio chunk.
  static const int chunkDurationSeconds = 30;

  int _currentChunkNumber = 0;
  int _chunkSecondsElapsed = 0;
  String? _currentChunkPath;
  bool _isTranscribingChunk = false;

  int get chunkSecondsElapsed => _chunkSecondsElapsed;
  bool _isRotatingChunk = false;

  int get chunkSecondsRemaining => chunkDurationSeconds - _chunkSecondsElapsed;
  int get currentChunkNumber => _currentChunkNumber;
  bool get isTranscribingChunk => _isTranscribingChunk;

  // ── Mic State ────────────────────────────────────────────
  bool _micActive = false;
  bool get micActive => _micActive;

  VoiceSessionStatus _sessionStatus = VoiceSessionStatus.paused;
  VoiceSessionStatus get sessionStatus => _sessionStatus;

  String? _currentSessionId;
  String? get currentSessionId => _currentSessionId;

  // ── Waveform Data ────────────────────────────────────────
  final List<VoiceWaveformSample> _waveformSamples = [];
  List<VoiceWaveformSample> get waveformSamples =>
      List.unmodifiable(_waveformSamples);

  static const int maxWaveformSamples = 120;

  // ── Live Stats ───────────────────────────────────────────
  double _currentVolume = 0.0;
  double get currentVolume => _currentVolume;

  double _avgVolume = 0.0;
  double get avgVolume => _avgVolume;

  int _totalChunksRecorded = 0;
  int get totalChunksRecorded => _totalChunksRecorded;

  int _totalAlertsCount = 0;
  int get totalAlertsCount => _totalAlertsCount;

  int _sessionsCount = 0;
  int get sessionsCount => _sessionsCount;

  Duration _sessionDuration = Duration.zero;
  Duration get sessionDuration => _sessionDuration;

  // ── Alerts Feed ──────────────────────────────────────────
  final List<VoiceLanguageAlert> _recentAlerts = [];
  List<VoiceLanguageAlert> get recentAlerts => List.unmodifiable(_recentAlerts);

  // ── Chunks Feed ──────────────────────────────────────────
  final List<VoiceAudioChunk> _recentChunks = [];
  List<VoiceAudioChunk> get recentChunks => List.unmodifiable(_recentChunks);

  // ── Alert Breakdown ──────────────────────────────────────
  final Map<LanguageAlertType, int> _alertBreakdown = {
    LanguageAlertType.profanity: 0,
    LanguageAlertType.hostility: 0,
    LanguageAlertType.threat: 0,
    LanguageAlertType.harassment: 0,
    LanguageAlertType.toxic: 0,
  };
  Map<LanguageAlertType, int> get alertBreakdown =>
      Map.unmodifiable(_alertBreakdown);

  // ── Timers ───────────────────────────────────────────────
  Timer? _waveformTimer;
  Timer? _alertTimer;
  Timer? _durationTimer;

  // ── Harsh Language Detection Templates (for alert simulation) ──

  static const List<Map<String, dynamic>> _harshPhraseTemplates = [
    {
      'type': 'profanity',
      'phrase': 'explicit language detected',
      'context': 'Audio chunk contained strong profanity in spoken segment',
      'severity': 'moderate',
    },
    {
      'type': 'hostility',
      'phrase': 'aggressive tone pattern',
      'context': 'Voice analysis detected elevated aggression indicators',
      'severity': 'severe',
    },
    {
      'type': 'threat',
      'phrase': 'threatening language detected',
      'context': 'NLP flagged potential threatening statements in transcript',
      'severity': 'severe',
    },
    {
      'type': 'harassment',
      'phrase': 'harassing speech pattern',
      'context': 'Repeated targeting language detected across audio segments',
      'severity': 'moderate',
    },
    {
      'type': 'toxic',
      'phrase': 'toxic language indicators',
      'context': 'Sentiment analysis returned high toxicity score',
      'severity': 'mild',
    },
    {
      'type': 'profanity',
      'phrase': 'mild profanity flagged',
      'context': 'Low-severity profanity detected in casual speech',
      'severity': 'mild',
    },
    {
      'type': 'hostility',
      'phrase': 'hostile vocal pattern',
      'context': 'Voice cadence and pitch indicate hostile interaction',
      'severity': 'moderate',
    },
    {
      'type': 'threat',
      'phrase': 'implicit threat detected',
      'context': 'Contextual analysis flagged implicit threatening language',
      'severity': 'moderate',
    },
    {
      'type': 'harassment',
      'phrase': 'discriminatory remarks',
      'context': 'Content filter flagged discriminatory speech patterns',
      'severity': 'severe',
    },
    {
      'type': 'toxic',
      'phrase': 'negative sentiment spike',
      'context': 'Sustained negative tone exceeding threshold for 15s',
      'severity': 'mild',
    },
  ];

  // ────────────────────────────────────────────────────────
  // Initialization
  // ────────────────────────────────────────────────────────

  VoiceSentinelProvider() {
    _loadPersistedData();
    _initChunksDir();
    _player.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _playingChunkPath = null;
      notifyListeners();
    });

    // Start OS-level microphone monitoring after a short delay
    // to let the widget tree finish building.
    Future.delayed(const Duration(seconds: 8), () {
      _micMonitor.startMonitoring();
      _micMonitorSub = _micMonitor.micUsageStream.listen(_onMicUsageChanged);
    });
  }

  /// Called when OS mic usage changes.
  void _onMicUsageChanged(List<MicUsageInfo> apps) {
    try {
      _externalMicApps = apps;

      // Auto-protect: start recording when external mic usage detected
      if (apps.isNotEmpty && !_micActive && _autoProtectEnabled) {
        debugPrint(
          '[VoiceSentinel] Auto-protect: external mic detected by '
          '${apps.map((a) => a.appName).join(", ")} — starting sentinel',
        );
        startRecording();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[VoiceSentinel] Error handling mic usage change: $e');
    }
  }

  /// Toggle auto-protect mode.
  void toggleAutoProtect() {
    _autoProtectEnabled = !_autoProtectEnabled;
    notifyListeners();
  }

  /// Ensure the chunks directory exists.
  Future<void> _initChunksDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    _chunksDir = p.join(appDir.path, 'shadow_sentinel', 'voice_chunks');
    final dir = Directory(_chunksDir!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  Future<void> _loadPersistedData() async {
    try {
      _sessionsCount = await _db.getTotalSessionCount();
      _totalChunksRecorded = await _db.getChunkCount();
      _totalAlertsCount = await _db.getAlertCount();

      final alerts = await _db.getAllAlerts();
      for (final alert in alerts) {
        final type = _parseAlertType(alert.alertType);
        _alertBreakdown[type] = (_alertBreakdown[type] ?? 0) + 1;
      }

      notifyListeners();
    } catch (_) {
      // Database not yet ready, will populate on first use
    }
  }

  // ────────────────────────────────────────────────────────
  // Mic Control
  // ────────────────────────────────────────────────────────

  void toggleMic() {
    if (_micActive) {
      stopRecording();
    } else {
      startRecording();
    }
  }

  Future<void> startRecording() async {
    _micActive = true;
    _sessionStatus = VoiceSessionStatus.recording;
    _currentSessionId =
        'vs-${DateTime.now().millisecondsSinceEpoch}-${_rng.nextInt(9999)}';
    _sessionDuration = Duration.zero;
    _currentChunkNumber = 0;
    _chunkSecondsElapsed = 0;

    // Persist session start
    await _db.insertSession(
      VoiceSessionsCompanion.insert(
        id: _currentSessionId!,
        startTime: DateTime.now(),
        status: const Value('recording'),
      ),
    );

    _sessionsCount++;

    // Start recording the first chunk
    await _startChunkRecording();

    _startTimers();
    _isTranscribing = true;
    _liveTranscriptBuffer =
        'Recording chunk $_currentChunkNumber... (${chunkDurationSeconds}s remaining)';
    notifyListeners();
  }

  /// Starts recording a new audio chunk to disk.
  Future<void> _startChunkRecording() async {
    try {
      // Check permission (required by the record package API)
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        debugPrint('[VoiceSentinel] Microphone permission denied');
        return;
      }

      // Ensure chunks dir is ready
      if (_chunksDir == null) await _initChunksDir();

      _currentChunkNumber++;
      _chunkSecondsElapsed = 0;
      _currentChunkPath = p.join(
        _chunksDir!,
        '${_currentSessionId}_chunk_$_currentChunkNumber.wav',
      );

      debugPrint(
        '[VoiceSentinel] Starting chunk $_currentChunkNumber → $_currentChunkPath',
      );

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: _currentChunkPath!,
      );

      // Verify the recorder is actually recording
      final isRecording = await _recorder.isRecording();
      debugPrint('[VoiceSentinel] Recorder active after start: $isRecording');
    } catch (e) {
      debugPrint('[VoiceSentinel] Failed to start chunk recording: $e');
    }
  }

  Future<void> stopRecording() async {
    _micActive = false;
    _sessionStatus = VoiceSessionStatus.completed;

    // Stop real microphone recording
    try {
      final recordedPath = await _recorder.stop();
      debugPrint('[VoiceSentinel] Recording stopped → $recordedPath');

      // Wait for OS to flush file
      await Future.delayed(const Duration(milliseconds: 500));

      // Transcribe the final partial chunk if it has at least 3 seconds
      final finalPath = recordedPath ?? _currentChunkPath;
      if (finalPath != null &&
          _chunkSecondsElapsed >= 3 &&
          await File(finalPath).exists()) {
        _createChunkEntry(
          finalPath,
          _currentChunkNumber,
          Duration(seconds: _chunkSecondsElapsed),
        );
        _transcribeCompletedChunk(finalPath, _currentChunkNumber);
      }
    } catch (e) {
      debugPrint('[VoiceSentinel] Error stopping recording: $e');
    }

    // Update session in DB
    if (_currentSessionId != null) {
      await _db.updateSession(
        _currentSessionId!,
        VoiceSessionsCompanion(
          endTime: Value(DateTime.now()),
          status: const Value('completed'),
          totalChunks: Value(_totalChunksRecorded),
          alertCount: Value(_totalAlertsCount),
          avgVolume: Value(_avgVolume),
          totalDurationMs: Value(_sessionDuration.inMilliseconds),
        ),
      );
    }

    _stopTimers();
    _isTranscribing = false;
    _wordTimer?.cancel();
    _wordTimer = null;
    _currentVolume = 0.0;
    notifyListeners();
  }

  // ── Playback ─────────────────────────────────────────────

  /// Play a recorded audio chunk file.
  Future<void> playChunk(String filePath) async {
    try {
      // Resolve absolute path
      String absPath = filePath;
      if (!p.isAbsolute(filePath) && _chunksDir != null) {
        absPath = p.join(_chunksDir!, p.basename(filePath));
      }

      if (!File(absPath).existsSync()) {
        debugPrint('[VoiceSentinel] File not found: $absPath');
        return;
      }

      // Stop any current playback
      if (_isPlaying) {
        await _player.stop();
      }

      _playingChunkPath = filePath;
      _isPlaying = true;
      notifyListeners();

      await _player.play(DeviceFileSource(absPath));
    } catch (e) {
      debugPrint('[VoiceSentinel] Playback error: $e');
      _isPlaying = false;
      _playingChunkPath = null;
      notifyListeners();
    }
  }

  /// Stop audio playback.
  Future<void> stopPlayback() async {
    await _player.stop();
    _isPlaying = false;
    _playingChunkPath = null;
    notifyListeners();
  }

  /// Play a specific chunk file.
  Future<void> playSession(String sessionId) async {
    if (_chunksDir == null) return;
    final sessionFile = p.join(_chunksDir!, '$sessionId.wav');
    await playChunk(sessionFile);
  }

  // ────────────────────────────────────────────────────────
  // Timer Engine
  // ────────────────────────────────────────────────────────

  void _startTimers() {
    // Waveform updates using real amplitude from recorder (~12 fps)
    _waveformTimer = Timer.periodic(
      const Duration(milliseconds: 80),
      (_) => _updateWaveform(),
    );

    // Simulate alert check every 8 seconds (30% chance of alert)
    _alertTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _simulateAlertCheck(),
    );

    // Session duration counter + chunk rotation driver (every 1 second)
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _sessionDuration += const Duration(seconds: 1);
      _chunkSecondsElapsed++;

      // Show recording countdown in live buffer (only when not
      // actively showing a transcription result)
      if (!_isTranscribingChunk && _wordTimer == null && _micActive) {
        final remaining = chunkDurationSeconds - _chunkSecondsElapsed;
        _liveTranscriptBuffer =
            'Recording chunk $_currentChunkNumber... (${remaining}s remaining)';
      }

      // Rotate chunk when 30 seconds have elapsed (guard against re-entry)
      if (_chunkSecondsElapsed >= chunkDurationSeconds &&
          _micActive &&
          !_isRotatingChunk) {
        _rotateChunk();
      }

      notifyListeners();
    });
  }

  void _stopTimers() {
    _waveformTimer?.cancel();
    _alertTimer?.cancel();
    _durationTimer?.cancel();
    _waveformTimer = null;
    _alertTimer = null;
    _durationTimer = null;
  }

  // ── Waveform ─────────────────────────────────────────────

  void _updateWaveform() async {
    double amplitude;

    // Try to get real amplitude from the recorder
    try {
      final amp = await _recorder.getAmplitude();
      // amp.current is in dBFS (negative, e.g. -30 to 0)
      // Normalise to 0.0 – 1.0
      final dbfs = amp.current;
      if (dbfs.isFinite && dbfs > -60) {
        amplitude = ((dbfs + 60) / 60).clamp(0.0, 1.0);
      } else {
        amplitude = 0.0;
      }
    } catch (_) {
      // Fallback to simulation
      final base = 0.2 + _rng.nextDouble() * 0.3;
      final spike = _rng.nextDouble() > 0.85 ? _rng.nextDouble() * 0.5 : 0.0;
      amplitude = (base + spike).clamp(0.0, 1.0);
    }

    _currentVolume = amplitude * 100;
    _avgVolume = _avgVolume * 0.95 + _currentVolume * 0.05;

    _waveformSamples.add(
      VoiceWaveformSample(
        amplitude: amplitude,
        timestamp: DateTime.now(),
        isFlagged: amplitude > 0.85,
      ),
    );

    if (_waveformSamples.length > maxWaveformSamples) {
      _waveformSamples.removeAt(0);
    }

    notifyListeners();
  }

  // ────────────────────────────────────────────────────────
  // Real 30-Second Chunk Recording & Transcription
  // ────────────────────────────────────────────────────────

  /// Rotate the current chunk: stop recording the active chunk, start
  /// recording the next one, and transcribe the completed chunk.
  Future<void> _rotateChunk() async {
    if (_isRotatingChunk || !_micActive || _currentSessionId == null) return;
    _isRotatingChunk = true;
    // Reset counter early to prevent the timer from re-triggering.
    _chunkSecondsElapsed = 0;

    final completedChunkPath = _currentChunkPath;
    final completedChunkNumber = _currentChunkNumber;
    final chunkDuration = const Duration(seconds: chunkDurationSeconds);

    // Stop current recording and capture the saved path.
    String? savedPath;
    try {
      savedPath = await _recorder.stop();
      debugPrint(
        '[VoiceSentinel] Chunk $completedChunkNumber stopped → $savedPath',
      );
    } catch (e) {
      debugPrint(
        '[VoiceSentinel] Error stopping chunk $completedChunkNumber: $e',
      );
    }

    // Give the OS a moment to flush the WAV file to disk.
    await Future.delayed(const Duration(milliseconds: 500));

    // Use the path the recorder actually saved to.
    final actualChunkPath = savedPath ?? completedChunkPath;

    // Start recording the next chunk.
    _currentChunkNumber++;
    _currentChunkPath = p.join(
      _chunksDir!,
      '${_currentSessionId}_chunk_$_currentChunkNumber.wav',
    );

    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: _currentChunkPath!,
      );
      final isRec = await _recorder.isRecording();
      debugPrint(
        '[VoiceSentinel] Recording chunk $_currentChunkNumber → $_currentChunkPath (active: $isRec)',
      );
    } catch (e) {
      debugPrint(
        '[VoiceSentinel] Failed to start chunk $_currentChunkNumber: $e',
      );
    }

    _isRotatingChunk = false;

    // Create a chunk entry for the completed chunk & transcribe.
    if (actualChunkPath != null && await File(actualChunkPath).exists()) {
      _createChunkEntry(actualChunkPath, completedChunkNumber, chunkDuration);
      // Transcribe in background (don't await — next chunk is recording)
      _transcribeCompletedChunk(actualChunkPath, completedChunkNumber);
    } else {
      debugPrint(
        '[VoiceSentinel] Chunk $completedChunkNumber file not found '
        'after stop: $actualChunkPath',
      );
    }

    notifyListeners();
  }

  /// Create a VoiceAudioChunk entry in the feed and persist to database.
  void _createChunkEntry(String filePath, int chunkNumber, Duration duration) {
    final chunkId =
        'vc-${DateTime.now().millisecondsSinceEpoch}-${_rng.nextInt(9999)}';

    final chunk = VoiceAudioChunk(
      id: chunkId,
      sessionId: _currentSessionId!,
      filePath: filePath,
      duration: duration,
      timestamp: DateTime.now(),
      volumeDb: -20.0 + _rng.nextDouble() * 15,
      transcript: 'Transcribing...',
      severity: VoiceSeverity.clean,
      flaggedWords: [],
    );

    _recentChunks.insert(0, chunk);
    if (_recentChunks.length > 30) _recentChunks.removeLast();
    _totalChunksRecorded++;

    // Persist to database
    _db.insertChunk(
      VoiceChunksCompanion.insert(
        id: chunkId,
        sessionId: _currentSessionId!,
        filePath: filePath,
        durationMs: duration.inMilliseconds,
        timestamp: DateTime.now(),
        volumeDb: chunk.volumeDb,
        transcript: const Value('Transcribing...'),
        severity: Value(VoiceSeverity.clean.name),
        flaggedWords: const Value(''),
      ),
    );

    notifyListeners();
  }

  /// Transcribe a completed audio chunk using Windows Speech Recognition.
  Future<void> _transcribeCompletedChunk(String wavPath, int chunkNum) async {
    _isTranscribingChunk = true;
    _liveTranscriptBuffer = 'Transcribing chunk $chunkNum...';
    notifyListeners();

    try {
      final text = await SpeechToTextService.transcribeWav(wavPath);
      _isTranscribingChunk = false;

      if (text.isNotEmpty) {
        debugPrint('[VoiceSentinel] Chunk $chunkNum transcribed: $text');
        // Reveal the transcribed text word-by-word then create summary
        _revealTranscribedText(text, chunkNum);
      } else {
        debugPrint('[VoiceSentinel] Chunk $chunkNum: no speech detected');
        _liveTranscriptBuffer = '(No speech detected in chunk $chunkNum)';
        _generateRealSummary('(No speech detected)', chunkNum);
        notifyListeners();
      }
    } catch (e) {
      _isTranscribingChunk = false;
      debugPrint('[VoiceSentinel] Transcription error for chunk $chunkNum: $e');
      _liveTranscriptBuffer = '(Transcription failed for chunk $chunkNum)';
      notifyListeners();
    }
  }

  /// Reveal the transcribed text word-by-word in the live buffer,
  /// then commit the full transcript and generate a real summary.
  void _revealTranscribedText(String text, int chunkNum) {
    _currentWords = text.split(' ');
    _currentWordIndex = 0;
    _liveTranscriptBuffer = '';

    _wordTimer?.cancel();
    _wordTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (_currentWordIndex >= _currentWords.length) {
        _wordTimer?.cancel();
        _wordTimer = null;
        // Commit the real transcript
        _commitTranscript(text);
        // Create a summary from the real text
        _generateRealSummary(text, chunkNum);
        return;
      }
      _liveTranscriptBuffer +=
          (_currentWordIndex > 0 ? ' ' : '') + _currentWords[_currentWordIndex];
      _currentWordIndex++;
      notifyListeners();
    });
  }

  /// Store a real transcription segment.
  void _commitTranscript(String text) {
    _transcriptSegments.insert(
      0,
      TranscriptionSegment(
        id: 'ts-${DateTime.now().millisecondsSinceEpoch}-${_rng.nextInt(9999)}',
        text: text,
        timestamp: DateTime.now(),
        isFlagged: false,
        flaggedWords: [],
        sessionId: _currentSessionId ?? 'unknown',
        confidence: 0.90,
      ),
    );
    if (_transcriptSegments.length > 100) _transcriptSegments.removeLast();
  }

  /// Generate a translation summary from real transcribed text.
  void _generateRealSummary(String transcribedText, int chunkNum) {
    final now = DateTime.now();
    final keyPoints = _extractKeyPoints(transcribedText);

    _translationSummaries.insert(
      0,
      TranslationSummary(
        id: 'tls-${now.millisecondsSinceEpoch}-${_rng.nextInt(9999)}',
        startTime: now.subtract(const Duration(seconds: chunkDurationSeconds)),
        endTime: now,
        topic: 'Audio Chunk #$chunkNum',
        summary: transcribedText,
        tone: 'Transcribed',
        keyPoints: keyPoints,
        segmentCount: 1,
        hasFlaggedContent: false,
        flaggedWords: [],
        avgConfidence: 0.90,
      ),
    );

    if (_translationSummaries.length > 50) _translationSummaries.removeLast();
    notifyListeners();
  }

  /// Extract key points (sentences) from transcribed text.
  List<String> _extractKeyPoints(String text) {
    final sentences = text
        .split(RegExp(r'[.!?]+'))
        .map((s) => s.trim())
        .where((s) => s.length > 3)
        .toList();
    if (sentences.isEmpty) {
      return [text.length > 80 ? '${text.substring(0, 80)}...' : text];
    }
    return sentences.take(3).toList();
  }

  // ── Alert Simulation ─────────────────────────────────────

  Future<void> _simulateAlertCheck() async {
    if (!_micActive || _currentSessionId == null) return;

    // 30% chance an alert fires
    if (_rng.nextDouble() > 0.30) return;

    final template =
        _harshPhraseTemplates[_rng.nextInt(_harshPhraseTemplates.length)];

    final alertType = _parseAlertType(template['type'] as String);
    final severity = _parseSeverity(template['severity'] as String);

    final alertId =
        'va-${DateTime.now().millisecondsSinceEpoch}-${_rng.nextInt(9999)}';
    final chunkId = _recentChunks.isNotEmpty
        ? _recentChunks.first.id
        : 'vc-unknown';

    final alert = VoiceLanguageAlert(
      id: alertId,
      sessionId: _currentSessionId!,
      chunkId: chunkId,
      alertType: alertType,
      severity: severity,
      flaggedPhrase: template['phrase'] as String,
      context: template['context'] as String,
      confidenceScore: 70 + _rng.nextDouble() * 30,
      timestamp: DateTime.now(),
    );

    _recentAlerts.insert(0, alert);
    if (_recentAlerts.length > 30) _recentAlerts.removeLast();
    _totalAlertsCount++;
    _alertBreakdown[alertType] = (_alertBreakdown[alertType] ?? 0) + 1;

    // Persist to database
    await _db.insertAlert(
      VoiceAlertsCompanion.insert(
        id: alertId,
        sessionId: _currentSessionId!,
        chunkId: chunkId,
        alertType: alertType.name,
        severity: severity.name,
        flaggedPhrase: template['phrase'] as String,
        context: template['context'] as String,
        confidenceScore: alert.confidenceScore,
        timestamp: alert.timestamp,
      ),
    );

    notifyListeners();
  }

  // ── Helpers ──────────────────────────────────────────────

  LanguageAlertType _parseAlertType(String type) {
    switch (type) {
      case 'profanity':
        return LanguageAlertType.profanity;
      case 'hostility':
        return LanguageAlertType.hostility;
      case 'threat':
        return LanguageAlertType.threat;
      case 'harassment':
        return LanguageAlertType.harassment;
      case 'toxic':
        return LanguageAlertType.toxic;
      default:
        return LanguageAlertType.toxic;
    }
  }

  VoiceSeverity _parseSeverity(String sev) {
    switch (sev) {
      case 'clean':
        return VoiceSeverity.clean;
      case 'mild':
        return VoiceSeverity.mild;
      case 'moderate':
        return VoiceSeverity.moderate;
      case 'severe':
        return VoiceSeverity.severe;
      default:
        return VoiceSeverity.mild;
    }
  }

  /// Clear all transcript segments and summaries.
  void clearTranscript() {
    _transcriptSegments.clear();
    _translationSummaries.clear();
    _liveTranscriptBuffer = '';
    notifyListeners();
  }

  // ── Computed Stats ───────────────────────────────────────

  double get cleanRatio {
    if (_totalChunksRecorded == 0) return 100.0;
    final flagged = _recentChunks
        .where((c) => c.severity != VoiceSeverity.clean)
        .length;
    final total = _recentChunks.length;
    return total > 0 ? ((total - flagged) / total) * 100 : 100.0;
  }

  String get formattedDuration {
    final h = _sessionDuration.inHours;
    final m = _sessionDuration.inMinutes % 60;
    final s = _sessionDuration.inSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Cleanup ──────────────────────────────────────────────

  @override
  void dispose() {
    _stopTimers();
    _wordTimer?.cancel();
    _micMonitorSub?.cancel();
    _micMonitor.dispose();
    _recorder.dispose();
    _player.dispose();
    _db.close();
    super.dispose();
  }
}
