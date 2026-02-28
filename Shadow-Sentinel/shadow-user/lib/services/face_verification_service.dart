import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'screen_capture_service.dart';

/// Result of a single face verification check.
class FaceVerificationResult {
  final bool matched;
  final double confidence;
  final double livenessScore;
  final int facesDetectedRef;
  final int facesDetectedCur;
  final String? error;
  final DateTime timestamp;
  final String? capturedImagePath;

  const FaceVerificationResult({
    required this.matched,
    required this.confidence,
    required this.livenessScore,
    required this.facesDetectedRef,
    required this.facesDetectedCur,
    this.error,
    required this.timestamp,
    this.capturedImagePath,
  });

  bool get hasFace => facesDetectedCur > 0;
  bool get isSpoofingAttempt => !matched && hasFace && confidence < 40;

  String get scanMode {
    if (error != null) return 'ERROR';
    if (!hasFace) return 'NO_FACE';
    if (isSpoofingAttempt) return 'ANTI_SPOOF';
    if (matched) return 'IDENTITY_VERIFY';
    return 'LIVENESS_CHECK';
  }

  String get statusDetail {
    if (error != null) return 'Error: $error';
    if (!hasFace) return 'No face detected in camera frame';
    if (isSpoofingAttempt) {
      return 'ALERT: Possible identity mismatch — confidence ${confidence.toStringAsFixed(1)}%';
    }
    if (matched) {
      return 'Face match confirmed — identity verified at ${confidence.toStringAsFixed(1)}% confidence';
    }
    return 'Face detected but match inconclusive — ${confidence.toStringAsFixed(1)}% confidence';
  }
}

/// Service that handles real face verification using the webcam.
///
/// Captures a reference face at login, then periodically captures
/// new frames and compares them against the reference using
/// OpenCV-based face detection and comparison.
class FaceVerificationService {
  FaceVerificationService._();
  static final FaceVerificationService instance = FaceVerificationService._();

  String? _referenceFacePath;
  String? get referenceFacePath => _referenceFacePath;
  bool get hasReference =>
      _referenceFacePath != null && File(_referenceFacePath!).existsSync();

  Timer? _verificationTimer;
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  /// Callback for verification results.
  void Function(FaceVerificationResult)? onVerificationResult;

  /// Capture the reference face photo for the current user.
  /// Returns the file path if successful, null otherwise.
  Future<String?> captureReferenceFace() async {
    try {
      debugPrint('[FaceVerification] Capturing reference face...');
      final path = await ScreenCaptureService.captureFromCamera();

      if (path != null && File(path).existsSync()) {
        // Save as the reference
        final dir = await getApplicationDocumentsDirectory();
        final refPath = p.join(dir.path, 'sentinel_reference_face.jpg');

        // Copy to reference path
        await File(path).copy(refPath);
        _referenceFacePath = refPath;

        debugPrint('[FaceVerification] Reference face saved: $refPath');
        return refPath;
      }

      debugPrint('[FaceVerification] Failed to capture reference face');
      return null;
    } catch (e) {
      debugPrint('[FaceVerification] Error capturing reference: $e');
      return null;
    }
  }

