import 'dart:io';
import 'dart:typed_data';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'voice_database.g.dart';

// ─── Tables ──────────────────────────────────────────────────

/// Registered / monitored users.
class MonitoredUsers extends Table {
  TextColumn get uid => text()();
  TextColumn get displayName => text()();
  TextColumn get email => text()();
  TextColumn get photoUrl => text().nullable()();
  TextColumn get role => text().withDefault(const Constant('viewer'))();
  DateTimeColumn get firstSeen => dateTime()();
  DateTimeColumn get lastLogin => dateTime()();

  @override
  Set<Column> get primaryKey => {uid};
}

/// Voice recording sessions.
class VoiceSessions extends Table {
  TextColumn get id => text()();
  TextColumn get userEmail => text().withDefault(const Constant('unknown'))();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('recording'))();
  IntColumn get totalChunks => integer().withDefault(const Constant(0))();
  IntColumn get alertCount => integer().withDefault(const Constant(0))();
  RealColumn get avgVolume => real().withDefault(const Constant(0.0))();
  IntColumn get totalDurationMs => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Individual audio chunks within a session.
class VoiceChunks extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(VoiceSessions, #id)();
  TextColumn get filePath => text()();
  BlobColumn get audioData => blob().nullable()();
  IntColumn get durationMs => integer()();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get volumeDb => real()();
  TextColumn get transcript => text().nullable()();
  TextColumn get severity => text().withDefault(const Constant('clean'))();
  TextColumn get flaggedWords => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Language violation alerts.
class VoiceAlerts extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(VoiceSessions, #id)();
  TextColumn get chunkId => text().references(VoiceChunks, #id)();
  TextColumn get alertType => text()();
  TextColumn get severity => text()();
  TextColumn get flaggedPhrase => text()();
  TextColumn get context => text()();
  RealColumn get confidenceScore => real()();
  DateTimeColumn get timestamp => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Database ────────────────────────────────────────────────

@DriftDatabase(
  tables: [MonitoredUsers, VoiceSessions, VoiceChunks, VoiceAlerts],
)
class VoiceDatabase extends _$VoiceDatabase {
  /// Singleton instance.
  static VoiceDatabase? _instance;

  factory VoiceDatabase() {
    return _instance ??= VoiceDatabase._internal(_openConnection());
  }

  VoiceDatabase._internal(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(voiceChunks, voiceChunks.audioData);
      }
      if (from < 3) {
        await migrator.createTable(monitoredUsers);
        await migrator.addColumn(voiceSessions, voiceSessions.userEmail);
      }
    },
  );

  // ── Session Operations ───────────────────────────────────

  Future<void> insertSession(VoiceSessionsCompanion session) =>
      into(voiceSessions).insert(session);

  Future<void> updateSession(String id, VoiceSessionsCompanion session) =>
      (update(voiceSessions)..where((t) => t.id.equals(id))).write(session);

  Future<List<VoiceSession>> getAllSessions() => (select(
    voiceSessions,
  )..orderBy([(t) => OrderingTerm.desc(t.startTime)])).get();

  Future<VoiceSession?> getActiveSession() => (select(
    voiceSessions,
  )..where((t) => t.status.equals('recording'))).getSingleOrNull();

  // ── Chunk Operations ─────────────────────────────────────

  Future<void> insertChunk(VoiceChunksCompanion chunk) =>
      into(voiceChunks).insert(chunk);

  Future<List<VoiceChunk>> getChunksForSession(String sessionId) =>
      (select(voiceChunks)
            ..where((t) => t.sessionId.equals(sessionId))
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
          .get();

  Future<void> updateChunkTranscript(String id, String transcript) =>
      (update(voiceChunks)..where((t) => t.id.equals(id))).write(
        VoiceChunksCompanion(transcript: Value(transcript)),
      );

  /// Store audio bytes (WAV data) for a chunk in the database.
  Future<void> updateChunkAudioData(String id, Uint8List audioBytes) =>
      (update(voiceChunks)..where((t) => t.id.equals(id))).write(
        VoiceChunksCompanion(audioData: Value(audioBytes)),
      );

  /// Retrieve audio bytes for a chunk from the database.
  Future<Uint8List?> getChunkAudioData(String id) async {
    final chunk = await (select(
      voiceChunks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return chunk?.audioData;
  }

  Future<int> getChunkCount() async {
    final count = voiceChunks.id.count();
    final query = selectOnly(voiceChunks)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // ── Alert Operations ─────────────────────────────────────

  Future<void> insertAlert(VoiceAlertsCompanion alert) =>
      into(voiceAlerts).insert(alert);

  Future<List<VoiceAlert>> getAllAlerts() => (select(
    voiceAlerts,
  )..orderBy([(t) => OrderingTerm.desc(t.timestamp)])).get();

  Future<List<VoiceAlert>> getAlertsForSession(String sessionId) =>
      (select(voiceAlerts)
            ..where((t) => t.sessionId.equals(sessionId))
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
          .get();

  Future<int> getAlertCount() async {
    final count = voiceAlerts.id.count();
    final query = selectOnly(voiceAlerts)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  Future<Map<String, int>> getAlertBreakdown() async {
    final alerts = await getAllAlerts();
    final breakdown = <String, int>{};
    for (final alert in alerts) {
      breakdown[alert.alertType] = (breakdown[alert.alertType] ?? 0) + 1;
    }
    return breakdown;
  }

  // ── Monitored Users Operations ────────────────────────────

  /// Upsert a monitored user (insert or update on conflict).
  Future<void> upsertMonitoredUser(MonitoredUsersCompanion user) async {
    await into(monitoredUsers).insertOnConflictUpdate(user);
  }

  /// Get all monitored users ordered by last login.
  Future<List<MonitoredUser>> getAllMonitoredUsers() => (select(
    monitoredUsers,
  )..orderBy([(t) => OrderingTerm.desc(t.lastLogin)])).get();

  /// Get a single monitored user by uid.
  Future<MonitoredUser?> getMonitoredUserByUid(String uid) => (select(
    monitoredUsers,
  )..where((t) => t.uid.equals(uid))).getSingleOrNull();

  /// Get a single monitored user by email.
  Future<MonitoredUser?> getMonitoredUserByEmail(String email) => (select(
    monitoredUsers,
  )..where((t) => t.email.equals(email))).getSingleOrNull();

  /// Count of monitored users.
  Future<int> getMonitoredUserCount() async {
    final count = monitoredUsers.uid.count();
    final query = selectOnly(monitoredUsers)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // ── Per-User Filtered Queries ────────────────────────────

  /// Get sessions for a specific user email.
  Future<List<VoiceSession>> getSessionsForUser(String email) =>
      (select(voiceSessions)
            ..where((t) => t.userEmail.equals(email))
            ..orderBy([(t) => OrderingTerm.desc(t.startTime)]))
          .get();

  /// Get all alerts for a specific user (via their sessions).
  Future<List<VoiceAlert>> getAlertsForUser(String email) async {
    final sessions = await getSessionsForUser(email);
    final sessionIds = sessions.map((s) => s.id).toSet();
    if (sessionIds.isEmpty) return [];
    return (select(voiceAlerts)
          ..where((t) => t.sessionId.isIn(sessionIds))
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
        .get();
  }

  /// Get all chunks for a specific user (via their sessions).
  Future<List<VoiceChunk>> getChunksForUser(String email) async {
    final sessions = await getSessionsForUser(email);
    final sessionIds = sessions.map((s) => s.id).toSet();
    if (sessionIds.isEmpty) return [];
    return (select(voiceChunks)
          ..where((t) => t.sessionId.isIn(sessionIds))
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
        .get();
  }

  /// Get user-level stats summary.
  Future<Map<String, dynamic>> getUserStats(String email) async {
    final sessions = await getSessionsForUser(email);
    final sessionIds = sessions.map((s) => s.id).toSet();
    int totalAlerts = 0;
    int totalChunks = 0;
    int flaggedChunks = 0;
    if (sessionIds.isNotEmpty) {
      final alerts = await (select(
        voiceAlerts,
      )..where((t) => t.sessionId.isIn(sessionIds))).get();
      totalAlerts = alerts.length;
      final chunks = await (select(
        voiceChunks,
      )..where((t) => t.sessionId.isIn(sessionIds))).get();
      totalChunks = chunks.length;
      flaggedChunks = chunks
          .where((c) => c.severity != 'clean' && c.severity.isNotEmpty)
          .length;
    }
    return {
      'totalSessions': sessions.length,
      'totalAlerts': totalAlerts,
      'totalChunks': totalChunks,
      'flaggedChunks': flaggedChunks,
    };
  }

  // ── Stats ────────────────────────────────────────────────

  Future<int> getTotalSessionCount() async {
    final count = voiceSessions.id.count();
    final query = selectOnly(voiceSessions)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  Future<void> clearAll() async {
    await delete(voiceAlerts).go();
    await delete(voiceChunks).go();
    await delete(voiceSessions).go();
  }
}

// ─── Connection Setup ────────────────────────────────────────

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'shadow_sentinel_voice.db'));
    return NativeDatabase.createInBackground(file);
  });
}
