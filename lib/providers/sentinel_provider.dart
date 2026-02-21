import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';
import '../services/face_verification_service.dart';
import '../services/api_service.dart';

/// Central state management for the Shadow Sentinel dashboard.
///
/// Manages trust score, keystroke metrics, neural scan results,
/// security events, productivity heatmap, threat data,
/// email fraud detection, and neural camera detection.
///
/// Now integrates with Python backend API for real AI analysis.
class SentinelProvider extends ChangeNotifier {
  final Random _rng = Random();

  // ── API Service ────────────────────────────────────────────
  final ApiService _api = ApiService();
  ApiService get api => _api;

  bool _apiConnected = false;
  bool get apiConnected => _apiConnected;

  // ── Demo Mode Controls ─────────────────────────────────────
  bool _demoModeEnabled = true;
  bool get demoModeEnabled => _demoModeEnabled;

  /// Active demo scenario (null = normal operation)
  DemoScenario? _activeScenario;
  DemoScenario? get activeScenario => _activeScenario;

  // ── Trust Score Components ─────────────────────────────────
  double _faceConfidence = 95.0;
  double _keystrokeMatch = 87.0;
  double _activitySafety = 90.0;

  double get faceConfidence => _faceConfidence;
  double get keystrokeMatch => _keystrokeMatch;
  double get activitySafety => _activitySafety;

  // ── Trust Score ──────────────────────────────────────────
  double _trustScore = 87.0;
  double _targetTrust = 87.0;
  double get trustScore => _trustScore;

  String _trustRiskLevel = 'LOW';
  String get trustRiskLevel => _trustRiskLevel;

  // ── Module States ────────────────────────────────────────
  final SentinelModuleState _keystrokeState = SentinelModuleState.active;
  SentinelModuleState _cameraState = SentinelModuleState.active;
  SentinelModuleState get keystrokeState => _keystrokeState;
  SentinelModuleState get cameraState => _cameraState;

  // ── Keystroke Metrics ────────────────────────────────────
  KeystrokeMetrics _keystrokeMetrics = KeystrokeMetrics(
    cadenceWpm: 142,
    patternDrift: 0.024,
    holdTimeMean: 85.3,
    flightTimeMean: 112.7,
    timestamp: DateTime.now(),
  );
  KeystrokeMetrics get keystrokeMetrics => _keystrokeMetrics;

  // ── Camera Polling ───────────────────────────────────────
  int _cameraCountdown = 28;
  int get cameraCountdown => _cameraCountdown;
  String _lastCapture = '12s ago';
  String get lastCapture => _lastCapture;
  double _cameraConfidence = 96.2;
  double get cameraConfidence => _cameraConfidence;

  // ── Security Events ──────────────────────────────────────
  final List<SecurityEvent> _events = [];
  List<SecurityEvent> get events => List.unmodifiable(_events);

  // ── Threats ──────────────────────────────────────────────
  final List<ThreatInfo> _threats = [
    ThreatInfo(
      label: 'Shadow Users',
      count: 3,
      trend: 'up',
      severity: ThreatSeverity.high,
    ),
    ThreatInfo(
      label: 'Proxy Tunnels',
      count: 1,
      trend: 'down',
      severity: ThreatSeverity.critical,
    ),
    ThreatInfo(
      label: 'Device Anomalies',
      count: 7,
      trend: 'up',
      severity: ThreatSeverity.medium,
    ),
    ThreatInfo(
      label: 'Auth Failures',
      count: 12,
      trend: 'stable',
      severity: ThreatSeverity.low,
    ),
  ];
  List<ThreatInfo> get threats => _threats;

  // ── Online Users ─────────────────────────────────────────
  final List<OnlineUser> _onlineUsers = const [
    OnlineUser(
      name: 'A. Sharma',
      trustScore: 94,
      status: UserVerificationStatus.verified,
      department: 'Engineering',
    ),
    OnlineUser(
      name: 'M. Chen',
      trustScore: 87,
      status: UserVerificationStatus.verified,
      department: 'Design',
    ),
    OnlineUser(
      name: 'J. Davis',
      trustScore: 62,
      status: UserVerificationStatus.monitoring,
      department: 'Marketing',
    ),
    OnlineUser(
      name: 'S. Kim',
      trustScore: 45,
      status: UserVerificationStatus.flagged,
      department: 'Sales',
    ),
    OnlineUser(
      name: 'R. Patel',
      trustScore: 91,
      status: UserVerificationStatus.verified,
      department: 'Engineering',
    ),
  ];
  List<OnlineUser> get onlineUsers => _onlineUsers;

  // ── Productivity Heatmap ─────────────────────────────────
  late List<List<ProductivitySlot>> _heatmapData;
  List<List<ProductivitySlot>> get heatmapData => _heatmapData;

  // ══════════════════════════════════════════════════════════
  // EMAIL FRAUD DETECTION
  // ══════════════════════════════════════════════════════════

  static const String userEmail = 'pruthvirajrajput353@gmail.com';

  final List<EmailThreat> _emailThreats = [];
  List<EmailThreat> get emailThreats => List.unmodifiable(_emailThreats);

