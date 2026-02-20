import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

/// API Service for Shadow Sentinel Backend communication.
///
/// Handles REST calls to:
/// - Face verification
/// - Keystroke analysis
/// - Threat detection
/// - Trust score calculation
///
/// Includes retry logic, timeout handling, and graceful fallback.
class ApiService {
  /// Base URL for the backend API
  static const String _defaultBaseUrl = 'http://localhost:8000';

  /// Connection timeout
  static const Duration _timeout = Duration(seconds: 10);

  /// Retry attempts for failed requests
  static const int _maxRetries = 2;

  final String baseUrl;
  final HttpClient _client;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  DateTime? _lastHealthCheck;

  ApiService({String? baseUrl})
    : baseUrl = baseUrl ?? _defaultBaseUrl,
      _client = HttpClient() {
    _client.connectionTimeout = _timeout;
  }

  // ─── Health Check ────────────────────────────────────────────

  /// Check if the backend server is reachable.
  Future<bool> checkHealth() async {
    try {
      final response = await _get('/health');
      _isConnected = response != null && response['status'] == 'healthy';
      _lastHealthCheck = DateTime.now();
      debugPrint('[ApiService] Health check: $_isConnected');
      return _isConnected;
    } catch (e) {
      _isConnected = false;
      debugPrint('[ApiService] Health check failed: $e');
      return false;
    }
  }

  // ─── Face Verification ───────────────────────────────────────

  /// Verify a face against enrolled baseline.
  ///
  /// Returns a [FaceVerifyResult] with confidence, liveness, and match status.
  Future<FaceVerifyResult> verifyFace({
    required String userId,
    String? imageBase64,
    bool demoMode = true,
    bool? simulateMatch,
    bool simulateSpoofing = false,
  }) async {
    try {
      final response = await _post('/api/face/verify', {
        'user_id': userId,
        if (imageBase64 != null) 'image_base64': imageBase64,
        'demo_mode': demoMode,
        if (simulateMatch != null) 'simulate_match': simulateMatch,
        'simulate_spoofing': simulateSpoofing,
      });

      if (response != null && response['success'] == true) {
        return FaceVerifyResult(
          success: true,
          matched: response['matched'] ?? false,
          confidence: (response['confidence'] ?? 0).toDouble(),
          livenessScore: (response['liveness_score'] ?? 0).toDouble(),
          spoofingDetected: response['spoofing_detected'] ?? false,
          faceDetected: response['face_detected'] ?? false,
          scanMode: response['scan_mode'] ?? 'UNKNOWN',
        );
      }
    } catch (e) {
      debugPrint('[ApiService] Face verify error: $e');
    }

    // Fallback result
    return FaceVerifyResult.fallback();
  }

  /// Enroll a face baseline for a user.
  Future<bool> enrollFace({
    required String userId,
    String? imageBase64,
    bool demoMode = true,
  }) async {
    try {
      final response = await _post('/api/face/enroll', {
        'user_id': userId,
        if (imageBase64 != null) 'image_base64': imageBase64,
        'demo_mode': demoMode,
      });
      return response?['enrolled'] == true;
    } catch (e) {
      debugPrint('[ApiService] Face enroll error: $e');
      return false;
    }
  }

  // ─── Keystroke Analysis ──────────────────────────────────────

  /// Analyze keystroke patterns for anomalies.
  ///
  /// Returns a [KeystrokeAnalysisResult] with anomaly score and match score.
  Future<KeystrokeAnalysisResult> analyzeKeystroke({
    required String userId,
    List<double> dwellTimes = const [],
    List<double> flightTimes = const [],
    double? wpm,
    int keyCount = 0,
    bool demoMode = true,
    double? simulateAnomaly,
  }) async {
    try {
      final response = await _post('/api/keystroke/analyze', {
        'user_id': userId,
        'metrics': {
          'dwell_times': dwellTimes,
          'flight_times': flightTimes,
          'wpm': wpm,
          'key_count': keyCount,
        },
        'demo_mode': demoMode,
        if (simulateAnomaly != null) 'simulate_anomaly': simulateAnomaly,
      });

      if (response != null && response['success'] == true) {
        return KeystrokeAnalysisResult(
          success: true,
          anomalyScore: (response['anomaly_score'] ?? 0).toDouble(),
          matchScore: (response['match_score'] ?? 80).toDouble(),
          riskLevel: response['risk_level'] ?? 'UNKNOWN',
          recommendation: response['recommendation'] ?? '',
        );
      }
    } catch (e) {
      debugPrint('[ApiService] Keystroke analyze error: $e');
    }

    return KeystrokeAnalysisResult.fallback();
  }

