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
import '../services/text_analysis_service.dart';

/// Voice Sentinel provider — manages mic monitoring, language analysis,
/// waveform data, and persists voice sessions/alerts to SQLite via Drift.
///
/// Records **real audio in 30-second chunks** via the `record` package,
/// transcribes each chunk using **OpenAI Whisper** (faster-whisper) offline
/// speech recognition, analyses the text for profanity / hostility / threats,
/// and feeds the real transcription into the live translation display and
/// summary cards.
///
/// Uses a sequential transcription queue to prevent parallel Python processes
/// from competing for memory.
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

  /// Queue of (wavPath, chunkNum) pairs waiting to be transcribed.
  /// Only ONE transcription runs at a time to avoid parallel Python
  /// processes fighting for memory (Whisper model is ~1.5 GB).
  final List<(String, int)> _transcriptionQueue = [];
  bool _isProcessingQueue = false;

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
  Timer? _durationTimer;

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
  /// Uses AppData/Local to avoid OneDrive sync interference with audio files.
  Future<void> _initChunksDir() async {
    // Prefer a local (non-synced) directory
    final supportDir = await getApplicationSupportDirectory();
    _chunksDir = p.join(supportDir.path, 'voice_chunks');
    final dir = Directory(_chunksDir!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    debugPrint('[VoiceSentinel] Chunks directory: $_chunksDir');
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

      // Verify the file handle was created
      if (File(_currentChunkPath!).existsSync()) {
        debugPrint('[VoiceSentinel] File created on disk ✓');
      } else {
        debugPrint('[VoiceSentinel] WARNING: File not created yet on disk');
      }
    } catch (e, stack) {
      debugPrint('[VoiceSentinel] Failed to start chunk recording: $e');
      debugPrint('[VoiceSentinel] Stack: $stack');
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
        _enqueueTranscription(finalPath, _currentChunkNumber);
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
    _durationTimer?.cancel();
    _waveformTimer = null;
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

    // Use the path the recorder actually saved to.
    final actualChunkPath = savedPath ?? completedChunkPath;

    // Start recording the NEXT chunk immediately — zero gap in recording.
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

    // Brief delay for OS to finish flushing the completed WAV to disk
    // (runs in parallel with the new chunk already recording).
    await Future.delayed(const Duration(milliseconds: 250));

    // Create a chunk entry for the completed chunk & queue for transcription.
    if (actualChunkPath != null && await File(actualChunkPath).exists()) {
      _createChunkEntry(actualChunkPath, completedChunkNumber, chunkDuration);
      // Queue transcription — only one runs at a time to prevent OOM
      _enqueueTranscription(actualChunkPath, completedChunkNumber);
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

  // ── Transcription Queue ──────────────────────────────────

  /// Add a chunk to the transcription queue and start processing
  /// if no other transcription is currently running.
  void _enqueueTranscription(String wavPath, int chunkNum) {
    _transcriptionQueue.add((wavPath, chunkNum));
    debugPrint(
      '[VoiceSentinel] Queued chunk $chunkNum for transcription '
      '(queue length: ${_transcriptionQueue.length})',
    );
    if (!_isProcessingQueue) {
      _processTranscriptionQueue();
    }
  }

  /// Process queued chunks one at a time. Only ONE Python/Whisper
  /// process runs at any time to prevent memory exhaustion.
  Future<void> _processTranscriptionQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;

    while (_transcriptionQueue.isNotEmpty) {
      final (wavPath, chunkNum) = _transcriptionQueue.removeAt(0);
      await _transcribeCompletedChunk(wavPath, chunkNum);
    }

    _isProcessingQueue = false;
  }

  /// Transcribe a completed audio chunk using Whisper offline speech
  /// recognition, then analyse the text for flagged content.
  Future<void> _transcribeCompletedChunk(String wavPath, int chunkNum) async {
    _isTranscribingChunk = true;
    _liveTranscriptBuffer = 'Transcribing chunk $chunkNum...';
    notifyListeners();

    try {
      final text = await SpeechToTextService.transcribeWav(wavPath);
      _isTranscribingChunk = false;

      if (text.isNotEmpty) {
        debugPrint('[VoiceSentinel] Chunk $chunkNum transcribed: $text');

        // ── Update the chunk entry with actual transcript ──
        _updateChunkTranscript(chunkNum, text);

        // ── Analyse the real transcription ──
        final analysis = TextAnalysisService.analyse(text);

        // If flagged, generate a real alert
        if (analysis.isFlagged) {
          _createRealAlert(analysis, chunkNum);
        }

        // Reveal the transcribed text word-by-word then create summary
        _revealTranscribedText(text, chunkNum, analysis: analysis);
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

  /// Update the chunk entry in _recentChunks with the actual transcript text.
  void _updateChunkTranscript(int chunkNum, String transcript) {
    for (int i = 0; i < _recentChunks.length; i++) {
      final chunk = _recentChunks[i];
      if (chunk.transcript == 'Transcribing...' &&
          chunk.filePath.contains('_chunk_$chunkNum.wav')) {
        _recentChunks[i] = VoiceAudioChunk(
          id: chunk.id,
          sessionId: chunk.sessionId,
          filePath: chunk.filePath,
          duration: chunk.duration,
          timestamp: chunk.timestamp,
          volumeDb: chunk.volumeDb,
          transcript: transcript,
          severity: chunk.severity,
          flaggedWords: chunk.flaggedWords,
        );

        // Also update the database
        _db.updateChunkTranscript(chunk.id, transcript);
        break;
      }
    }
  }

  /// Show the transcribed text instantly in the live buffer,
  /// then commit the full transcript and generate a real summary.
  void _revealTranscribedText(
    String text,
    int chunkNum, {
    TextAnalysisResult? analysis,
  }) {
    _wordTimer?.cancel();
    _wordTimer = null;

    final result = analysis ?? TextAnalysisResult.clean;

    // Show the full transcription immediately — no delay.
    _liveTranscriptBuffer = text;
    notifyListeners();

    // Commit the real transcript (with analysis results)
    _commitTranscript(text, analysis: result);
    // Create a summary from the real text (with analysis results)
    _generateRealSummary(text, chunkNum, analysis: result);
  }

  /// Store a real transcription segment with analysis results.
  void _commitTranscript(
    String text, {
    TextAnalysisResult analysis = TextAnalysisResult.clean,
  }) {
    _transcriptSegments.insert(
      0,
      TranscriptionSegment(
        id: 'ts-${DateTime.now().millisecondsSinceEpoch}-${_rng.nextInt(9999)}',
        text: text,
        timestamp: DateTime.now(),
        isFlagged: analysis.isFlagged,
        flaggedWords: analysis.flaggedWords,
        sessionId: _currentSessionId ?? 'unknown',
        confidence: 0.90,
      ),
    );
    if (_transcriptSegments.length > 100) _transcriptSegments.removeLast();
  }

  /// Generate a translation summary from real transcribed text.
  void _generateRealSummary(
    String transcribedText,
    int chunkNum, {
    TextAnalysisResult analysis = TextAnalysisResult.clean,
  }) {
    final now = DateTime.now();
    final keyPoints = _extractKeyPoints(transcribedText);

    // Capitalise first letter of tone for display
    final displayTone = analysis.isFlagged
        ? '${analysis.tone[0].toUpperCase()}${analysis.tone.substring(1)}'
        : 'Transcribed';

    _translationSummaries.insert(
      0,
      TranslationSummary(
        id: 'tls-${now.millisecondsSinceEpoch}-${_rng.nextInt(9999)}',
        startTime: now.subtract(const Duration(seconds: chunkDurationSeconds)),
        endTime: now,
        topic: 'Audio Chunk #$chunkNum',
        summary: transcribedText,
        tone: displayTone,
        keyPoints: keyPoints,
        segmentCount: 1,
        hasFlaggedContent: analysis.isFlagged,
        flaggedWords: analysis.flaggedWords,
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

  // ── Real Alert Generation ───────────────────────────────

  /// Create a real alert from text-analysis results.
  Future<void> _createRealAlert(
    TextAnalysisResult analysis,
    int chunkNum,
  ) async {
    if (!_micActive || _currentSessionId == null || !analysis.isFlagged) return;

    final alertType = _parseAlertType(analysis.alertType);
    final severity = _severityFromScore(analysis.severity);

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
      flaggedPhrase: analysis.flaggedWords.take(5).join(', '),
      context: analysis.alertMessage,
      confidenceScore: analysis.severity.toDouble().clamp(50.0, 100.0),
      timestamp: DateTime.now(),
    );

    _recentAlerts.insert(0, alert);
    if (_recentAlerts.length > 30) _recentAlerts.removeLast();
    _totalAlertsCount++;
    _alertBreakdown[alertType] = (_alertBreakdown[alertType] ?? 0) + 1;

    // Also update the latest chunk entry with severity + flagged words
    if (_recentChunks.isNotEmpty) {
      final latestChunk = _recentChunks.first;
      _recentChunks[0] = VoiceAudioChunk(
        id: latestChunk.id,
        sessionId: latestChunk.sessionId,
        filePath: latestChunk.filePath,
        duration: latestChunk.duration,
        timestamp: latestChunk.timestamp,
        volumeDb: latestChunk.volumeDb,
        transcript: latestChunk.transcript,
        severity: severity,
        flaggedWords: analysis.flaggedWords,
      );
    }

    // Persist to database
    await _db.insertAlert(
      VoiceAlertsCompanion.insert(
        id: alertId,
        sessionId: _currentSessionId!,
        chunkId: chunkId,
        alertType: alertType.name,
        severity: severity.name,
        flaggedPhrase: analysis.flaggedWords.take(5).join(', '),
        context: analysis.alertMessage,
        confidenceScore: alert.confidenceScore,
        timestamp: alert.timestamp,
      ),
    );

    debugPrint(
      '[VoiceSentinel] ALERT created — ${alertType.name} / ${severity.name} '
      'in chunk $chunkNum: ${analysis.flaggedWords}',
    );

    notifyListeners();
  }

  /// Map a numeric severity score (0-100) to a VoiceSeverity enum.
  VoiceSeverity _severityFromScore(int score) {
    if (score >= 80) return VoiceSeverity.severe;
    if (score >= 50) return VoiceSeverity.moderate;
    if (score >= 20) return VoiceSeverity.mild;
    return VoiceSeverity.clean;
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