  /// Load existing reference face from disk (if previously captured).
  Future<bool> loadExistingReference() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final refPath = p.join(dir.path, 'sentinel_reference_face.jpg');
      if (File(refPath).existsSync()) {
        _referenceFacePath = refPath;
        debugPrint('[FaceVerification] Loaded existing reference: $refPath');
        return true;
      }
    } catch (e) {
      debugPrint('[FaceVerification] Error loading reference: $e');
    }
    return false;
  }

  /// Run a single face verification against the reference.
  Future<FaceVerificationResult> verify() async {
    if (!hasReference) {
      return FaceVerificationResult(
        matched: false,
        confidence: 0,
        livenessScore: 0,
        facesDetectedRef: 0,
        facesDetectedCur: 0,
        error: 'No reference face captured',
        timestamp: DateTime.now(),
      );
    }

    try {
      // Capture current face
      final currentPath = await ScreenCaptureService.captureFromCamera();
      if (currentPath == null) {
        return FaceVerificationResult(
          matched: false,
          confidence: 0,
          livenessScore: 0,
          facesDetectedRef: 1,
          facesDetectedCur: 0,
          error: 'Camera capture failed',
          timestamp: DateTime.now(),
        );
      }

      // Run Python face comparison
      final result = await _runFaceComparison(_referenceFacePath!, currentPath);
      return FaceVerificationResult(
        matched: result['match'] as bool? ?? false,
        confidence: (result['confidence'] as num?)?.toDouble() ?? 0,
        livenessScore: (result['liveness'] as num?)?.toDouble() ?? 0,
        facesDetectedRef: result['faces_detected_ref'] as int? ?? 0,
        facesDetectedCur: result['faces_detected_cur'] as int? ?? 0,
        error: result['error'] as String?,
        timestamp: DateTime.now(),
        capturedImagePath: currentPath,
      );
    } catch (e) {
      debugPrint('[FaceVerification] Verification error: $e');
      return FaceVerificationResult(
        matched: false,
        confidence: 0,
        livenessScore: 0,
        facesDetectedRef: 0,
        facesDetectedCur: 0,
        error: 'Verification error: $e',
        timestamp: DateTime.now(),
      );
    }
  }

  /// Start periodic face verification.
  /// [intervalSeconds] — how often to check (default: 30 seconds).
  void startPeriodicVerification({int intervalSeconds = 30}) {
    if (_isRunning) return;
    _isRunning = true;

    debugPrint(
      '[FaceVerification] Starting periodic verification (every ${intervalSeconds}s)',
    );

    // Run first check immediately
    _runVerification();

    _verificationTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) => _runVerification(),
    );
  }

  /// Stop periodic verification.
  void stopPeriodicVerification() {
    _isRunning = false;
    _verificationTimer?.cancel();
    _verificationTimer = null;
    debugPrint('[FaceVerification] Stopped periodic verification');
  }

  Future<void> _runVerification() async {
    if (!hasReference) return;
    final result = await verify();
    onVerificationResult?.call(result);
  }

  /// Run the Python face comparison script.
  Future<Map<String, dynamic>> _runFaceComparison(
    String referencePath,
    String currentPath,
  ) async {
    try {
      final scriptPath = await _getFaceCompareScriptPath();
      if (scriptPath == null) {
        return {
          'match': false,
          'confidence': 0.0,
          'liveness': 0.0,
          'faces_detected_ref': 0,
          'faces_detected_cur': 0,
          'error': 'face_compare.py not found',
        };
      }

      debugPrint('[FaceVerification] Running comparison: $scriptPath');
      final pythonExe = await _findPythonExe();
      final result = await Process.run(pythonExe, [
        scriptPath,
        referencePath,
        currentPath,
      ], runInShell: true);

      debugPrint('[FaceVerification] Python exit: ${result.exitCode}');
      if (result.stdout.toString().trim().isNotEmpty) {
        debugPrint('[FaceVerification] stdout: ${result.stdout}');
      }
      if (result.stderr.toString().trim().isNotEmpty) {
        debugPrint('[FaceVerification] stderr: ${result.stderr}');
      }

      final stdout = result.stdout.toString().trim();
      if (stdout.isNotEmpty) {
        try {
          return jsonDecode(stdout) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('[FaceVerification] Failed to parse JSON: $e');
        }
      }

      return {
        'match': false,
        'confidence': 0.0,
        'liveness': 0.0,
        'faces_detected_ref': 0,
        'faces_detected_cur': 0,
        'error': 'Failed to parse comparison result',
      };
    } catch (e) {
      return {
        'match': false,
        'confidence': 0.0,
        'liveness': 0.0,
        'faces_detected_ref': 0,
        'faces_detected_cur': 0,
        'error': 'Comparison error: $e',
      };
    }
  }

  /// Locate the face_compare.py script.
  static Future<String?> _getFaceCompareScriptPath() async {
    // 1. Next to executable
    final exe = Platform.resolvedExecutable;
    final exeDir = p.dirname(exe);
    final c1 = p.join(exeDir, 'face_compare.py');
    if (File(c1).existsSync()) return c1;

    // 2. In scripts/ folder relative to project root
    try {
      var dir = Directory(exeDir);
      for (var i = 0; i < 6; i++) {
        final c2 = p.join(dir.path, 'scripts', 'face_compare.py');
        if (File(c2).existsSync()) return c2;
        final parent = dir.parent;
        if (parent.path == dir.path) break;
        dir = parent;
      }
    } catch (_) {}

    debugPrint('[FaceVerification] face_compare.py not found');
    return null;
  }

  /// Returns a Python executable, preferring the project .venv.
  static Future<String> _findPythonExe() async {
    final venvCandidates = <String>[
      p.join(Directory.current.path, '.venv', 'Scripts', 'python.exe'),
      p.join(Directory.current.path, '.venv', 'bin', 'python'),
    ];
    for (final venv in venvCandidates) {
      if (File(venv).existsSync()) {
        debugPrint('[FaceVerification] Using venv Python: $venv');
        return venv;
      }
    }
    return 'python';
  }

  /// Clean up resources.
  void dispose() {
    stopPeriodicVerification();
  }
}
