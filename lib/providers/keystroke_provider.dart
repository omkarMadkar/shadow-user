import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/keystroke_dynamics_service.dart';
import '../services/global_keystroke_monitor_service.dart';

/// Keystroke behavioral analysis states.
enum KeystrokeMode { idle, enrolling, monitoring }

/// Central state management for the Keystroke Sentinel module.
///
/// Handles enrollment (baseline capture), live anomaly detection,
/// snapshot history for charting, alerts, and demo mode simulation.
class KeystrokeProvider extends ChangeNotifier {
  final KeystrokeDynamicsService _service = KeystrokeDynamicsService();
  final Random _rng = Random();

  // ── Mode ──────────────────────────────────────────────────
  KeystrokeMode _mode = KeystrokeMode.monitoring;
  KeystrokeMode get mode => _mode;

  // ── Enrollment ────────────────────────────────────────────
  static const int enrollmentTarget = 100; // key events needed
  int _enrollmentProgress = 0;
  int get enrollmentProgress => _enrollmentProgress;
  double get enrollmentPercent =>
      (_enrollmentProgress / enrollmentTarget).clamp(0.0, 1.0);

  KeystrokeBaseline? _baseline;
  KeystrokeBaseline? get baseline => _baseline;
  bool get isEnrolled => _baseline != null;

  // ── Live Metrics ──────────────────────────────────────────
  double _currentWpm = 0;
  double get currentWpm => _currentWpm;

  double _currentDwellMs = 0;
  double get currentDwellMs => _currentDwellMs;

  double _currentFlightMs = 0;
  double get currentFlightMs => _currentFlightMs;

  double _anomalyScore = 0;
  double get anomalyScore => _anomalyScore;

  /// Match score 0–100% (inverse of anomaly) used by trust score.
  double get keystrokeMatchScore => ((1.0 - _anomalyScore) * 100).clamp(0, 100);

  // ── History (for charts) ─────────────────────────────────
  final List<KeystrokeSnapshot> _history = [];
  List<KeystrokeSnapshot> get history => List.unmodifiable(_history);

  // ── Waveform data (last N dwell/flight values) ───────────
  final List<double> _dwellWaveform = [];
  List<double> get dwellWaveform => List.unmodifiable(_dwellWaveform);

  final List<double> _flightWaveform = [];
  List<double> get flightWaveform => List.unmodifiable(_flightWaveform);

  // ── Alerts ────────────────────────────────────────────────
  final List<KeystrokeAlert> _alerts = [];
  List<KeystrokeAlert> get alerts => List.unmodifiable(_alerts);

  // ── Log Messages ──────────────────────────────────────────
  final List<String> _logMessages = [];
  List<String> get logMessages => List.unmodifiable(_logMessages);

  // ── Demo Mode ─────────────────────────────────────────────
  bool _demoMode = false;
  bool get demoMode => _demoMode;
  Timer? _demoTimer;

  // ── Snapshot timer ────────────────────────────────────────
  Timer? _snapshotTimer;

  KeystrokeDynamicsService get service => _service;

  // ── Global OS-level Monitor ───────────────────────────────
  final GlobalKeystrokeMonitorService _globalMonitor =
      GlobalKeystrokeMonitorService();
  GlobalKeystrokeMonitorService get globalMonitor => _globalMonitor;

  bool _globalMonitorActive = false;
  bool get globalMonitorActive => _globalMonitorActive;

  final List<ContentThreatAlert> _contentThreats = [];
  List<ContentThreatAlert> get contentThreats =>
      List.unmodifiable(_contentThreats);

  String _currentTypedText = '';
  String get currentTypedText => _currentTypedText;

  String _currentForegroundApp = '';
  String get currentForegroundApp => _currentForegroundApp;

  final List<SentPhrase> _sentPhrases = [];
  List<SentPhrase> get sentPhrases => List.unmodifiable(_sentPhrases);

  int _backspaceCoverUpCount = 0;
  int get backspaceCoverUpCount => _backspaceCoverUpCount;

  // ────────────────────────────────────────────────────────
  // Global Monitor Control
  // ────────────────────────────────────────────────────────