  int _totalScanned = 247;
  int _threatsBlocked = 18;
  int _safeEmails = 221;
  int _quarantined = 8;
  int _pendingReview = 3;

  int get totalScanned => _totalScanned;
  int get threatsBlocked => _threatsBlocked;
  int get safeEmailsCount => _safeEmails;
  int get quarantinedCount => _quarantined;
  int get pendingReviewCount => _pendingReview;

  final Map<EmailThreatType, int> _threatBreakdown = {
    EmailThreatType.phishing: 7,
    EmailThreatType.malware: 3,
    EmailThreatType.spoofing: 4,
    EmailThreatType.spam: 9,
    EmailThreatType.suspicious: 2,
  };
  Map<EmailThreatType, int> get threatBreakdown =>
      Map.unmodifiable(_threatBreakdown);

  bool _emailScanActive = true;
  bool get emailScanActive => _emailScanActive;
  void toggleEmailScan() {
    _emailScanActive = !_emailScanActive;
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════
  // NEURAL CAMERA DETECTION (Real Face Verification)
  // ══════════════════════════════════════════════════════════

  final FaceVerificationService _faceService = FaceVerificationService.instance;

  /// Whether the real face verification system is active.
  bool _realCameraActive = false;
  bool get realCameraActive => _realCameraActive;

  /// Whether a reference face has been captured.
  bool get hasReferenceFace => _faceService.hasReference;
  String? get referenceFacePath => _faceService.referenceFacePath;

  /// Path to the last captured verification face image.
  String? _lastVerificationImagePath;
  String? get lastVerificationImagePath => _lastVerificationImagePath;

  /// Whether a verification is currently in progress.
  bool _isVerifying = false;
  bool get isVerifying => _isVerifying;

  /// Consecutive face mismatch counter.
  int _consecutiveMismatches = 0;
  int get consecutiveMismatches => _consecutiveMismatches;

  /// Total face alerts triggered this session.
  int _faceAlertCount = 0;
  int get faceAlertCount => _faceAlertCount;

  /// Email of the current logged-in user (set from AuthProvider).
  String _currentUserEmail = 'unknown';
  String get currentUserEmail => _currentUserEmail;
  set currentUserEmail(String email) => _currentUserEmail = email;

  FaceScanFrame _currentFrame = FaceScanFrame(
    confidence: 0,
    livenessScore: 0,
    matched: false,
    spoofingAttempt: false,
    timestamp: DateTime.now(),
    scanMode: 'STANDBY',
  );
  FaceScanFrame get currentFrame => _currentFrame;

  final List<CameraSessionLog> _cameraLogs = [];
  List<CameraSessionLog> get cameraLogs => List.unmodifiable(_cameraLogs);

  int _totalFramesAnalyzed = 0;
  int get totalFramesAnalyzed => _totalFramesAnalyzed;

  int _spoofingAttempts = 0;
  int get spoofingAttempts => _spoofingAttempts;

  double _avgConfidence = 0;
  double get avgConfidence => _avgConfidence;

  bool _neuralScanActive = false;
  bool get neuralScanActive => _neuralScanActive;

  void toggleNeuralScan() {
    _neuralScanActive = !_neuralScanActive;
    if (_neuralScanActive && hasReferenceFace) {
      startRealVerification();
    } else {
      stopRealVerification();
    }
    notifyListeners();
  }

  /// Capture the reference face (called after login).
  Future<String?> captureReferenceFace() async {
    _isVerifying = true;
    notifyListeners();

    final path = await _faceService.captureReferenceFace();
    _isVerifying = false;

    if (path != null) {
      _addCameraLog(
        confidence: 100,
        liveness: 100,
        matched: true,
        spoofing: false,
        detail:
            'Reference face captured — baseline enrolled for identity verification',
      );
      _currentFrame = FaceScanFrame(
        confidence: 100,
        livenessScore: 100,
        matched: true,
        spoofingAttempt: false,
        timestamp: DateTime.now(),
        scanMode: 'ENROLLED',
      );
    }

    notifyListeners();
    return path;
  }

  /// Load a previously captured reference face.
  Future<bool> loadReferenceFace() async {
    return await _faceService.loadExistingReference();
  }

  /// Run a single face verification check.
  /// Re-captures the reference face first, then verifies all future
  /// images against this new reference.
  Future<FaceVerificationResult?> runSingleVerification() async {
    _isVerifying = true;
    _currentFrame = FaceScanFrame(
      confidence: _currentFrame.confidence,
      livenessScore: _currentFrame.livenessScore,
      matched: _currentFrame.matched,
      spoofingAttempt: _currentFrame.spoofingAttempt,
      timestamp: DateTime.now(),
      scanMode: 'ENROLLING',
    );
    notifyListeners();

    // 1. Re-capture a fresh reference face
    final refPath = await _faceService.captureReferenceFace();
    if (refPath == null) {
      _isVerifying = false;
      _addCameraLog(
        confidence: 0,
        liveness: 0,
        matched: false,
        spoofing: false,
        detail: 'Reference face re-capture failed — camera unavailable',
      );
      notifyListeners();
      return null;
    }

    _addCameraLog(
      confidence: 100,
      liveness: 100,
      matched: true,
      spoofing: false,
      detail:
          'New reference face captured — all future verifications use this baseline',
    );
    _consecutiveMismatches = 0; // Reset mismatches for new reference
    _currentFrame = FaceScanFrame(
      confidence: 100,
      livenessScore: 100,
      matched: true,
      spoofingAttempt: false,
      timestamp: DateTime.now(),
      scanMode: 'ENROLLED',
    );
    notifyListeners();

    // 2. Immediately run a verification against the new reference
    _currentFrame = FaceScanFrame(
      confidence: 100,
      livenessScore: 100,
      matched: true,
      spoofingAttempt: false,
      timestamp: DateTime.now(),
      scanMode: 'SCANNING',
    );
    notifyListeners();

    final result = await _faceService.verify();
    _processVerificationResult(result);
    _isVerifying = false;

    // 3. Restart periodic verification with the new reference
    if (_neuralScanActive) {
      stopRealVerification();
      startRealVerification();
    }

    notifyListeners();
    return result;
  }

  /// Start periodic real face verification.
  void startRealVerification({int intervalSeconds = 30}) {
    if (_realCameraActive) return;
    _realCameraActive = true;
    _neuralScanActive = true;

    _faceService.onVerificationResult = _processVerificationResult;
    _faceService.startPeriodicVerification(intervalSeconds: intervalSeconds);
    notifyListeners();
  }

  /// Stop periodic verification.
  void stopRealVerification() {
    _realCameraActive = false;
    _faceService.stopPeriodicVerification();
    notifyListeners();
  }

  /// Process a verification result from the face service.
  void _processVerificationResult(FaceVerificationResult result) {
    _totalFramesAnalyzed++;
    _lastVerificationImagePath = result.capturedImagePath;

    if (result.isSpoofingAttempt) {
      _spoofingAttempts++;
    }

    // Track consecutive mismatches
    if (!result.matched) {
      _consecutiveMismatches++;
      if (_consecutiveMismatches >= 2) {
        _faceAlertCount++;
        _persistFaceAlert(result);
        debugPrint(
          '[NeuralCamera] ALERT: $_consecutiveMismatches consecutive face '
          'mismatches for $_currentUserEmail',
        );
      }
    } else {
      _consecutiveMismatches = 0;
    }

    // Update running average
    if (_avgConfidence == 0) {
      _avgConfidence = result.confidence;
    } else {
      _avgConfidence = _avgConfidence * 0.85 + result.confidence * 0.15;
    }

    _currentFrame = FaceScanFrame(
      confidence: result.confidence,
      livenessScore: result.livenessScore,
      matched: result.matched,
      spoofingAttempt: result.isSpoofingAttempt,
      timestamp: result.timestamp,
      scanMode: result.scanMode,
    );

    _addCameraLog(
      confidence: result.confidence,
      liveness: result.livenessScore,
      matched: result.matched,
      spoofing: result.isSpoofingAttempt,
      detail: result.statusDetail,
    );

    notifyListeners();
  }

  /// Persist a face mismatch alert to a shared JSON file so the admin
  /// dashboard can read it.
  Future<void> _persistFaceAlert(FaceVerificationResult result) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/sentinel_face_alerts.json');

      List<dynamic> alerts = [];
      if (file.existsSync()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          alerts = jsonDecode(content) as List<dynamic>;
        }
      }

