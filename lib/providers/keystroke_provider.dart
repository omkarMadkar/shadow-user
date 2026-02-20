import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/keystroke_dynamics_service.dart';

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
  KeystrokeMode _mode = KeystrokeMode.idle;
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

  // ────────────────────────────────────────────────────────
  // Enrollment
  // ────────────────────────────────────────────────────────

  void startEnrollment() {
    _mode = KeystrokeMode.enrolling;
    _enrollmentProgress = 0;
    _service.reset();
    _dwellWaveform.clear();
    _flightWaveform.clear();
    _addLog('ENROLL', 'Enrollment started — type the sample text');
    notifyListeners();
  }

  /// Called on each key event during enrollment.
  void processEnrollmentKey() {
    _enrollmentProgress = _service.keyCount;
    _currentWpm = _service.currentWpm;
    _currentDwellMs = _service.avgDwellMs;
    _currentFlightMs = _service.avgFlightMs;

    // Update waveforms
    _updateWaveforms();

    if (_enrollmentProgress >= enrollmentTarget) {
      _completeEnrollment();
    }
    notifyListeners();
  }

  void _completeEnrollment() {
    _baseline = KeystrokeBaseline(
      meanDwellMs: _service.avgDwellMs,
      stdDwellMs: _service.stdDwellMs,
      meanFlightMs: _service.avgFlightMs,
      stdFlightMs: _service.stdFlightMs,
      meanWpm: _service.currentWpm,
      totalSamples: _service.keyCount,
      enrolledAt: DateTime.now(),
    );
    _mode = KeystrokeMode.monitoring;
    _service.reset();
    _addLog('ENROLL', 'Baseline captured — monitoring active');
    _addAlert(
      KeystrokeAlertType.enrollmentComplete,
      'Typing profile enrolled successfully',
      0.0,
      ThreatSeverity.low,
    );
    _startSnapshotCapture();
    notifyListeners();
  }

  // ────────────────────────────────────────────────────────
  // Live Monitoring
  // ────────────────────────────────────────────────────────

  void processMonitoringKey() {
    if (_baseline == null) return;

    _currentWpm = _service.currentWpm;
    _currentDwellMs = _service.avgDwellMs;
    _currentFlightMs = _service.avgFlightMs;

    // Compute anomaly score via Z-score distance
    _anomalyScore = _computeAnomalyScore();

    _updateWaveforms();

    // Generate alerts for significant anomalies
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

  double _computeAnomalyScore() {
    if (_baseline == null) return 0;
    final b = _baseline!;

    // Z-score for dwell
    final dwellZ = b.stdDwellMs > 0
        ? ((_currentDwellMs - b.meanDwellMs) / b.stdDwellMs).abs()
        : 0.0;

    // Z-score for flight
    final flightZ = b.stdFlightMs > 0
        ? ((_currentFlightMs - b.meanFlightMs) / b.stdFlightMs).abs()
        : 0.0;

    // WPM deviation (normalized)
    final wpmDev = b.meanWpm > 0
        ? ((_currentWpm - b.meanWpm) / b.meanWpm).abs()
        : 0.0;

    // Combined score (weighted average, clamped 0–1)
    final combined = (dwellZ * 0.4 + flightZ * 0.4 + wpmDev * 0.2) / 3.0;
    return combined.clamp(0.0, 1.0);
  }

  void _startSnapshotCapture() {
    _snapshotTimer?.cancel();
    _snapshotTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_mode != KeystrokeMode.monitoring) return;

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
    super.dispose();
  }
}