  /// Start OS-level global keyboard monitoring.
  Future<bool> startGlobalMonitor() async {
    _globalMonitor.onThreatDetected = _onContentThreat;
    _globalMonitor.onTextChanged = _onGlobalTextChanged;
    _globalMonitor.onPhraseSent = _onGlobalPhraseSent;
    _globalMonitor.onKeyEvent = _onGlobalKeyEvent;

    final success = await _globalMonitor.startHook();
    _globalMonitorActive = success;
    if (success) {
      _mode = KeystrokeMode.monitoring;
      _startSnapshotCapture();
      _addLog('GLOBAL', 'OS-level keystroke monitor activated');
      _addAlert(
        KeystrokeAlertType.enrollmentComplete,
        'Global keystroke threat monitor is now active',
        0.0,
        ThreatSeverity.low,
      );
    } else {
      _addLog('GLOBAL', 'Failed to start OS-level monitor');
    }
    notifyListeners();
    return success;
  }

  /// Stop OS-level global keyboard monitoring.
  Future<void> stopGlobalMonitor() async {
    await _globalMonitor.stopHook();
    _globalMonitorActive = false;
    _addLog('GLOBAL', 'OS-level keystroke monitor deactivated');
    notifyListeners();
  }

  void _onContentThreat(ContentThreatAlert alert) {
    _contentThreats.insert(0, alert);
    if (_contentThreats.length > 30) _contentThreats.removeLast();

    // Drive anomaly score from threat severity
    _anomalyScore = (alert.analysis.severity / 100.0).clamp(0.0, 1.0);

    // Add snapshot to history for anomaly timeline chart
    _history.add(
      KeystrokeSnapshot(
        avgDwellTimeMs: _currentDwellMs,
        avgFlightTimeMs: _currentFlightMs,
        wpm: _currentWpm,
        anomalyScore: _anomalyScore,
        keyCount: _service.keyCount,
        timestamp: DateTime.now(),
      ),
    );
    if (_history.length > 60) _history.removeAt(0);

    // Map to keystroke alert type
    KeystrokeAlertType alertType;
    ThreatSeverity severity;
    String message;

    switch (alert.threatType) {
      case ContentThreatType.backspaceCoverUp:
        alertType = KeystrokeAlertType.backspaceCoverUp;
        severity = ThreatSeverity.critical;
        _backspaceCoverUpCount++;
        message =
            '🚨 COVER-UP: User typed "${_truncate(alert.deletedText, 40)}" '
            'then deleted it in [${_truncateApp(alert.foregroundApp)}] — '
            '${alert.analysis.alertType} detected';
        break;
      case ContentThreatType.sentThreatening:
        alertType = KeystrokeAlertType.sentThreatening;
        severity = ThreatSeverity.critical;
        message =
            '⚠️ SENT: Threatening content sent in [${_truncateApp(alert.foregroundApp)}] — '
            '"${_truncate(alert.typedText, 50)}"';
        break;
      case ContentThreatType.liveTyping:
        alertType = KeystrokeAlertType.contentThreat;
        severity = alert.analysis.severity >= 70
            ? ThreatSeverity.high
            : ThreatSeverity.medium;
        message =
            '🔴 TYPING: ${alert.analysis.alertType} detected in [${_truncateApp(alert.foregroundApp)}] — '
            'severity ${alert.analysis.severity}%';
        break;
    }

    _addAlert(alertType, message, alert.analysis.severity / 100.0, severity);
    _addLog(
      'THREAT',
      '${alert.threatType.name}: ${alert.analysis.flaggedWords.join(", ")} in ${_truncateApp(alert.foregroundApp)}',
    );

    notifyListeners();
  }

  void _onGlobalTextChanged(String text, String windowTitle) {
    _currentTypedText = text;
    _currentForegroundApp = windowTitle;
    notifyListeners();
  }

  void _onGlobalPhraseSent(SentPhrase phrase) {
    _sentPhrases.insert(0, phrase);
    if (_sentPhrases.length > 50) _sentPhrases.removeLast();

    _addLog(
      'SENT',
      '${phrase.isThreatening ? "⚠️ " : "✓ "}[${_truncateApp(phrase.foregroundApp)}] "${_truncate(phrase.text, 60)}"',
    );

    notifyListeners();
  }

  void _onGlobalKeyEvent(GlobalKeyEvent event) {
    // Update waveform from global key events (simulate dwell/flight)
    if (event.isDown) {
      // Use timestamp differences for waveform visualization
      final now = DateTime.now().millisecondsSinceEpoch;
      final jitter = (now % 50).toDouble() + 40;
      _dwellWaveform.add(jitter);
      if (_dwellWaveform.length > 40) _dwellWaveform.removeAt(0);
      _flightWaveform.add(jitter + 20 + (now % 30).toDouble());
      if (_flightWaveform.length > 40) _flightWaveform.removeAt(0);
      notifyListeners();
    }
  }

