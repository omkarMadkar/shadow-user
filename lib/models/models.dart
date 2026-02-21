// Data models for the Shadow Sentinel application.

// ─── Enums ───────────────────────────────────────────────────

enum ThreatSeverity { low, medium, high, critical }

enum UserVerificationStatus { verified, monitoring, flagged, locked }

enum SentinelModuleState { active, paused, error, capturing }

enum ProductivityState { deepWork, focused, distracted, burnoutRisk, offline }

// ─── Keystroke Metrics ───────────────────────────────────────

class KeystrokeMetrics {
  final double cadenceWpm;
  final double patternDrift;
  final double holdTimeMean;
  final double flightTimeMean;
  final DateTime timestamp;

  const KeystrokeMetrics({
    required this.cadenceWpm,
    required this.patternDrift,
    required this.holdTimeMean,
    required this.flightTimeMean,
    required this.timestamp,
  });

  KeystrokeMetrics copyWith({
    double? cadenceWpm,
    double? patternDrift,
    double? holdTimeMean,
    double? flightTimeMean,
    DateTime? timestamp,
  }) {
    return KeystrokeMetrics(
      cadenceWpm: cadenceWpm ?? this.cadenceWpm,
      patternDrift: patternDrift ?? this.patternDrift,
      holdTimeMean: holdTimeMean ?? this.holdTimeMean,
      flightTimeMean: flightTimeMean ?? this.flightTimeMean,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

// ─── Neural Scan Result ──────────────────────────────────────

class NeuralScanResult {
  final double confidence;
  final bool matched;
  final DateTime timestamp;
  final Duration scanDuration;

  const NeuralScanResult({
    required this.confidence,
    required this.matched,
    required this.timestamp,
    required this.scanDuration,
  });
}

// ─── Security Event ──────────────────────────────────────────

class SecurityEvent {
  final String id;
  final String message;
  final ThreatSeverity severity;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const SecurityEvent({
    required this.id,
    required this.message,
    required this.severity,
    required this.timestamp,
    this.metadata,
  });
}

// ─── Productivity Slot ───────────────────────────────────────

class ProductivitySlot {
  final ProductivityState state;
  final double intensity;
  final int dayIndex;
  final int hourIndex;

  const ProductivitySlot({
    required this.state,
    required this.intensity,
    required this.dayIndex,
    required this.hourIndex,
  });
}

// ─── Threat Info ─────────────────────────────────────────────

class ThreatInfo {
  final String label;
  int count;
  final String trend;
  final ThreatSeverity severity;

  ThreatInfo({
    required this.label,
    required this.count,
    required this.trend,
    required this.severity,
  });
}

// ─── Online User ─────────────────────────────────────────────

class OnlineUser {
  final String name;
  final double trustScore;
  final UserVerificationStatus status;
  final String department;

  const OnlineUser({
    required this.name,
    required this.trustScore,
    required this.status,
    required this.department,
  });
}

// ─── Email Threat Types ──────────────────────────────────────

enum EmailThreatType { phishing, malware, spoofing, spam, suspicious, safe }

enum EmailThreatStatus { blocked, quarantined, flagged, delivered }

// ─── Email Threat ────────────────────────────────────────────

class EmailThreat {
  final String id;
  final String sender;
  final String senderDomain;
  final String subject;
  final String recipient;
  final EmailThreatType threatType;
  final EmailThreatStatus status;
  final double riskScore;
  final DateTime timestamp;
  final String analysisDetail;
  final List<String> indicators;

  const EmailThreat({
    required this.id,
    required this.sender,
    required this.senderDomain,
    required this.subject,
    required this.recipient,
    required this.threatType,
    required this.status,
    required this.riskScore,
    required this.timestamp,
    required this.analysisDetail,
    required this.indicators,
  });
}

// ─── Email Scan Result ───────────────────────────────────────

class EmailScanResult {
  final int totalScanned;
  final int threatsBlocked;
  final int safeEmails;
  final int quarantined;
  final int pendingReview;
  final Map<EmailThreatType, int> threatBreakdown;

  const EmailScanResult({
    required this.totalScanned,
    required this.threatsBlocked,
    required this.safeEmails,
    required this.quarantined,
    required this.pendingReview,
    required this.threatBreakdown,
  });

  double get safeRatio =>
      totalScanned > 0 ? (safeEmails / totalScanned) * 100 : 100;
  double get blockRate =>
      totalScanned > 0 ? (threatsBlocked / totalScanned) * 100 : 0;
}

// ─── Face Scan Frame ─────────────────────────────────────────

class FaceScanFrame {
  final double confidence;
  final double livenessScore;
  final bool matched;
  final bool spoofingAttempt;
  final DateTime timestamp;
  final String scanMode;

  const FaceScanFrame({
    required this.confidence,
    required this.livenessScore,
    required this.matched,
    required this.spoofingAttempt,
    required this.timestamp,
    required this.scanMode,
  });
}

// ─── Camera Session Log ──────────────────────────────────────

class CameraSessionLog {
  final String id;
  final DateTime timestamp;
  final double confidence;
  final double livenessScore;
  final bool matched;
  final bool spoofingAttempt;
  final String detail;

  const CameraSessionLog({
    required this.id,
    required this.timestamp,
    required this.confidence,
    required this.livenessScore,
    required this.matched,
    required this.spoofingAttempt,
    required this.detail,
  });
}

// ─── Voice Sentinel Enums ────────────────────────────────────

enum VoiceSeverity { clean, mild, moderate, severe }

enum VoiceSessionStatus { recording, paused, completed, error }

enum LanguageAlertType { profanity, hostility, threat, harassment, toxic }

// ─── Voice Audio Chunk ───────────────────────────────────────

class VoiceAudioChunk {
  final String id;
  final String sessionId;
  final String filePath;
  final Duration duration;
  final DateTime timestamp;
  final double volumeDb;
  final String? transcript;
  final VoiceSeverity severity;
  final List<String> flaggedWords;

  const VoiceAudioChunk({
    required this.id,
    required this.sessionId,
    required this.filePath,
    required this.duration,
    required this.timestamp,
    required this.volumeDb,
    this.transcript,
    required this.severity,
    required this.flaggedWords,
  });
}

// ─── Voice Language Alert ────────────────────────────────────

class VoiceLanguageAlert {
  final String id;
  final String sessionId;
  final String chunkId;
  final LanguageAlertType alertType;
  final VoiceSeverity severity;
  final String flaggedPhrase;
  final String context;
  final double confidenceScore;
  final DateTime timestamp;

  const VoiceLanguageAlert({
    required this.id,
    required this.sessionId,
    required this.chunkId,
    required this.alertType,
    required this.severity,
    required this.flaggedPhrase,
    required this.context,
    required this.confidenceScore,
    required this.timestamp,
  });
}

// ─── Voice Session ───────────────────────────────────────────

class VoiceSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final VoiceSessionStatus status;
  final int totalChunks;
  final int alertCount;
  final double avgVolume;
  final Duration totalDuration;

  const VoiceSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.totalChunks,
    required this.alertCount,
    required this.avgVolume,
    required this.totalDuration,
  });
}