  /// Enroll a keystroke baseline for a user.
  Future<bool> enrollKeystroke({
    required String userId,
    required List<double> dwellTimes,
    required List<double> flightTimes,
    double? wpm,
    bool demoMode = true,
  }) async {
    try {
      final response = await _post('/api/keystroke/enroll', {
        'user_id': userId,
        'metrics': {
          'dwell_times': dwellTimes,
          'flight_times': flightTimes,
          'wpm': wpm,
          'key_count': dwellTimes.length,
        },
        'demo_mode': demoMode,
      });
      return response?['enrolled'] == true;
    } catch (e) {
      debugPrint('[ApiService] Keystroke enroll error: $e');
      return false;
    }
  }

  // ─── Threat Detection ────────────────────────────────────────

  /// Detect threats from activity metadata.
  ///
  /// Returns a [ThreatDetectResult] with threat score and safety score.
  Future<ThreatDetectResult> detectThreats({
    required String userId,
    String? activeWindow,
    String? activeApp,
    List<String> recentUrls = const [],
    List<String> appsRunning = const [],
    int? hourOfDay,
    int? sessionDurationMinutes,
    bool demoMode = true,
    double? simulateThreat,
    bool simulatePhishing = false,
    bool simulateBurnout = false,
  }) async {
    try {
      final response = await _post('/api/threat/detect', {
        'user_id': userId,
        'activity': {
          'active_window': activeWindow,
          'active_app': activeApp,
          'recent_urls': recentUrls,
          'apps_running': appsRunning,
          'hour_of_day': hourOfDay ?? DateTime.now().hour,
          'session_duration_minutes': sessionDurationMinutes,
        },
        'demo_mode': demoMode,
        if (simulateThreat != null) 'simulate_threat': simulateThreat,
        'simulate_phishing': simulatePhishing,
        'simulate_burnout': simulateBurnout,
      });

      if (response != null && response['success'] == true) {
        // return ThreatDetectResult(
        //   success: true,
        //   threatScore: (response['threat_score'] ?? 0).toDouble(),
        //   safetyScore: (response['safety_score'] ?? 90).toDouble(),
        //   riskLevel: response['risk_level'] ?? 'LOW',
        //   burnoutRisk: (response['burnout_risk'] ?? 20).toDouble(),
        //   productivityScore: (response['productivity_score'] ?? 75).toDouble(),
        //   recommendation: response['recommendation'] ?? '',
        //   //threatsDetected: _parseThreats(response['threats_detected']),
        // );
      }
    } catch (e) {
      debugPrint('[ApiService] Threat detect error: $e');
    }

    return ThreatDetectResult.fallback();
  }

  // List<ThreatInfo> _parseThreats(dynamic threats) {
  //   if (threats == null || threats is! List) return [];
  //   return threats
  //       .map<ThreatInfo>(
  //         (t) => ThreatInfo(
  //           type: t['type'] ?? 'unknown',
  //           severity: t['severity'] ?? 'low',
  //           description: t['description'] ?? '',
  //           indicator: t['indicator'] ?? '',
  //           confidence: (t['confidence'] ?? 50).toDouble(),
  //         ),
  //       )
  //       .toList();
  // }

  // ─── Trust Score ─────────────────────────────────────────────

  /// Calculate unified trust score from component scores.
  ///
  /// Formula: (0.40 × Face) + (0.40 × Keystroke) + (0.20 × Activity Safety)
  Future<TrustScoreResult> calculateTrustScore({
    double? faceConfidence,
    double? keystrokeMatch,
    double? activitySafety,
  }) async {
    try {
      final response = await _post('/api/trust/score', {
        if (faceConfidence != null) 'face_confidence': faceConfidence,
        if (keystrokeMatch != null) 'keystroke_match': keystrokeMatch,
        if (activitySafety != null) 'activity_safety': activitySafety,
      });

      if (response != null && response['success'] == true) {
        return TrustScoreResult(
          success: true,
          trustScore: (response['trust_score'] ?? 80).toDouble(),
          riskLevel: response['risk_level'] ?? 'MEDIUM',
          recommendation: response['recommendation'] ?? '',
          components: response['components'] ?? {},
        );
      }
    } catch (e) {
      debugPrint('[ApiService] Trust score error: $e');
    }

    // Local fallback calculation
    final face = faceConfidence ?? 85.0;
    final keystroke = keystrokeMatch ?? 80.0;
    final activity = activitySafety ?? 90.0;
    final score = (0.40 * face) + (0.40 * keystroke) + (0.20 * activity);

    return TrustScoreResult(
      success: false,
      trustScore: score,
      riskLevel: score >= 80
          ? 'LOW'
          : score >= 60
          ? 'MEDIUM'
          : score >= 40
          ? 'HIGH'
          : 'CRITICAL',
      recommendation: 'Local calculation (server unavailable)',
      components: {
        'face_confidence': face,
        'keystroke_match': keystroke,
        'activity_safety': activity,
      },
    );
  }

  // ─── HTTP Helpers ────────────────────────────────────────────