  String _truncate(String text, int maxLen) {
    if (text.length <= maxLen) return text;
    return '${text.substring(0, maxLen)}...';
  }

  String _truncateApp(String appTitle) {
    if (appTitle.length <= 30) return appTitle;
    return '${appTitle.substring(0, 30)}...';
  }

  // ────────────────────────────────────────────────────────
  // Live Key Processing (no enrollment needed)
  // ────────────────────────────────────────────────────────

  /// Called on every in-app key event — updates waveform and live metrics.
  void processLiveKey() {
    _currentWpm = _service.currentWpm;
    _currentDwellMs = _service.avgDwellMs;
    _currentFlightMs = _service.avgFlightMs;

    // Update waveforms from real typing data
    _updateWaveforms();

    notifyListeners();
  }

  // ────────────────────────────────────────────────────────
  // Live Monitoring
  // ────────────────────────────────────────────────────────

  void processMonitoringKey() {
    _currentWpm = _service.currentWpm;
    _currentDwellMs = _service.avgDwellMs;
    _currentFlightMs = _service.avgFlightMs;

    _updateWaveforms();

    // Generate alerts for significant anomalies (driven by threat detection)
    if (_anomalyScore > 0.7 &&
        (_alerts.isEmpty || _alerts.first.anomalyScore <= 0.7)) {
      _addAlert(
        KeystrokeAlertType.possibleSwitch,
        'Possible user switch — typing pattern divergence ${(_anomalyScore * 100).round()}%',
        _anomalyScore,
        ThreatSeverity.critical,
      );
    } else if (_anomalyScore > 0.4 &&
        (_alerts.isEmpty || _alerts.first.anomalyScore <= 0.4)) {
      _addAlert(
        KeystrokeAlertType.patternDrift,
        'Typing pattern drift detected — anomaly ${(_anomalyScore * 100).round()}%',
        _anomalyScore,
        ThreatSeverity.high,
      );
    }

    notifyListeners();
  }