// ─── Voice Waveform Sample ───────────────────────────────────

class VoiceWaveformSample {
  final double amplitude;
  final DateTime timestamp;
  final bool isFlagged;

  const VoiceWaveformSample({
    required this.amplitude,
    required this.timestamp,
    this.isFlagged = false,
  });
}

// ─── Transcription Segment ───────────────────────────────────

/// A segment of transcribed speech with metadata.
class TranscriptionSegment {
  final String id;
  final String text;
  final DateTime timestamp;
  final bool isFlagged;
  final List<String> flaggedWords;
  final String sessionId;
  final double confidence;

  const TranscriptionSegment({
    required this.id,
    required this.text,
    required this.timestamp,
    this.isFlagged = false,
    this.flaggedWords = const [],
    required this.sessionId,
    this.confidence = 0.95,
  });
}

// ─── Translation Summary ─────────────────────────────────────

/// A time-windowed summary of translated/transcribed speech.
class TranslationSummary {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final String topic;
  final String summary;
  final String tone;
  final List<String> keyPoints;
  final int segmentCount;
  final bool hasFlaggedContent;
  final List<String> flaggedWords;
  final double avgConfidence;

  const TranslationSummary({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.topic,
    required this.summary,
    required this.tone,
    required this.keyPoints,
    required this.segmentCount,
    this.hasFlaggedContent = false,
    this.flaggedWords = const [],
    this.avgConfidence = 0.90,
  });
}

