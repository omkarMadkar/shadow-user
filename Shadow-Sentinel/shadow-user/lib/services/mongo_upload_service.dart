import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Service that uploads detection events to MongoDB Atlas using a Python script.
///
/// Calls [mongo_upload.py] via [Process.run] — fire-and-forget, never blocks
/// the alert pipeline. Returns the MongoDB document ID on success or null.
class MongoUploadService {
  MongoUploadService._();
  static final MongoUploadService instance = MongoUploadService._();

  // ── Python / Script discovery ──────────────────────────────

  static Future<String?> _getScriptPath(String filename) async {
    final exe = Platform.resolvedExecutable;
    final exeDir = p.dirname(exe);

    // 1. Next to the exe (release build)
    final c1 = p.join(exeDir, filename);
    if (File(c1).existsSync()) return c1;

    // 2. Walk up looking for scripts/<filename>
    try {
      var dir = Directory(exeDir);
      for (var i = 0; i < 7; i++) {
        final c2 = p.join(dir.path, 'scripts', filename);
        if (File(c2).existsSync()) return c2;
        final parent = dir.parent;
        if (parent.path == dir.path) break;
        dir = parent;
      }
    } catch (_) {}

    debugPrint('[MongoUpload] $filename not found');
    return null;
  }

  static Future<String> _findPythonExe() async {
    final venvCandidates = <String>[
      p.join(Directory.current.path, '.venv', 'Scripts', 'python.exe'),
      p.join(Directory.current.path, '.venv', 'bin', 'python'),
      p.join(
        Directory.current.path,
        'backend',
        'venv',
        'Scripts',
        'python.exe',
      ),
      p.join(Directory.current.path, 'backend', 'venv', 'bin', 'python'),
    ];
    for (final venv in venvCandidates) {
      if (File(venv).existsSync()) return venv;
    }
    return 'python';
  }

  // ── Core runner ────────────────────────────────────────────

  Future<String?> _runUpload(List<String> args) async {
    try {
      final scriptPath = await _getScriptPath('mongo_upload.py');
      if (scriptPath == null) {
        debugPrint('[MongoUpload] mongo_upload.py not found');
        return null;
      }
      final python = await _findPythonExe();
      debugPrint('[MongoUpload] Running upload: ${args.take(4).join(" ")}...');

      final result = await Process.run(python, [
        scriptPath,
        ...args,
      ], runInShell: true);

      if (result.stderr.toString().trim().isNotEmpty) {
        debugPrint('[MongoUpload] stderr: ${result.stderr}');
      }

      final stdout = result.stdout.toString().trim();
      if (stdout.isNotEmpty) {
        try {
          final json = jsonDecode(stdout) as Map<String, dynamic>;
          if (json['ok'] == true) {
            final id = json['id'] as String?;
            debugPrint('[MongoUpload] ✅ Uploaded — doc id: $id');
            return id;
          } else {
            debugPrint('[MongoUpload] ❌ Upload failed: ${json['error']}');
          }
        } catch (e) {
          debugPrint('[MongoUpload] JSON parse error: $e  stdout: $stdout');
        }
      }
    } catch (e) {
      debugPrint('[MongoUpload] Exception: $e');
    }
    return null;
  }

  // ── Public API ─────────────────────────────────────────────

  /// Upload a keystroke / voice detection alert to MongoDB Atlas.
  ///
  /// Fire-and-forget — call without awaiting if you don't need the doc ID.
  Future<String?> uploadKeystrokeAlert({
    required String userEmail,
    required String alertType,
    required String severity,
    required List<String> flaggedWords,
    required String transcript,
    String? screenshotPath,
    String? facePhotoPath,
    bool? faceVerified,
    double? faceConfidence,
  }) async {
    return _runUpload([
      '--event_type',
      'keystroke_alert',
      '--user_email',
      userEmail,
      '--alert_type',
      alertType,
      '--severity',
      severity,
      '--flagged_words',
      flaggedWords.join(','),
      '--transcript',
      transcript,
      '--screenshot_path',
      screenshotPath ?? '',
      '--face_path',
      facePhotoPath ?? '',
      '--verified',
      faceVerified == null ? 'unknown' : (faceVerified ? 'true' : 'false'),
      '--confidence',
      (faceConfidence ?? 0.0).toStringAsFixed(2),
    ]);
  }

  /// Upload a face mismatch alert (from Neural Camera) to MongoDB Atlas.
  Future<String?> uploadFaceAlert({
    required String userEmail,
    required double confidence,
    required int consecutiveMismatches,
    String? facePhotoPath,
  }) async {
    return _runUpload([
      '--event_type',
      'face_alert',
      '--user_email',
      userEmail,
      '--alert_type',
      'face_mismatch',
      '--severity',
      consecutiveMismatches >= 3 ? 'severe' : 'moderate',
      '--confidence',
      confidence.toStringAsFixed(2),
      '--consecutive_mismatches',
      consecutiveMismatches.toString(),
      '--face_path',
      facePhotoPath ?? '',
    ]);
  }

  // ── Query helper ───────────────────────────────────────────

  /// Fetch all detection events for [userEmail] from MongoDB Atlas.
  /// Returns a list of event maps or empty list on failure.
  Future<List<Map<String, dynamic>>> fetchEventsForUser(
    String userEmail, {
    int limit = 100,
  }) async {
    try {
      final scriptPath = await _getScriptPath('mongo_query.py');
      if (scriptPath == null) return [];

      final python = await _findPythonExe();
      final result = await Process.run(python, [
        scriptPath,
        '--user_email',
        userEmail,
        '--limit',
        limit.toString(),
      ], runInShell: true);

      if (result.stderr.toString().trim().isNotEmpty) {
        debugPrint('[MongoQuery] stderr: ${result.stderr}');
      }

      final stdout = result.stdout.toString().trim();
      if (stdout.isEmpty) return [];

      final decoded = jsonDecode(stdout);

      // Error object from script
      if (decoded is Map && decoded.containsKey('error')) {
        debugPrint('[MongoQuery] Error from script: ${decoded['error']}');
        return [];
      }

      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('[MongoQuery] Exception: $e');
    }
    return [];
  }
}