  void _startSnapshotCapture() {
    _snapshotTimer?.cancel();
    _snapshotTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      // Gradually decay anomaly score when no new threats
      if (_anomalyScore > 0) {
        _anomalyScore = (_anomalyScore - 0.05).clamp(0.0, 1.0);
      }

      // Only capture snapshots when actively typing or threats detected
      if (_currentWpm <= 0 && _anomalyScore <= 0) return;

      final snapshot = KeystrokeSnapshot(
        avgDwellTimeMs: _currentDwellMs,
        avgFlightTimeMs: _currentFlightMs,
        wpm: _currentWpm,
        anomalyScore: _anomalyScore,
        keyCount: _service.keyCount,
        timestamp: DateTime.now(),
      );
      _history.add(snapshot);
      if (_history.length > 60) _history.removeAt(0);

      _addLog(
        'MONITOR',
        'Snapshot: WPM=${_currentWpm.round()} Dwell=${_currentDwellMs.round()}ms Anomaly=${(_anomalyScore * 100).round()}%',
      );

      notifyListeners();
    });
  }

  // ────────────────────────────────────────────────────────
  // Waveform
  // ────────────────────────────────────────────────────────

  void _updateWaveforms() {
    final dwells = _service.dwellTimes;
    final flights = _service.flightTimes;

    if (dwells.isNotEmpty) {
      _dwellWaveform.clear();
      final start = dwells.length > 40 ? dwells.length - 40 : 0;
      _dwellWaveform.addAll(dwells.sublist(start));
    }

    if (flights.isNotEmpty) {
      _flightWaveform.clear();
      final start = flights.length > 40 ? flights.length - 40 : 0;
      _flightWaveform.addAll(flights.sublist(start));
    }
  }

  // ────────────────────────────────────────────────────────
  // Alerts & Logs
  // ────────────────────────────────────────────────────────

  void _addAlert(
    KeystrokeAlertType type,
    String message,
    double score,
    ThreatSeverity severity,
  ) {
    _alerts.insert(
      0,
      KeystrokeAlert(
        id: 'KA-${DateTime.now().millisecondsSinceEpoch}-${_rng.nextInt(9999)}',
        alertType: type,
        message: message,
        anomalyScore: score,
        timestamp: DateTime.now(),
        severity: severity,
      ),
    );
    if (_alerts.length > 20) _alerts.removeLast();
  }

  void _addLog(String tag, String message) {
    final ts = DateTime.now();
    final timeStr =
        '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}:${ts.second.toString().padLeft(2, '0')}';
    _logMessages.insert(0, '[$timeStr] [$tag] $message');
    if (_logMessages.length > 50) _logMessages.removeLast();
  }

  // ────────────────────────────────────────────────────────
  // Demo Mode
  // ────────────────────────────────────────────────────────

  void toggleDemoMode() {
    _demoMode = !_demoMode;
    if (_demoMode) {
      _startDemoSimulation();
    } else {
      _stopDemoSimulation();
    }
    notifyListeners();
  }

  void _startDemoSimulation() {
    // Auto-enroll with fake baseline
    _baseline = KeystrokeBaseline(
      meanDwellMs: 82.0,
      stdDwellMs: 15.0,
      meanFlightMs: 110.0,
      stdFlightMs: 22.0,
      meanWpm: 65.0,
      totalSamples: 150,
      enrolledAt: DateTime.now(),
    );
    _mode = KeystrokeMode.monitoring;
    _enrollmentProgress = enrollmentTarget;
    _addLog('DEMO', 'Demo mode activated — simulating keystroke data');
    _addAlert(
      KeystrokeAlertType.enrollmentComplete,
      'Demo baseline loaded',
      0.0,
      ThreatSeverity.low,
    );

    _demoTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      // Simulate varying typing metrics
      final phase = DateTime.now().second % 30;
      double drift;
      if (phase < 15) {
        drift = 0.05 + _rng.nextDouble() * 0.15; // normal
      } else if (phase < 22) {
        drift = 0.35 + _rng.nextDouble() * 0.25; // suspicious
      } else {
        drift = 0.65 + _rng.nextDouble() * 0.3; // anomaly
      }

      _currentWpm = 50 + _rng.nextDouble() * 40;
      _currentDwellMs = 65 + _rng.nextDouble() * 35;
      _currentFlightMs = 85 + _rng.nextDouble() * 50;
      _anomalyScore = drift.clamp(0.0, 1.0);

      // Waveform data
      _dwellWaveform.add(60 + _rng.nextDouble() * 50);
      if (_dwellWaveform.length > 40) _dwellWaveform.removeAt(0);
      _flightWaveform.add(80 + _rng.nextDouble() * 60);
      if (_flightWaveform.length > 40) _flightWaveform.removeAt(0);

      // Snapshot
      _history.add(
        KeystrokeSnapshot(
          avgDwellTimeMs: _currentDwellMs,
          avgFlightTimeMs: _currentFlightMs,
          wpm: _currentWpm,
          anomalyScore: _anomalyScore,
          keyCount: _rng.nextInt(200) + 100,
          timestamp: DateTime.now(),
        ),
      );
      if (_history.length > 60) _history.removeAt(0);

      // Periodic alerts
      if (_anomalyScore > 0.6 && _rng.nextDouble() < 0.3) {
        _addAlert(
          _anomalyScore > 0.7
              ? KeystrokeAlertType.possibleSwitch
              : KeystrokeAlertType.anomalySpike,
          _anomalyScore > 0.7
              ? 'ALERT: Possible user switch detected — ${(_anomalyScore * 100).round()}% divergence'
              : 'Anomaly spike: typing rhythm deviation ${(_anomalyScore * 100).round()}%',
          _anomalyScore,
          _anomalyScore > 0.7 ? ThreatSeverity.critical : ThreatSeverity.high,
        );
      }

      _addLog(
        'MONITOR',
        'WPM=${_currentWpm.round()} Dwell=${_currentDwellMs.round()}ms Flight=${_currentFlightMs.round()}ms Anomaly=${(_anomalyScore * 100).round()}%',
      );

      notifyListeners();
    });
  }

  void _stopDemoSimulation() {
    _demoTimer?.cancel();
    _demoTimer = null;
    _addLog('DEMO', 'Demo mode deactivated');
  }

  // ────────────────────────────────────────────────────────
  // Reset
  // ────────────────────────────────────────────────────────

  void resetBaseline() {
    _baseline = null;
    _mode = KeystrokeMode.idle;
    _enrollmentProgress = 0;
    _anomalyScore = 0;
    _currentWpm = 0;
    _currentDwellMs = 0;
    _currentFlightMs = 0;
    _history.clear();
    _dwellWaveform.clear();
    _flightWaveform.clear();
    _service.reset();
    _snapshotTimer?.cancel();
    _addLog('RESET', 'Baseline cleared — re-enrollment required');
    _addAlert(
      KeystrokeAlertType.baselineReset,
      'Typing baseline has been reset',
      0.0,
      ThreatSeverity.medium,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _snapshotTimer?.cancel();
    _demoTimer?.cancel();
    _globalMonitor.dispose();
    super.dispose();
  }
}