// ─── Threat Report ───────────────────────────────────────────

/// Evidence bundle captured when Voice Sentinel flags bad content.
/// Contains screenshot, face photo, audio chunk path and text context.
class ThreatReport {
  final String id;
  final DateTime timestamp;

  /// One of: profanity, hostility, threat, harassment, negative
  final String alertType;
  final VoiceSeverity severity;
  final List<String> flaggedWords;
  final String transcript;

  /// Absolute path to the .wav audio chunk that was flagged.
  final String audioChunkPath;

  /// Absolute path to the screen capture PNG (null if capture failed).
  final String? screenshotPath;

  /// Absolute path to the webcam JPEG (null if camera unavailable).
  final String? facePhotoPath;

  const ThreatReport({
    required this.id,
    required this.timestamp,
    required this.alertType,
    required this.severity,
    required this.flaggedWords,
    required this.transcript,
    required this.audioChunkPath,
    this.screenshotPath,
    this.facePhotoPath,
  });
}

// ─── Keystroke Snapshot ──────────────────────────────────────

/// A single point-in-time capture of typing timing metrics.
class KeystrokeSnapshot {
  final double avgDwellTimeMs;
  final double avgFlightTimeMs;
  final double wpm;
  final double anomalyScore; // 0.0 = match, 1.0 = mismatch
  final int keyCount;
  final DateTime timestamp;

  const KeystrokeSnapshot({
    required this.avgDwellTimeMs,
    required this.avgFlightTimeMs,
    required this.wpm,
    required this.anomalyScore,
    required this.keyCount,
    required this.timestamp,
  });
}

// ─── Keystroke Baseline ──────────────────────────────────────

/// The enrolled typing profile used as reference for anomaly detection.
class KeystrokeBaseline {
  final double meanDwellMs;
  final double stdDwellMs;
  final double meanFlightMs;
  final double stdFlightMs;
  final double meanWpm;
  final int totalSamples;
  final DateTime enrolledAt;

  const KeystrokeBaseline({
    required this.meanDwellMs,
    required this.stdDwellMs,
    required this.meanFlightMs,
    required this.stdFlightMs,
    required this.meanWpm,
    required this.totalSamples,
    required this.enrolledAt,
  });
}

// ─── Keystroke Alert ─────────────────────────────────────────

enum KeystrokeAlertType {
  patternDrift,
  possibleSwitch,
  anomalySpike,
  enrollmentComplete,
  baselineReset,
  contentThreat,
  backspaceCoverUp,
  sentThreatening,
}

class KeystrokeAlert {
  final String id;
  final KeystrokeAlertType alertType;
  final String message;
  final double anomalyScore;
  final DateTime timestamp;
  final ThreatSeverity severity;

  const KeystrokeAlert({
    required this.id,
    required this.alertType,
    required this.message,
    required this.anomalyScore,
    required this.timestamp,
    required this.severity,
  });
}

/// Represents a camera capture triggered by keystroke bad-word detection.
/// Stored by [SentinelProvider] and displayed in the Neural Camera screen
/// and the Admin captures panel.
class KeystrokeCameraTrigger {
  final List<String> flaggedWords;
  final String triggerText;
  final String alertType; // liveTyping | sentThreatening | backspaceCoverUp
  final bool? faceVerified;
  final double faceConfidence;
  final String? screenshotPath;
  final String? facePhotoPath;
  final DateTime timestamp;

  const KeystrokeCameraTrigger({
    required this.flaggedWords,
    required this.triggerText,
    required this.alertType,
    required this.faceVerified,
    required this.faceConfidence,
    this.screenshotPath,
    this.facePhotoPath,
    required this.timestamp,
  });
}
