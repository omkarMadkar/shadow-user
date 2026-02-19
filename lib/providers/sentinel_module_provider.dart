import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

/// Abstract base class for all Shadow Sentinel monitoring module providers.
///
/// Provides shared infrastructure that every monitoring module needs:
/// - **ID generation** — unique, prefixed, timestamp-based IDs
/// - **Duration formatting** — `HH:MM:SS` display strings
/// - **Severity scoring** — numeric (0-100) → [VoiceSeverity] enum mapping
///
/// Future modules (Camera Sentinel, Keystroke Sentinel, etc.) should
/// extend this class to inherit the common patterns established by
/// Voice Sentinel, avoiding duplication of boilerplate across modules.
///
/// ```dart
/// class CameraSentinelProvider extends SentinelModuleProvider {
///   // Inherits generateId(), formatDuration(), severityFromScore()
///   // Focus only on camera-specific logic.
/// }
/// ```
abstract class SentinelModuleProvider extends ChangeNotifier {
  /// Shared random number generator available to all subclasses.
  ///
  /// Used internally by [generateId] and available for subclass use
  /// (e.g. simulated volume values, random jitter).
  @protected
  final Random moduleRng = Random();

  // ── ID Generation ────────────────────────────────────────

  /// Generate a unique identifier with the given [prefix].
  ///
  /// Format: `prefix-millisecondsSinceEpoch-random(0-9999)`
  ///
  /// Examples:
  /// - `generateId('vs')` → `vs-1708300000000-4271`
  /// - `generateId('vc')` → `vc-1708300001234-0092`
  @protected
  String generateId(String prefix) {
    return '$prefix-${DateTime.now().millisecondsSinceEpoch}-${moduleRng.nextInt(9999)}';
  }

  // ── Duration Formatting ──────────────────────────────────

  /// Format a [Duration] into a zero-padded `HH:MM:SS` string.
  ///
  /// ```dart
  /// formatDuration(Duration(hours: 1, minutes: 5, seconds: 3));
  /// // → '01:05:03'
  /// ```
  String formatDuration(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes % 60;
    final s = duration.inSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  // ── Severity Scoring ─────────────────────────────────────

  /// Map a numeric severity score (0–100) to a [VoiceSeverity] enum.
  ///
  /// | Score Range | Severity |
  /// |-------------|----------|
  /// | 80–100      | severe   |
  /// | 50–79       | moderate |
  /// | 20–49       | mild     |
  /// | 0–19        | clean    |
  @protected
  VoiceSeverity severityFromScore(int score) {
    if (score >= 80) return VoiceSeverity.severe;
    if (score >= 50) return VoiceSeverity.moderate;
    if (score >= 20) return VoiceSeverity.mild;
    return VoiceSeverity.clean;
  }
}
