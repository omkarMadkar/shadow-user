import 'dart:async';
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../database/voice_database.dart';

/// Voice Sentinel provider — manages mic monitoring, language analysis,
/// waveform data, and persists voice sessions/alerts to SQLite via Drift.
class VoiceSentinelProvider extends ChangeNotifier {
  final Random _rng = Random();
  final VoiceDatabase _db = VoiceDatabase();

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
  Timer? _chunkTimer;
  Timer? _alertTimer;
  Timer? _durationTimer;

  // ── Harsh Language Detection Templates ───────────────────

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

  static const List<String> _transcriptTemplates = [
    'Normal conversation detected — no anomalies in speech pattern',
    'Standard discussion — professional tone maintained throughout',
    'Meeting dialogue — multiple speakers, all within acceptable parameters',
    'Phone call segment — routine communication, no flags raised',
    'Voice memo — personal notes, clean language throughout',
    'Casual speech detected — informal but within acceptable bounds',
    'Presentation audio — formal delivery, confidence level high',
    'Break room conversation — ambient noise, speech patterns normal',
  ];

  static const List<String> _flaggedWordSamples = [
    'hostile',
    'aggressive',
    'threat',
    'inappropriate',
    'offensive',
    'abusive',
    'vulgar',
    'derogatory',
  ];

  // ────────────────────────────────────────────────────────
  // Initialization
  // ────────────────────────────────────────────────────────

  VoiceSentinelProvider() {
    _loadPersistedData();
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

    // Persist session start
    await _db.insertSession(
      VoiceSessionsCompanion.insert(
        id: _currentSessionId!,
        startTime: DateTime.now(),
        status: const Value('recording'),
      ),
    );

    _sessionsCount++;

    _startSimulation();
    notifyListeners();
  }

  Future<void> stopRecording() async {
    _micActive = false;
    _sessionStatus = VoiceSessionStatus.completed;

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

    _stopSimulation();
    _currentVolume = 0.0;
    notifyListeners();
  }

  // ────────────────────────────────────────────────────────
  // Simulation Engine
  // ────────────────────────────────────────────────────────

  void _startSimulation() {
    // Waveform updates at ~60fps (every 80ms for smooth animation)
    _waveformTimer = Timer.periodic(
      const Duration(milliseconds: 80),
      (_) => _updateWaveform(),
    );

    // Simulate audio chunk every 5 seconds
    _chunkTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _simulateAudioChunk(),
    );

    // Simulate alert check every 8 seconds (30% chance of alert)
    _alertTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _simulateAlertCheck(),
    );

    // Session duration counter
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _sessionDuration += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  void _stopSimulation() {
    _waveformTimer?.cancel();
    _chunkTimer?.cancel();
    _alertTimer?.cancel();
    _durationTimer?.cancel();
    _waveformTimer = null;
    _chunkTimer = null;
    _alertTimer = null;
    _durationTimer = null;
  }

  // ── Waveform ─────────────────────────────────────────────

  void _updateWaveform() {
    // Simulate realistic audio waveform amplitudes
    final base = 0.2 + _rng.nextDouble() * 0.3;
    final spike = _rng.nextDouble() > 0.85 ? _rng.nextDouble() * 0.5 : 0.0;
    final amplitude = (base + spike).clamp(0.0, 1.0);

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

  // ── Audio Chunk Simulation ───────────────────────────────

  Future<void> _simulateAudioChunk() async {
    if (!_micActive || _currentSessionId == null) return;

    final chunkId =
        'vc-${DateTime.now().millisecondsSinceEpoch}-${_rng.nextInt(9999)}';
    final isClean = _rng.nextDouble() > 0.25; // 75% clean

    final severity = isClean
        ? VoiceSeverity.clean
        : [
            VoiceSeverity.mild,
            VoiceSeverity.moderate,
            VoiceSeverity.severe,
          ][_rng.nextInt(3)];

    final transcript = isClean
        ? _transcriptTemplates[_rng.nextInt(_transcriptTemplates.length)]
        : 'Audio segment flagged — language analysis in progress...';

    final flaggedWords = isClean
        ? <String>[]
        : List.generate(
            1 + _rng.nextInt(3),
            (_) =>
                _flaggedWordSamples[_rng.nextInt(_flaggedWordSamples.length)],
          );

    final chunk = VoiceAudioChunk(
      id: chunkId,
      sessionId: _currentSessionId!,
      filePath: 'chunks/$chunkId.wav',
      duration: Duration(seconds: 3 + _rng.nextInt(8)),
      timestamp: DateTime.now(),
      volumeDb: -20.0 + _rng.nextDouble() * 15,
      transcript: transcript,
      severity: severity,
      flaggedWords: flaggedWords,
    );

    _recentChunks.insert(0, chunk);
    if (_recentChunks.length > 30) _recentChunks.removeLast();
    _totalChunksRecorded++;

    // Persist to database
    await _db.insertChunk(
      VoiceChunksCompanion.insert(
        id: chunkId,
        sessionId: _currentSessionId!,
        filePath: chunk.filePath,
        durationMs: chunk.duration.inMilliseconds,
        timestamp: chunk.timestamp,
        volumeDb: chunk.volumeDb,
        transcript: Value(transcript),
        severity: Value(severity.name),
        flaggedWords: Value(flaggedWords.join(',')),
      ),
    );

    notifyListeners();
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
    _stopSimulation();
    _db.close();
    super.dispose();
  }
}
