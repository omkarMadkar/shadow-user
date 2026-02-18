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