  Future<Map<String, dynamic>?> _get(String endpoint) async {
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final uri = Uri.parse('$baseUrl$endpoint');
        final request = await _client.getUrl(uri);
        request.headers.set('Accept', 'application/json');

        final response = await request.close().timeout(_timeout);

        if (response.statusCode == 200) {
          final body = await response.transform(utf8.decoder).join();
          return jsonDecode(body) as Map<String, dynamic>;
        }
      } on SocketException catch (e) {
        debugPrint('[ApiService] Socket error (attempt $attempt): $e');
        if (attempt == _maxRetries) rethrow;
      } on TimeoutException catch (e) {
        debugPrint('[ApiService] Timeout (attempt $attempt): $e');
        if (attempt == _maxRetries) rethrow;
      } catch (e) {
        debugPrint('[ApiService] GET error: $e');
        if (attempt == _maxRetries) rethrow;
      }

      // Wait before retry
      await Future.delayed(Duration(milliseconds: 200 * (attempt + 1)));
    }
    return null;
  }

  Future<Map<String, dynamic>?> _post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final uri = Uri.parse('$baseUrl$endpoint');
        final request = await _client.postUrl(uri);
        request.headers.set('Content-Type', 'application/json');
        request.headers.set('Accept', 'application/json');
        request.write(jsonEncode(body));

        final response = await request.close().timeout(_timeout);
        final responseBody = await response.transform(utf8.decoder).join();

        if (response.statusCode == 200) {
          return jsonDecode(responseBody) as Map<String, dynamic>;
        } else {
          debugPrint('[ApiService] POST $endpoint: ${response.statusCode}');
          debugPrint('[ApiService] Response: $responseBody');
        }
      } on SocketException catch (e) {
        debugPrint('[ApiService] Socket error (attempt $attempt): $e');
        if (attempt == _maxRetries) rethrow;
      } on TimeoutException catch (e) {
        debugPrint('[ApiService] Timeout (attempt $attempt): $e');
        if (attempt == _maxRetries) rethrow;
      } catch (e) {
        debugPrint('[ApiService] POST error: $e');
        if (attempt == _maxRetries) rethrow;
      }

      await Future.delayed(Duration(milliseconds: 200 * (attempt + 1)));
    }
    return null;
  }

  void dispose() {
    _client.close();
  }
}

// ─── Result Models ─────────────────────────────────────────────

/// Result from face verification API.
class FaceVerifyResult {
  final bool success;
  final bool matched;
  final double confidence;
  final double livenessScore;
  final bool spoofingDetected;
  final bool faceDetected;
  final String scanMode;

  const FaceVerifyResult({
    required this.success,
    required this.matched,
    required this.confidence,
    required this.livenessScore,
    required this.spoofingDetected,
    required this.faceDetected,
    required this.scanMode,
  });

  /// Fallback result when API unavailable
  factory FaceVerifyResult.fallback() => const FaceVerifyResult(
    success: false,
    matched: true,
    confidence: 85.0,
    livenessScore: 90.0,
    spoofingDetected: false,
    faceDetected: true,
    scanMode: 'FALLBACK',
  );
}

/// Result from keystroke analysis API.
class KeystrokeAnalysisResult {
  final bool success;
  final double anomalyScore;
  final double matchScore;
  final String riskLevel;
  final String recommendation;

  const KeystrokeAnalysisResult({
    required this.success,
    required this.anomalyScore,
    required this.matchScore,
    required this.riskLevel,
    required this.recommendation,
  });

  factory KeystrokeAnalysisResult.fallback() => const KeystrokeAnalysisResult(
    success: false,
    anomalyScore: 0.15,
    matchScore: 85.0,
    riskLevel: 'LOW',
    recommendation: 'Fallback mode',
  );
}

/// Result from threat detection API.
class ThreatDetectResult {
  final bool success;
  final double threatScore;
  final double safetyScore;
  final String riskLevel;
  final double burnoutRisk;
  final double productivityScore;
  final String recommendation;
  final List<ThreatInfo> threatsDetected;

  const ThreatDetectResult({
    required this.success,
    required this.threatScore,
    required this.safetyScore,
    required this.riskLevel,
    required this.burnoutRisk,
    required this.productivityScore,
    required this.recommendation,
    required this.threatsDetected,
  });

  factory ThreatDetectResult.fallback() => const ThreatDetectResult(
    success: false,
    threatScore: 10.0,
    safetyScore: 90.0,
    riskLevel: 'LOW',
    burnoutRisk: 20.0,
    productivityScore: 75.0,
    recommendation: 'Fallback mode',
    threatsDetected: [],
  );
}

/// Result from trust score calculation API.
class TrustScoreResult {
  final bool success;
  final double trustScore;
  final String riskLevel;
  final String recommendation;
  final Map<String, dynamic> components;

  const TrustScoreResult({
    required this.success,
    required this.trustScore,
    required this.riskLevel,
    required this.recommendation,
    required this.components,
  });
}
