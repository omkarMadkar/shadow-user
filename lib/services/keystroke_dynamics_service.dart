import 'package:flutter/services.dart';

/// Raw timing data for a single key press.
class KeyTimingEvent {
  final String keyLabel;
  final int keyDownTs; // milliseconds since epoch
  int? keyUpTs;

  KeyTimingEvent({
    required this.keyLabel,
    required this.keyDownTs,
    this.keyUpTs,
  });

  /// Dwell time in ms (how long the key was held).
  double? get dwellTimeMs =>
      keyUpTs != null ? (keyUpTs! - keyDownTs).toDouble() : null;
}

/// Captures real keyboard timing (dwell & flight) without storing characters.
///
/// Only timing metadata is collected — no actual keystroke content is stored,
/// ensuring privacy-first design.
class KeystrokeDynamicsService {
  final List<KeyTimingEvent> _activeKeys = [];
  final List<double> _dwellTimes = [];
  final List<double> _flightTimes = [];
  int _keyCount = 0;
  int? _lastKeyUpTs;
  DateTime? _windowStart;

  // Rolling window (last N seconds)
  static const int windowDurationSec = 5;

  // Callbacks
  void Function(double dwellMs)? onDwell;
  void Function(double flightMs)? onFlight;
  void Function(int totalKeys)? onKeyCount;

  /// Process a raw key event from Flutter's keyboard system.
  void handleKeyEvent(KeyEvent event) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final label = event.logicalKey.keyLabel;

    if (label.isEmpty) return; // ignore modifier-only events

    if (event is KeyDownEvent) {
      _windowStart ??= DateTime.now();
      _activeKeys.add(KeyTimingEvent(keyLabel: label, keyDownTs: now));

      // Flight time = gap between last key-up and this key-down
      if (_lastKeyUpTs != null) {
        final flight = (now - _lastKeyUpTs!).toDouble();
        if (flight > 0 && flight < 2000) {
          _flightTimes.add(flight);
          onFlight?.call(flight);
        }
      }
    } else if (event is KeyUpEvent) {
      // Find matching key-down
      for (int i = _activeKeys.length - 1; i >= 0; i--) {
        if (_activeKeys[i].keyLabel == label &&
            _activeKeys[i].keyUpTs == null) {
          _activeKeys[i].keyUpTs = now;
          final dwell = _activeKeys[i].dwellTimeMs;
          if (dwell != null && dwell > 0 && dwell < 2000) {
            _dwellTimes.add(dwell);
            onDwell?.call(dwell);
          }
          break;
        }
      }
      _lastKeyUpTs = now;
      _keyCount++;
      onKeyCount?.call(_keyCount);
    }

    // Trim old active keys (cleanup)
    _activeKeys.removeWhere(
      (k) => k.keyUpTs != null && (now - k.keyUpTs!) > 10000,
    );
  }

  /// Current words per minute (estimated from key count over time window).
  double get currentWpm {
    if (_windowStart == null) return 0;
    final elapsed = DateTime.now().difference(_windowStart!).inSeconds;
    if (elapsed < 1) return 0;
    // Average word = 5 chars
    return (_keyCount / 5) / (elapsed / 60);
  }

  /// Average dwell time across all captured samples.
  double get avgDwellMs {
    if (_dwellTimes.isEmpty) return 0;
    return _dwellTimes.reduce((a, b) => a + b) / _dwellTimes.length;
  }

  /// Average flight time across all captured samples.
  double get avgFlightMs {
    if (_flightTimes.isEmpty) return 0;
    return _flightTimes.reduce((a, b) => a + b) / _flightTimes.length;
  }

  /// Standard deviation of dwell times.
  double get stdDwellMs => _std(_dwellTimes);

  /// Standard deviation of flight times.
  double get stdFlightMs => _std(_flightTimes);

  /// Total key events captured.
  int get keyCount => _keyCount;

  /// Raw dwell times (read only copy).
  List<double> get dwellTimes => List.unmodifiable(_dwellTimes);

  /// Raw flight times (read only copy).
  List<double> get flightTimes => List.unmodifiable(_flightTimes);

  /// Reset all captured data.
  void reset() {
    _activeKeys.clear();
    _dwellTimes.clear();
    _flightTimes.clear();
    _keyCount = 0;
    _lastKeyUpTs = null;
    _windowStart = null;
  }

  double _std(List<double> values) {
    if (values.length < 2) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final sumSqDiff = values.fold<double>(
      0,
      (sum, v) => sum + (v - mean) * (v - mean),
    );
    return _sqrt(sumSqDiff / (values.length - 1));
  }

  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
}