      alerts.add({
        'userEmail': _currentUserEmail,
        'timestamp': DateTime.now().toIso8601String(),
        'consecutiveMismatches': _consecutiveMismatches,
        'confidence': result.confidence,
        'liveness': result.livenessScore,
        'capturedImagePath': result.capturedImagePath,
        'detail': result.statusDetail,
      });

      await file.writeAsString(jsonEncode(alerts));
    } catch (e) {
      debugPrint('[NeuralCamera] Failed to persist face alert: $e');
    }
  }

  /// Read all persisted face alerts (used by admin dashboard).
  static Future<List<Map<String, dynamic>>> loadFaceAlerts() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/sentinel_face_alerts.json');
      if (!file.existsSync()) return [];
      final content = await file.readAsString();
      if (content.isEmpty) return [];
      final list = jsonDecode(content) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[NeuralCamera] Failed to load face alerts: $e');
      return [];
    }
  }

  /// Get face alerts filtered by a specific user email.
  static Future<List<Map<String, dynamic>>> getFaceAlertsForUser(
    String email,
  ) async {
    final all = await loadFaceAlerts();
    return all.where((a) => a['userEmail'] == email).toList();
  }

  void _addCameraLog({
    required double confidence,
    required double liveness,
    required bool matched,
    required bool spoofing,
    required String detail,
  }) {
    _cameraLogs.insert(
      0,
      CameraSessionLog(
        id: 'CAM-${DateTime.now().millisecondsSinceEpoch}-${_rng.nextInt(9999)}',
        timestamp: DateTime.now(),
        confidence: confidence,
        livenessScore: liveness,
        matched: matched,
        spoofingAttempt: spoofing,
        detail: detail,
      ),
    );
    if (_cameraLogs.length > 50) _cameraLogs.removeLast();
  }

  // ── Timers ───────────────────────────────────────────────
  Timer? _trustTimer;
  Timer? _trustInterp;
  Timer? _keystrokeTimer;
  Timer? _cameraTimer;
  Timer? _eventTimer;
  Timer? _threatTimer;
  Timer? _heatmapTimer;
  Timer? _emailTimer;

  // ── API Integration Timer ───────────────────────────────
  Timer? _apiPollTimer;

  // ────────────────────────────────────────────────────────
  // Initialization
  // ────────────────────────────────────────────────────────

  SentinelProvider() {
    _initHeatmap();
    _generateInitialEvents();
    _generateInitialEmailThreats();
    _startSimulation();
    _initApiConnection();
  }

  /// Initialize API connection and start polling
  Future<void> _initApiConnection() async {
    _apiConnected = await _api.checkHealth();
    debugPrint('[SentinelProvider] API connected: $_apiConnected');

    // Start API polling timer (every 5 seconds)
    _apiPollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _pollApiForUpdates();
    });

    notifyListeners();
  }

  /// Poll API for real-time updates
  Future<void> _pollApiForUpdates() async {
    if (!_demoModeEnabled) return;

    // Check if scenario is active and apply it
    if (_activeScenario != null) {
      await _applyDemoScenario(_activeScenario!);
    } else {
      // Normal operation - poll for real data
      await _fetchTrustScoreFromApi();
    }
  }

  /// Fetch trust score from API using current component values
  Future<void> _fetchTrustScoreFromApi() async {
    final result = await _api.calculateTrustScore(
      faceConfidence: _faceConfidence,
      keystrokeMatch: _keystrokeMatch,
      activitySafety: _activitySafety,
    );

    if (result.success) {
      _targetTrust = result.trustScore;
      _trustRiskLevel = result.riskLevel;
    }
  }

  // ────────────────────────────────────────────────────────
  // Demo Mode Controls
  // ────────────────────────────────────────────────────────

  /// Toggle demo mode on/off
  void toggleDemoMode() {
    _demoModeEnabled = !_demoModeEnabled;
    if (!_demoModeEnabled) {
      _activeScenario = null;
    }
    notifyListeners();
  }

  /// Activate a specific demo scenario
  void activateScenario(DemoScenario scenario) {
    _activeScenario = scenario;
    _applyDemoScenario(scenario);

    // Add security event for the scenario
    _events.insert(
      0,
      SecurityEvent(
        id: '${DateTime.now().millisecondsSinceEpoch}-scenario',
        message: _getScenarioEventMessage(scenario),
        severity: _getScenarioSeverity(scenario),
        timestamp: DateTime.now(),
      ),
    );

    notifyListeners();
  }

  /// Deactivate current demo scenario
  void deactivateScenario() {
    _activeScenario = null;

    // Reset to normal values
    _faceConfidence = 92.0 + _rng.nextDouble() * 7;
    _keystrokeMatch = 85.0 + _rng.nextDouble() * 10;
    _activitySafety = 88.0 + _rng.nextDouble() * 10;
    _targetTrust =
        (_faceConfidence * 0.4) +
        (_keystrokeMatch * 0.4) +
        (_activitySafety * 0.2);
    _trustRiskLevel = 'LOW';

    _events.insert(
      0,
      SecurityEvent(
        id: '${DateTime.now().millisecondsSinceEpoch}-recovery',
        message: 'Demo scenario ended — normal operation resumed',
        severity: ThreatSeverity.low,
        timestamp: DateTime.now(),
      ),
    );

    notifyListeners();
  }

  /// Apply the effects of a demo scenario
  Future<void> _applyDemoScenario(DemoScenario scenario) async {
    switch (scenario) {
      case DemoScenario.identityMismatch:
        _faceConfidence = 25.0 + _rng.nextDouble() * 15;
        _keystrokeMatch = 30.0 + _rng.nextDouble() * 20;
        _activitySafety = 85.0;
        _currentFrame = FaceScanFrame(
          confidence: _faceConfidence,
          livenessScore: 88.0,
          matched: false,
          spoofingAttempt: false,
          timestamp: DateTime.now(),
          scanMode: 'ALERT',
        );
        break;

      case DemoScenario.spoofingAttempt:
        _faceConfidence = 15.0 + _rng.nextDouble() * 10;
        _keystrokeMatch = 80.0;
        _activitySafety = 40.0;
        _spoofingAttempts++;
        _currentFrame = FaceScanFrame(
          confidence: _faceConfidence,
          livenessScore: 12.0 + _rng.nextDouble() * 15,
          matched: false,
          spoofingAttempt: true,
          timestamp: DateTime.now(),
          scanMode: 'ANTI_SPOOF',
        );
        break;

      case DemoScenario.keystrokeAnomaly:
        _faceConfidence = 92.0;
        _keystrokeMatch = 20.0 + _rng.nextDouble() * 15;
        _activitySafety = 85.0;
        _keystrokeMetrics = KeystrokeMetrics(
          cadenceWpm: 45 + _rng.nextDouble() * 20,
          patternDrift: 0.65 + _rng.nextDouble() * 0.25,
          holdTimeMean: 150 + _rng.nextDouble() * 50,
          flightTimeMean: 200 + _rng.nextDouble() * 80,
          timestamp: DateTime.now(),
        );
        break;

      case DemoScenario.phishingDetected:
        _faceConfidence = 94.0;
        _keystrokeMatch = 88.0;
        _activitySafety = 15.0 + _rng.nextDouble() * 10;
        // Add phishing email threat
        _emailThreats.insert(0, _generateEmailThreat());
        _threatsBlocked++;
        break;

      case DemoScenario.burnoutRisk:
        _faceConfidence = 90.0;
        _keystrokeMatch = 75.0;
        _activitySafety = 70.0;
        // Update heatmap to show burnout pattern
        for (int h = 8; h < 13; h++) {
          _heatmapData[4][h] = ProductivitySlot(
            state: ProductivityState.burnoutRisk,
            intensity: 0.85,
            dayIndex: 4,
            hourIndex: h,
          );
        }
        break;

      case DemoScenario.normalOperation:
        _faceConfidence = 95.0 + _rng.nextDouble() * 4;
        _keystrokeMatch = 90.0 + _rng.nextDouble() * 8;
        _activitySafety = 92.0 + _rng.nextDouble() * 7;
        break;
    }

    // Compute trust score
    _targetTrust =
        (_faceConfidence * 0.4) +
        (_keystrokeMatch * 0.4) +
        (_activitySafety * 0.2);

    // Determine risk level
    if (_targetTrust >= 80) {
      _trustRiskLevel = 'LOW';
    } else if (_targetTrust >= 60) {
      _trustRiskLevel = 'MEDIUM';
    } else if (_targetTrust >= 40) {
      _trustRiskLevel = 'HIGH';
    } else {
      _trustRiskLevel = 'CRITICAL';
    }

    notifyListeners();
  }

  String _getScenarioEventMessage(DemoScenario scenario) {
    switch (scenario) {
      case DemoScenario.identityMismatch:
        return 'ALERT: Identity mismatch detected — face verification failed';
      case DemoScenario.spoofingAttempt:
        return 'CRITICAL: Spoofing attempt detected — photo/mask presentation';
      case DemoScenario.keystrokeAnomaly:
        return 'WARNING: Keystroke pattern anomaly — possible user switch';
      case DemoScenario.phishingDetected:
        return 'ALERT: Phishing URL detected in browser activity';
      case DemoScenario.burnoutRisk:
        return 'NOTICE: Elevated burnout risk — fatigue indicators detected';
      case DemoScenario.normalOperation:
        return 'INFO: System operating normally — all checks passed';
    }
  }

  ThreatSeverity _getScenarioSeverity(DemoScenario scenario) {
    switch (scenario) {
      case DemoScenario.identityMismatch:
      case DemoScenario.spoofingAttempt:
        return ThreatSeverity.critical;
      case DemoScenario.keystrokeAnomaly:
      case DemoScenario.phishingDetected:
        return ThreatSeverity.high;
      case DemoScenario.burnoutRisk:
        return ThreatSeverity.medium;
      case DemoScenario.normalOperation:
        return ThreatSeverity.low;
    }
  }

  /// Update face confidence (can be called from face verification)
  void updateFaceConfidence(
    double confidence, {
    bool matched = true,
    bool spoofing = false,
  }) {
    _faceConfidence = confidence;
    _cameraConfidence = confidence;
    _currentFrame = FaceScanFrame(
      confidence: confidence,
      livenessScore: spoofing ? 15.0 : 95.0,
      matched: matched,
      spoofingAttempt: spoofing,
      timestamp: DateTime.now(),
      scanMode: spoofing ? 'ANTI_SPOOF' : 'CONTINUOUS',
    );
    _recalculateTrustScore();
    notifyListeners();
  }

  /// Update keystroke match score
  void updateKeystrokeMatch(double matchScore) {
    _keystrokeMatch = matchScore;
    _recalculateTrustScore();
    notifyListeners();
  }

  /// Update activity safety score
  void updateActivitySafety(double safetyScore) {
    _activitySafety = safetyScore;
    _recalculateTrustScore();
    notifyListeners();
  }

  /// Recalculate trust score from components
  void _recalculateTrustScore() {
    _targetTrust =
        (_faceConfidence * 0.4) +
        (_keystrokeMatch * 0.4) +
        (_activitySafety * 0.2);
    _targetTrust = _targetTrust.clamp(0.0, 100.0);

    if (_targetTrust >= 80) {
      _trustRiskLevel = 'LOW';
    } else if (_targetTrust >= 60) {
      _trustRiskLevel = 'MEDIUM';
    } else if (_targetTrust >= 40) {
      _trustRiskLevel = 'HIGH';
    } else {
      _trustRiskLevel = 'CRITICAL';
    }
  }

  void _initHeatmap() {
    _heatmapData = List.generate(5, (day) {
      return List.generate(13, (hour) {
        ProductivityState state;
        if (hour < 1 || hour > 11) {
          state = ProductivityState.offline;
        } else {
          final r = _rng.nextDouble();
          if (r > 0.7) {
            state = ProductivityState.deepWork;
          } else if (r > 0.4) {
            state = ProductivityState.focused;
          } else if (r > 0.15) {
            state = ProductivityState.distracted;
          } else {
            state = ProductivityState.burnoutRisk;
          }
        }
        return ProductivitySlot(
          state: state,
          intensity: state == ProductivityState.offline
              ? 0.3
              : 0.5 + _rng.nextDouble() * 0.5,
          dayIndex: day,
          hourIndex: hour,
        );
      });
    });
  }

  // ────────────────────────────────────────────────────────
  // Event Templates
  // ────────────────────────────────────────────────────────

  static const List<Map<String, String>> _eventTemplates = [
    {'type': 'info', 'msg': 'Keystroke pattern validated — confidence {val}%'},
    {
      'type': 'success',
      'msg': 'User verified: Biometric face match ({val}% similarity)',
    },
    {
      'type': 'warning',
      'msg': 'Anomaly detected: Typing rhythm deviation ({val}%)',
    },
    {
      'type': 'info',
      'msg': 'Deep work session detected — {val} min continuous focus',
    },
    {'type': 'error', 'msg': 'ALERT: Unknown device fingerprint — IP {ip}'},
    {
      'type': 'success',
      'msg': 'Periodic neural scan passed — identity confirmed',
    },
    {
      'type': 'warning',
      'msg': 'Burnout risk elevated: fatigue index at {val}%',
    },
    {'type': 'info', 'msg': 'Keystroke cadence stable — avg latency {val}ms'},
    {'type': 'error', 'msg': 'CRITICAL: Proxy tunnel detected on port {val}'},
    {'type': 'success', 'msg': 'Camera polling: frame captured — no anomalies'},
    {
      'type': 'warning',
      'msg': 'Typing pattern shift: possible user switch ({val}% drift)',
    },
    {'type': 'info', 'msg': 'Session heartbeat — all sentinel modules nominal'},
    {'type': 'info', 'msg': 'Behavioral baseline updated — model v2.{val}'},
    {
      'type': 'error',
      'msg': 'ALERT: Multiple authentication failures from {ip}',
    },
    {'type': 'success', 'msg': 'Zero Trust check passed — device compliant'},
  ];

  static const List<String> _ips = [
    '192.168.1.42',
    '10.0.0.15',
    '172.16.0.88',
    '203.0.113.7',
    '198.51.100.12',
  ];

  SecurityEvent _generateEvent() {
    final template = _eventTemplates[_rng.nextInt(_eventTemplates.length)];
    final val = _rng.nextInt(60) + 40;
    final ip = _ips[_rng.nextInt(_ips.length)];
    final message = template['msg']!
        .replaceAll('{val}', val.toString())
        .replaceAll('{ip}', ip);

    ThreatSeverity severity;
    switch (template['type']) {
      case 'error':
        severity = ThreatSeverity.critical;
        break;
      case 'warning':
        severity = ThreatSeverity.high;
        break;
      case 'success':
        severity = ThreatSeverity.low;
        break;
      default:
        severity = ThreatSeverity.medium;
    }

    return SecurityEvent(
      id: '${DateTime.now().millisecondsSinceEpoch}-${_rng.nextInt(9999)}',
      message: message,
      severity: severity,
      timestamp: DateTime.now(),
    );
  }

  void _generateInitialEvents() {
    for (int i = 0; i < 10; i++) {
      _events.add(_generateEvent());
    }
  }

  // ────────────────────────────────────────────────────────
  // Email Fraud Simulation Data
  // ────────────────────────────────────────────────────────

  static const List<Map<String, dynamic>> _emailThreatTemplates = [
    {
      'sender': 'security-alert@paypa1.com',
      'domain': 'paypa1.com',
      'subject': 'Urgent: Your account has been compromised',
      'type': 'phishing',
      'detail':
          'Sender domain typosquats paypal.com. Contains credential harvesting link.',
      'indicators': ['Domain spoofing', 'Urgency language', 'Suspicious link'],
    },
    {
      'sender': 'noreply@amaz0n-security.net',
      'domain': 'amaz0n-security.net',
      'subject': 'Order #3847291 - Payment declined, action required',
      'type': 'phishing',
      'detail': 'Fake order notification. Links redirect to phishing page.',
      'indicators': [
        'Fake domain',
        'Social engineering',
        'Credential harvesting',
      ],
    },
    {
      'sender': 'admin@company-docs.ru',
      'domain': 'company-docs.ru',
      'subject': 'Shared document: Q4_Financial_Report.xlsx',
      'type': 'malware',
      'detail': 'Attachment contains macro-enabled malware (Trojan.GenericKD).',
      'indicators': ['Malicious attachment', 'Macro payload', 'Unknown sender'],
    },
    {
      'sender': 'pruthviraj.rajput@g00gle.com',
      'domain': 'g00gle.com',
      'subject': 'Re: Meeting notes from yesterday',
      'type': 'spoofing',
      'detail': 'Sender impersonating user identity. SPF/DKIM check failed.',
      'indicators': ['Identity spoofing', 'SPF fail', 'DKIM mismatch'],
    },
    {
      'sender': 'winner@mega-lottery-intl.com',
      'domain': 'mega-lottery-intl.com',
      'subject': 'Congratulations! You have won ₹50,00,000',
      'type': 'spam',
      'detail': 'Advance fee fraud. Requests personal banking details.',
      'indicators': ['Scam pattern', 'Financial bait', 'Unknown origin'],
    },
    {
      'sender': 'support@microsoft-verify.xyz',
      'domain': 'microsoft-verify.xyz',
      'subject': 'Your Microsoft 365 subscription expires today',
      'type': 'phishing',
      'detail': 'Fake subscription renewal page. Harvests credit card data.',
      'indicators': [
        'Brand impersonation',
        'Urgency tactics',
        'Card harvesting',
      ],
    },
    {
      'sender': 'hr@trusted-careers.info',
      'domain': 'trusted-careers.info',
      'subject': 'Job Offer: Senior Developer - ₹45 LPA (Remote)',
      'type': 'spam',
      'detail': 'Fake job offer. Collects personal data for identity theft.',
      'indicators': [
        'Too-good-to-be-true',
        'Data harvesting',
        'No company verification',
      ],
    },
    {
      'sender': 'invoice@quickbooks-billing.net',
      'domain': 'quickbooks-billing.net',
      'subject': 'Invoice #INV-2947 attached - Payment overdue',
      'type': 'malware',
      'detail':
          'PDF attachment exploits CVE-2024-XXXX. Contains ransomware dropper.',
      'indicators': ['Exploit payload', 'Ransomware dropper', 'Fake invoice'],
    },
    {
      'sender': 'notifications@instagram-verify.com',
      'domain': 'instagram-verify.com',
      'subject': 'Someone tried to log into your Instagram',
      'type': 'phishing',
      'detail': 'Fake login alert. Redirects to credential phishing page.',
      'indicators': [
        'Social media impersonation',
        'Login phishing',
        'Fake alert',
      ],
    },
    {
      'sender': 'delivery@fedex-tracking.biz',
      'domain': 'fedex-tracking.biz',
      'subject': 'Your package delivery failed - reschedule now',
      'type': 'suspicious',
      'detail': 'Suspicious link to unknown tracking portal. Under analysis.',
      'indicators': [
        'Brand impersonation',
        'Suspicious redirect',
        'Under review',
      ],
    },
    {
      'sender': 'contact@tech-update-center.org',
      'domain': 'tech-update-center.org',
      'subject': 'Critical Chrome update required immediately',
      'type': 'malware',
      'detail': 'Links to malicious .exe disguised as browser update.',
      'indicators': ['Fake update', 'Malware download', 'Social engineering'],
    },
    {
      'sender': 'rewards@flipkart-offers.co',
      'domain': 'flipkart-offers.co',
      'subject': 'Exclusive: ₹5000 reward for loyal customers',
      'type': 'phishing',
      'detail': 'Phishing campaign targeting Indian e-commerce users.',
      'indicators': ['Reward scam', 'Data harvesting', 'Fake domain'],
    },
  ];

  EmailThreat _generateEmailThreat() {
    final template =
        _emailThreatTemplates[_rng.nextInt(_emailThreatTemplates.length)];

    EmailThreatType type;
    switch (template['type']) {
      case 'phishing':
        type = EmailThreatType.phishing;
        break;
      case 'malware':
        type = EmailThreatType.malware;
        break;
      case 'spoofing':
        type = EmailThreatType.spoofing;
        break;
      case 'spam':
        type = EmailThreatType.spam;
        break;
      default:
        type = EmailThreatType.suspicious;
    }

    final riskScore = 0.55 + _rng.nextDouble() * 0.44;

    EmailThreatStatus status;
    if (riskScore > 0.85) {
      status = EmailThreatStatus.blocked;
    } else if (riskScore > 0.7) {
      status = EmailThreatStatus.quarantined;
    } else {
      status = EmailThreatStatus.flagged;
    }

    return EmailThreat(
      id: 'EM-${DateTime.now().millisecondsSinceEpoch}-${_rng.nextInt(9999)}',
      sender: template['sender'] as String,
      senderDomain: template['domain'] as String,
      subject: template['subject'] as String,
      recipient: userEmail,
      threatType: type,
      status: status,
      riskScore: riskScore,
      timestamp: DateTime.now(),
      analysisDetail: template['detail'] as String,
      indicators: List<String>.from(template['indicators'] as List),
    );
  }

  void _generateInitialEmailThreats() {
    for (int i = 0; i < 8; i++) {
      _emailThreats.add(_generateEmailThreat());
    }
  }

  // ────────────────────────────────────────────────────────
  // Neural Camera Simulation Data
  // ────────────────────────────────────────────────────────

  // ────────────────────────────────────────────────────────
  // Simulation Engine
  // ────────────────────────────────────────────────────────

  void _startSimulation() {
    // Trust score drift
    _trustTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final delta = (_rng.nextDouble() - 0.4) * 8;
      _targetTrust = (_targetTrust + delta).clamp(35.0, 99.0);
    });

    // Smooth trust interpolation
    _trustInterp = Timer.periodic(const Duration(milliseconds: 50), (_) {
      final diff = _targetTrust - _trustScore;
      if (diff.abs() < 0.3) {
        _trustScore = _targetTrust;
      } else {
        _trustScore += diff * 0.06;
      }
      notifyListeners();
    });

    // Keystroke metrics update
    _keystrokeTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _keystrokeMetrics = KeystrokeMetrics(
        cadenceWpm: 120 + _rng.nextDouble() * 40,
        patternDrift: _rng.nextDouble() * 0.08,
        holdTimeMean: 70 + _rng.nextDouble() * 30,
        flightTimeMean: 90 + _rng.nextDouble() * 40,
        timestamp: DateTime.now(),
      );
      notifyListeners();
    });

    // Camera countdown
    _cameraTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _cameraCountdown--;
      if (_cameraCountdown <= 0) {
        _cameraState = SentinelModuleState.capturing;
        _lastCapture = 'just now';
        _cameraConfidence = 90 + _rng.nextDouble() * 9.5;
        notifyListeners();
        Future.delayed(const Duration(milliseconds: 1200), () {
          _cameraState = SentinelModuleState.active;
          _cameraCountdown = 30;
          notifyListeners();
        });
      } else {
        notifyListeners();
      }
    });

    // Event stream
    _eventTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      _events.insert(0, _generateEvent());
      if (_events.length > 50) _events.removeLast();
      notifyListeners();
    });

    // Threat counts
    _threatTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      for (var t in _threats) {
        t.count = max(0, t.count + _rng.nextInt(3) - 1);
      }
      notifyListeners();
    });

    // Heatmap micro-updates
    _heatmapTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      final day = _rng.nextInt(5);
      final hour = _rng.nextInt(11) + 1;
      final r = _rng.nextDouble();
      ProductivityState state;
      if (r > 0.7) {
        state = ProductivityState.deepWork;
      } else if (r > 0.4) {
        state = ProductivityState.focused;
      } else if (r > 0.15) {
        state = ProductivityState.distracted;
      } else {
        state = ProductivityState.burnoutRisk;
      }
      _heatmapData[day][hour] = ProductivitySlot(
        state: state,
        intensity: 0.5 + _rng.nextDouble() * 0.5,
        dayIndex: day,
        hourIndex: hour,
      );
      notifyListeners();
    });

    // ── Email Fraud Simulation ──────────────────────────────
    _emailTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_emailScanActive) return;

      // Increment scanned
      _totalScanned += 1;

      // 30% chance of a threat email
      if (_rng.nextDouble() < 0.30) {
        final threat = _generateEmailThreat();
        _emailThreats.insert(0, threat);
        if (_emailThreats.length > 30) _emailThreats.removeLast();

        _threatsBlocked++;
        _threatBreakdown[threat.threatType] =
            (_threatBreakdown[threat.threatType] ?? 0) + 1;

        if (threat.status == EmailThreatStatus.quarantined) {
          _quarantined++;
        }
        if (threat.status == EmailThreatStatus.flagged) {
          _pendingReview++;
        }
      } else {
        _safeEmails++;
      }
      notifyListeners();
    });

    // ── Neural Camera ──────────────────────────────────────
    // Real face verification is started separately via
    // startRealVerification() after reference face capture.
    // No simulation timers — the camera system is real.
  }

  // ────────────────────────────────────────────────────────
  // Computed Stats
  // ────────────────────────────────────────────────────────

  int get totalThreats => _threats.fold<int>(0, (sum, t) => sum + t.count);

  Map<String, int> get productivityStats {
    int dw = 0, f = 0, d = 0, b = 0, total = 0;
    for (final row in _heatmapData) {
      for (final slot in row) {
        if (slot.state == ProductivityState.offline) continue;
        total++;
        switch (slot.state) {
          case ProductivityState.deepWork:
            dw++;
            break;
          case ProductivityState.focused:
            f++;
            break;
          case ProductivityState.distracted:
            d++;
            break;
          case ProductivityState.burnoutRisk:
            b++;
            break;
          default:
            break;
        }
      }
    }
    if (total == 0) total = 1;
    return {
      'deepWork': ((dw / total) * 100).round(),
      'focused': ((f / total) * 100).round(),
      'distracted': ((d / total) * 100).round(),
      'burnout': ((b / total) * 100).round(),
    };
  }

  // ────────────────────────────────────────────────────────
  // Cleanup
  // ────────────────────────────────────────────────────────

  @override
  void dispose() {
    _trustTimer?.cancel();
    _trustInterp?.cancel();
    _keystrokeTimer?.cancel();
    _cameraTimer?.cancel();
    _eventTimer?.cancel();
    _threatTimer?.cancel();
    _heatmapTimer?.cancel();
    _emailTimer?.cancel();
    _faceService.dispose();
    _apiPollTimer?.cancel();
    _api.dispose();
    super.dispose();
  }
}

/// Demo scenarios for hackathon demonstration
enum DemoScenario {
  /// Face verification fails — unknown person
  identityMismatch,

  /// Photo/mask detected instead of real face
  spoofingAttempt,

  /// Typing pattern doesn't match enrolled user
  keystrokeAnomaly,

  /// Phishing URL detected in browser activity
  phishingDetected,

  /// Extended work hours, stress indicators
  burnoutRisk,

  /// Everything normal (reset scenario)
  normalOperation,
}
