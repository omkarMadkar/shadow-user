// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_database.dart';

// ignore_for_file: type=lint
class $VoiceSessionsTable extends VoiceSessions
    with TableInfo<$VoiceSessionsTable, VoiceSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VoiceSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
    'end_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('recording'),
  );
  static const VerificationMeta _totalChunksMeta = const VerificationMeta(
    'totalChunks',
  );
  @override
  late final GeneratedColumn<int> totalChunks = GeneratedColumn<int>(
    'total_chunks',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _alertCountMeta = const VerificationMeta(
    'alertCount',
  );
  @override
  late final GeneratedColumn<int> alertCount = GeneratedColumn<int>(
    'alert_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _avgVolumeMeta = const VerificationMeta(
    'avgVolume',
  );
  @override
  late final GeneratedColumn<double> avgVolume = GeneratedColumn<double>(
    'avg_volume',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _totalDurationMsMeta = const VerificationMeta(
    'totalDurationMs',
  );
  @override
  late final GeneratedColumn<int> totalDurationMs = GeneratedColumn<int>(
    'total_duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startTime,
    endTime,
    status,
    totalChunks,
    alertCount,
    avgVolume,
    totalDurationMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'voice_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<VoiceSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('total_chunks')) {
      context.handle(
        _totalChunksMeta,
        totalChunks.isAcceptableOrUnknown(
          data['total_chunks']!,
          _totalChunksMeta,
        ),
      );
    }
    if (data.containsKey('alert_count')) {
      context.handle(
        _alertCountMeta,
        alertCount.isAcceptableOrUnknown(data['alert_count']!, _alertCountMeta),
      );
    }
    if (data.containsKey('avg_volume')) {
      context.handle(
        _avgVolumeMeta,
        avgVolume.isAcceptableOrUnknown(data['avg_volume']!, _avgVolumeMeta),
      );
    }
    if (data.containsKey('total_duration_ms')) {
      context.handle(
        _totalDurationMsMeta,
        totalDurationMs.isAcceptableOrUnknown(
          data['total_duration_ms']!,
          _totalDurationMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VoiceSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VoiceSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_time'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      totalChunks: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_chunks'],
      )!,
      alertCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}alert_count'],
      )!,
      avgVolume: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_volume'],
      )!,
      totalDurationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_duration_ms'],
      )!,
    );
  }

  @override
  $VoiceSessionsTable createAlias(String alias) {
    return $VoiceSessionsTable(attachedDatabase, alias);
  }
}

class VoiceSession extends DataClass implements Insertable<VoiceSession> {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final String status;
  final int totalChunks;
  final int alertCount;
  final double avgVolume;
  final int totalDurationMs;
  const VoiceSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.totalChunks,
    required this.alertCount,
    required this.avgVolume,
    required this.totalDurationMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['start_time'] = Variable<DateTime>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime>(endTime);
    }
    map['status'] = Variable<String>(status);
    map['total_chunks'] = Variable<int>(totalChunks);
    map['alert_count'] = Variable<int>(alertCount);
    map['avg_volume'] = Variable<double>(avgVolume);
    map['total_duration_ms'] = Variable<int>(totalDurationMs);
    return map;
  }

  VoiceSessionsCompanion toCompanion(bool nullToAbsent) {
    return VoiceSessionsCompanion(
      id: Value(id),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      status: Value(status),
      totalChunks: Value(totalChunks),
      alertCount: Value(alertCount),
      avgVolume: Value(avgVolume),
      totalDurationMs: Value(totalDurationMs),
    );
  }

  factory VoiceSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VoiceSession(
      id: serializer.fromJson<String>(json['id']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
      status: serializer.fromJson<String>(json['status']),
      totalChunks: serializer.fromJson<int>(json['totalChunks']),
      alertCount: serializer.fromJson<int>(json['alertCount']),
      avgVolume: serializer.fromJson<double>(json['avgVolume']),
      totalDurationMs: serializer.fromJson<int>(json['totalDurationMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime?>(endTime),
      'status': serializer.toJson<String>(status),
      'totalChunks': serializer.toJson<int>(totalChunks),
      'alertCount': serializer.toJson<int>(alertCount),
      'avgVolume': serializer.toJson<double>(avgVolume),
      'totalDurationMs': serializer.toJson<int>(totalDurationMs),
    };
  }

  VoiceSession copyWith({
    String? id,
    DateTime? startTime,
    Value<DateTime?> endTime = const Value.absent(),
    String? status,
    int? totalChunks,
    int? alertCount,
    double? avgVolume,
    int? totalDurationMs,
  }) => VoiceSession(
    id: id ?? this.id,
    startTime: startTime ?? this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
    status: status ?? this.status,
    totalChunks: totalChunks ?? this.totalChunks,
    alertCount: alertCount ?? this.alertCount,
    avgVolume: avgVolume ?? this.avgVolume,
    totalDurationMs: totalDurationMs ?? this.totalDurationMs,
  );
  VoiceSession copyWithCompanion(VoiceSessionsCompanion data) {
    return VoiceSession(
      id: data.id.present ? data.id.value : this.id,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      status: data.status.present ? data.status.value : this.status,
      totalChunks: data.totalChunks.present
          ? data.totalChunks.value
          : this.totalChunks,
      alertCount: data.alertCount.present
          ? data.alertCount.value
          : this.alertCount,
      avgVolume: data.avgVolume.present ? data.avgVolume.value : this.avgVolume,
      totalDurationMs: data.totalDurationMs.present
          ? data.totalDurationMs.value
          : this.totalDurationMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VoiceSession(')
          ..write('id: $id, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('status: $status, ')
          ..write('totalChunks: $totalChunks, ')
          ..write('alertCount: $alertCount, ')
          ..write('avgVolume: $avgVolume, ')
          ..write('totalDurationMs: $totalDurationMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startTime,
    endTime,
    status,
    totalChunks,
    alertCount,
    avgVolume,
    totalDurationMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VoiceSession &&
          other.id == this.id &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.status == this.status &&
          other.totalChunks == this.totalChunks &&
          other.alertCount == this.alertCount &&
          other.avgVolume == this.avgVolume &&
          other.totalDurationMs == this.totalDurationMs);
}

class VoiceSessionsCompanion extends UpdateCompanion<VoiceSession> {
  final Value<String> id;
  final Value<DateTime> startTime;
  final Value<DateTime?> endTime;
  final Value<String> status;
  final Value<int> totalChunks;
  final Value<int> alertCount;
  final Value<double> avgVolume;
  final Value<int> totalDurationMs;
  final Value<int> rowid;
  const VoiceSessionsCompanion({
    this.id = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.status = const Value.absent(),
    this.totalChunks = const Value.absent(),
    this.alertCount = const Value.absent(),
    this.avgVolume = const Value.absent(),
    this.totalDurationMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VoiceSessionsCompanion.insert({
    required String id,
    required DateTime startTime,
    this.endTime = const Value.absent(),
    this.status = const Value.absent(),
    this.totalChunks = const Value.absent(),
    this.alertCount = const Value.absent(),
    this.avgVolume = const Value.absent(),
    this.totalDurationMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       startTime = Value(startTime);
  static Insertable<VoiceSession> custom({
    Expression<String>? id,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<String>? status,
    Expression<int>? totalChunks,
    Expression<int>? alertCount,
    Expression<double>? avgVolume,
    Expression<int>? totalDurationMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (status != null) 'status': status,
      if (totalChunks != null) 'total_chunks': totalChunks,
      if (alertCount != null) 'alert_count': alertCount,
      if (avgVolume != null) 'avg_volume': avgVolume,
      if (totalDurationMs != null) 'total_duration_ms': totalDurationMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VoiceSessionsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? startTime,
    Value<DateTime?>? endTime,
    Value<String>? status,
    Value<int>? totalChunks,
    Value<int>? alertCount,
    Value<double>? avgVolume,
    Value<int>? totalDurationMs,
    Value<int>? rowid,
  }) {
    return VoiceSessionsCompanion(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      totalChunks: totalChunks ?? this.totalChunks,
      alertCount: alertCount ?? this.alertCount,
      avgVolume: avgVolume ?? this.avgVolume,
      totalDurationMs: totalDurationMs ?? this.totalDurationMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (totalChunks.present) {
      map['total_chunks'] = Variable<int>(totalChunks.value);
    }
    if (alertCount.present) {
      map['alert_count'] = Variable<int>(alertCount.value);
    }
    if (avgVolume.present) {
      map['avg_volume'] = Variable<double>(avgVolume.value);
    }
    if (totalDurationMs.present) {
      map['total_duration_ms'] = Variable<int>(totalDurationMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VoiceSessionsCompanion(')
          ..write('id: $id, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('status: $status, ')
          ..write('totalChunks: $totalChunks, ')
          ..write('alertCount: $alertCount, ')
          ..write('avgVolume: $avgVolume, ')
          ..write('totalDurationMs: $totalDurationMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VoiceChunksTable extends VoiceChunks
    with TableInfo<$VoiceChunksTable, VoiceChunk> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VoiceChunksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES voice_sessions (id)',
    ),
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _volumeDbMeta = const VerificationMeta(
    'volumeDb',
  );
  @override
  late final GeneratedColumn<double> volumeDb = GeneratedColumn<double>(
    'volume_db',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transcriptMeta = const VerificationMeta(
    'transcript',
  );
  @override
  late final GeneratedColumn<String> transcript = GeneratedColumn<String>(
    'transcript',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _severityMeta = const VerificationMeta(
    'severity',
  );
  @override
  late final GeneratedColumn<String> severity = GeneratedColumn<String>(
    'severity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('clean'),
  );
  static const VerificationMeta _flaggedWordsMeta = const VerificationMeta(
    'flaggedWords',
  );
  @override
  late final GeneratedColumn<String> flaggedWords = GeneratedColumn<String>(
    'flagged_words',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    filePath,
    durationMs,
    timestamp,
    volumeDb,
    transcript,
    severity,
    flaggedWords,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'voice_chunks';
  @override
  VerificationContext validateIntegrity(
    Insertable<VoiceChunk> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('volume_db')) {
      context.handle(
        _volumeDbMeta,
        volumeDb.isAcceptableOrUnknown(data['volume_db']!, _volumeDbMeta),
      );
    } else if (isInserting) {
      context.missing(_volumeDbMeta);
    }
    if (data.containsKey('transcript')) {
      context.handle(
        _transcriptMeta,
        transcript.isAcceptableOrUnknown(data['transcript']!, _transcriptMeta),
      );
    }
    if (data.containsKey('severity')) {
      context.handle(
        _severityMeta,
        severity.isAcceptableOrUnknown(data['severity']!, _severityMeta),
      );
    }
    if (data.containsKey('flagged_words')) {
      context.handle(
        _flaggedWordsMeta,
        flaggedWords.isAcceptableOrUnknown(
          data['flagged_words']!,
          _flaggedWordsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VoiceChunk map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VoiceChunk(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      volumeDb: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}volume_db'],
      )!,
      transcript: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transcript'],
      ),
      severity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}severity'],
      )!,
      flaggedWords: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}flagged_words'],
      )!,
    );
  }

  @override
  $VoiceChunksTable createAlias(String alias) {
    return $VoiceChunksTable(attachedDatabase, alias);
  }
}

class VoiceChunk extends DataClass implements Insertable<VoiceChunk> {
  final String id;
  final String sessionId;
  final String filePath;
  final int durationMs;
  final DateTime timestamp;
  final double volumeDb;
  final String? transcript;
  final String severity;
  final String flaggedWords;
  const VoiceChunk({
    required this.id,
    required this.sessionId,
    required this.filePath,
    required this.durationMs,
    required this.timestamp,
    required this.volumeDb,
    this.transcript,
    required this.severity,
    required this.flaggedWords,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['file_path'] = Variable<String>(filePath);
    map['duration_ms'] = Variable<int>(durationMs);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['volume_db'] = Variable<double>(volumeDb);
    if (!nullToAbsent || transcript != null) {
      map['transcript'] = Variable<String>(transcript);
    }
    map['severity'] = Variable<String>(severity);
    map['flagged_words'] = Variable<String>(flaggedWords);
    return map;
  }

  VoiceChunksCompanion toCompanion(bool nullToAbsent) {
    return VoiceChunksCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      filePath: Value(filePath),
      durationMs: Value(durationMs),
      timestamp: Value(timestamp),
      volumeDb: Value(volumeDb),
      transcript: transcript == null && nullToAbsent
          ? const Value.absent()
          : Value(transcript),
      severity: Value(severity),
      flaggedWords: Value(flaggedWords),
    );
  }

  factory VoiceChunk.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VoiceChunk(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      filePath: serializer.fromJson<String>(json['filePath']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      volumeDb: serializer.fromJson<double>(json['volumeDb']),
      transcript: serializer.fromJson<String?>(json['transcript']),
      severity: serializer.fromJson<String>(json['severity']),
      flaggedWords: serializer.fromJson<String>(json['flaggedWords']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'filePath': serializer.toJson<String>(filePath),
      'durationMs': serializer.toJson<int>(durationMs),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'volumeDb': serializer.toJson<double>(volumeDb),
      'transcript': serializer.toJson<String?>(transcript),
      'severity': serializer.toJson<String>(severity),
      'flaggedWords': serializer.toJson<String>(flaggedWords),
    };
  }

  VoiceChunk copyWith({
    String? id,
    String? sessionId,
    String? filePath,
    int? durationMs,
    DateTime? timestamp,
    double? volumeDb,
    Value<String?> transcript = const Value.absent(),
    String? severity,
    String? flaggedWords,
  }) => VoiceChunk(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    filePath: filePath ?? this.filePath,
    durationMs: durationMs ?? this.durationMs,
    timestamp: timestamp ?? this.timestamp,
    volumeDb: volumeDb ?? this.volumeDb,
    transcript: transcript.present ? transcript.value : this.transcript,
    severity: severity ?? this.severity,
    flaggedWords: flaggedWords ?? this.flaggedWords,
  );
  VoiceChunk copyWithCompanion(VoiceChunksCompanion data) {
    return VoiceChunk(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      volumeDb: data.volumeDb.present ? data.volumeDb.value : this.volumeDb,
      transcript: data.transcript.present
          ? data.transcript.value
          : this.transcript,
      severity: data.severity.present ? data.severity.value : this.severity,
      flaggedWords: data.flaggedWords.present
          ? data.flaggedWords.value
          : this.flaggedWords,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VoiceChunk(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('filePath: $filePath, ')
          ..write('durationMs: $durationMs, ')
          ..write('timestamp: $timestamp, ')
          ..write('volumeDb: $volumeDb, ')
          ..write('transcript: $transcript, ')
          ..write('severity: $severity, ')
          ..write('flaggedWords: $flaggedWords')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    filePath,
    durationMs,
    timestamp,
    volumeDb,
    transcript,
    severity,
    flaggedWords,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VoiceChunk &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.filePath == this.filePath &&
          other.durationMs == this.durationMs &&
          other.timestamp == this.timestamp &&
          other.volumeDb == this.volumeDb &&
          other.transcript == this.transcript &&
          other.severity == this.severity &&
          other.flaggedWords == this.flaggedWords);
}

class VoiceChunksCompanion extends UpdateCompanion<VoiceChunk> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> filePath;
  final Value<int> durationMs;
  final Value<DateTime> timestamp;
  final Value<double> volumeDb;
  final Value<String?> transcript;
  final Value<String> severity;
  final Value<String> flaggedWords;
  final Value<int> rowid;
  const VoiceChunksCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.volumeDb = const Value.absent(),
    this.transcript = const Value.absent(),
    this.severity = const Value.absent(),
    this.flaggedWords = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VoiceChunksCompanion.insert({
    required String id,
    required String sessionId,
    required String filePath,
    required int durationMs,
    required DateTime timestamp,
    required double volumeDb,
    this.transcript = const Value.absent(),
    this.severity = const Value.absent(),
    this.flaggedWords = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       filePath = Value(filePath),
       durationMs = Value(durationMs),
       timestamp = Value(timestamp),
       volumeDb = Value(volumeDb);
  static Insertable<VoiceChunk> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? filePath,
    Expression<int>? durationMs,
    Expression<DateTime>? timestamp,
    Expression<double>? volumeDb,
    Expression<String>? transcript,
    Expression<String>? severity,
    Expression<String>? flaggedWords,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (filePath != null) 'file_path': filePath,
      if (durationMs != null) 'duration_ms': durationMs,
      if (timestamp != null) 'timestamp': timestamp,
      if (volumeDb != null) 'volume_db': volumeDb,
      if (transcript != null) 'transcript': transcript,
      if (severity != null) 'severity': severity,
      if (flaggedWords != null) 'flagged_words': flaggedWords,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VoiceChunksCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? filePath,
    Value<int>? durationMs,
    Value<DateTime>? timestamp,
    Value<double>? volumeDb,
    Value<String?>? transcript,
    Value<String>? severity,
    Value<String>? flaggedWords,
    Value<int>? rowid,
  }) {
    return VoiceChunksCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      filePath: filePath ?? this.filePath,
      durationMs: durationMs ?? this.durationMs,
      timestamp: timestamp ?? this.timestamp,
      volumeDb: volumeDb ?? this.volumeDb,
      transcript: transcript ?? this.transcript,
      severity: severity ?? this.severity,
      flaggedWords: flaggedWords ?? this.flaggedWords,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (volumeDb.present) {
      map['volume_db'] = Variable<double>(volumeDb.value);
    }
    if (transcript.present) {
      map['transcript'] = Variable<String>(transcript.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(severity.value);
    }
    if (flaggedWords.present) {
      map['flagged_words'] = Variable<String>(flaggedWords.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VoiceChunksCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('filePath: $filePath, ')
          ..write('durationMs: $durationMs, ')
          ..write('timestamp: $timestamp, ')
          ..write('volumeDb: $volumeDb, ')
          ..write('transcript: $transcript, ')
          ..write('severity: $severity, ')
          ..write('flaggedWords: $flaggedWords, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VoiceAlertsTable extends VoiceAlerts
    with TableInfo<$VoiceAlertsTable, VoiceAlert> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VoiceAlertsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES voice_sessions (id)',
    ),
  );
  static const VerificationMeta _chunkIdMeta = const VerificationMeta(
    'chunkId',
  );
  @override
  late final GeneratedColumn<String> chunkId = GeneratedColumn<String>(
    'chunk_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES voice_chunks (id)',
    ),
  );
  static const VerificationMeta _alertTypeMeta = const VerificationMeta(
    'alertType',
  );
  @override
  late final GeneratedColumn<String> alertType = GeneratedColumn<String>(
    'alert_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _severityMeta = const VerificationMeta(
    'severity',
  );
  @override
  late final GeneratedColumn<String> severity = GeneratedColumn<String>(
    'severity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _flaggedPhraseMeta = const VerificationMeta(
    'flaggedPhrase',
  );
  @override
  late final GeneratedColumn<String> flaggedPhrase = GeneratedColumn<String>(
    'flagged_phrase',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contextMeta = const VerificationMeta(
    'context',
  );
  @override
  late final GeneratedColumn<String> context = GeneratedColumn<String>(
    'context',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confidenceScoreMeta = const VerificationMeta(
    'confidenceScore',
  );
  @override
  late final GeneratedColumn<double> confidenceScore = GeneratedColumn<double>(
    'confidence_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    chunkId,
    alertType,
    severity,
    flaggedPhrase,
    context,
    confidenceScore,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'voice_alerts';
  @override
  VerificationContext validateIntegrity(
    Insertable<VoiceAlert> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('chunk_id')) {
      context.handle(
        _chunkIdMeta,
        chunkId.isAcceptableOrUnknown(data['chunk_id']!, _chunkIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chunkIdMeta);
    }
    if (data.containsKey('alert_type')) {
      context.handle(
        _alertTypeMeta,
        alertType.isAcceptableOrUnknown(data['alert_type']!, _alertTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_alertTypeMeta);
    }
    if (data.containsKey('severity')) {
      context.handle(
        _severityMeta,
        severity.isAcceptableOrUnknown(data['severity']!, _severityMeta),
      );
    } else if (isInserting) {
      context.missing(_severityMeta);
    }
    if (data.containsKey('flagged_phrase')) {
      context.handle(
        _flaggedPhraseMeta,
        flaggedPhrase.isAcceptableOrUnknown(
          data['flagged_phrase']!,
          _flaggedPhraseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_flaggedPhraseMeta);
    }
    if (data.containsKey('context')) {
      context.handle(
        _contextMeta,
        this.context.isAcceptableOrUnknown(data['context']!, _contextMeta),
      );
    } else if (isInserting) {
      context.missing(_contextMeta);
    }
    if (data.containsKey('confidence_score')) {
      context.handle(
        _confidenceScoreMeta,
        confidenceScore.isAcceptableOrUnknown(
          data['confidence_score']!,
          _confidenceScoreMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_confidenceScoreMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VoiceAlert map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VoiceAlert(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      chunkId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chunk_id'],
      )!,
      alertType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alert_type'],
      )!,
      severity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}severity'],
      )!,
      flaggedPhrase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}flagged_phrase'],
      )!,
      context: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context'],
      )!,
      confidenceScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence_score'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $VoiceAlertsTable createAlias(String alias) {
    return $VoiceAlertsTable(attachedDatabase, alias);
  }
}

class VoiceAlert extends DataClass implements Insertable<VoiceAlert> {
  final String id;
  final String sessionId;
  final String chunkId;
  final String alertType;
  final String severity;
  final String flaggedPhrase;
  final String context;
  final double confidenceScore;
  final DateTime timestamp;
  const VoiceAlert({
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
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['chunk_id'] = Variable<String>(chunkId);
    map['alert_type'] = Variable<String>(alertType);
    map['severity'] = Variable<String>(severity);
    map['flagged_phrase'] = Variable<String>(flaggedPhrase);
    map['context'] = Variable<String>(context);
    map['confidence_score'] = Variable<double>(confidenceScore);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  VoiceAlertsCompanion toCompanion(bool nullToAbsent) {
    return VoiceAlertsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      chunkId: Value(chunkId),
      alertType: Value(alertType),
      severity: Value(severity),
      flaggedPhrase: Value(flaggedPhrase),
      context: Value(context),
      confidenceScore: Value(confidenceScore),
      timestamp: Value(timestamp),
    );
  }

  factory VoiceAlert.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VoiceAlert(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      chunkId: serializer.fromJson<String>(json['chunkId']),
      alertType: serializer.fromJson<String>(json['alertType']),
      severity: serializer.fromJson<String>(json['severity']),
      flaggedPhrase: serializer.fromJson<String>(json['flaggedPhrase']),
      context: serializer.fromJson<String>(json['context']),
      confidenceScore: serializer.fromJson<double>(json['confidenceScore']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'chunkId': serializer.toJson<String>(chunkId),
      'alertType': serializer.toJson<String>(alertType),
      'severity': serializer.toJson<String>(severity),
      'flaggedPhrase': serializer.toJson<String>(flaggedPhrase),
      'context': serializer.toJson<String>(context),
      'confidenceScore': serializer.toJson<double>(confidenceScore),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  VoiceAlert copyWith({
    String? id,
    String? sessionId,
    String? chunkId,
    String? alertType,
    String? severity,
    String? flaggedPhrase,
    String? context,
    double? confidenceScore,
    DateTime? timestamp,
  }) => VoiceAlert(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    chunkId: chunkId ?? this.chunkId,
    alertType: alertType ?? this.alertType,
    severity: severity ?? this.severity,
    flaggedPhrase: flaggedPhrase ?? this.flaggedPhrase,
    context: context ?? this.context,
    confidenceScore: confidenceScore ?? this.confidenceScore,
    timestamp: timestamp ?? this.timestamp,
  );
  VoiceAlert copyWithCompanion(VoiceAlertsCompanion data) {
    return VoiceAlert(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      chunkId: data.chunkId.present ? data.chunkId.value : this.chunkId,
      alertType: data.alertType.present ? data.alertType.value : this.alertType,
      severity: data.severity.present ? data.severity.value : this.severity,
      flaggedPhrase: data.flaggedPhrase.present
          ? data.flaggedPhrase.value
          : this.flaggedPhrase,
      context: data.context.present ? data.context.value : this.context,
      confidenceScore: data.confidenceScore.present
          ? data.confidenceScore.value
          : this.confidenceScore,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VoiceAlert(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('chunkId: $chunkId, ')
          ..write('alertType: $alertType, ')
          ..write('severity: $severity, ')
          ..write('flaggedPhrase: $flaggedPhrase, ')
          ..write('context: $context, ')
          ..write('confidenceScore: $confidenceScore, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    chunkId,
    alertType,
    severity,
    flaggedPhrase,
    context,
    confidenceScore,
    timestamp,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VoiceAlert &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.chunkId == this.chunkId &&
          other.alertType == this.alertType &&
          other.severity == this.severity &&
          other.flaggedPhrase == this.flaggedPhrase &&
          other.context == this.context &&
          other.confidenceScore == this.confidenceScore &&
          other.timestamp == this.timestamp);
}

class VoiceAlertsCompanion extends UpdateCompanion<VoiceAlert> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> chunkId;
  final Value<String> alertType;
  final Value<String> severity;
  final Value<String> flaggedPhrase;
  final Value<String> context;
  final Value<double> confidenceScore;
  final Value<DateTime> timestamp;
  final Value<int> rowid;
  const VoiceAlertsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.chunkId = const Value.absent(),
    this.alertType = const Value.absent(),
    this.severity = const Value.absent(),
    this.flaggedPhrase = const Value.absent(),
    this.context = const Value.absent(),
    this.confidenceScore = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VoiceAlertsCompanion.insert({
    required String id,
    required String sessionId,
    required String chunkId,
    required String alertType,
    required String severity,
    required String flaggedPhrase,
    required String context,
    required double confidenceScore,
    required DateTime timestamp,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       chunkId = Value(chunkId),
       alertType = Value(alertType),
       severity = Value(severity),
       flaggedPhrase = Value(flaggedPhrase),
       context = Value(context),
       confidenceScore = Value(confidenceScore),
       timestamp = Value(timestamp);
  static Insertable<VoiceAlert> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? chunkId,
    Expression<String>? alertType,
    Expression<String>? severity,
    Expression<String>? flaggedPhrase,
    Expression<String>? context,
    Expression<double>? confidenceScore,
    Expression<DateTime>? timestamp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (chunkId != null) 'chunk_id': chunkId,
      if (alertType != null) 'alert_type': alertType,
      if (severity != null) 'severity': severity,
      if (flaggedPhrase != null) 'flagged_phrase': flaggedPhrase,
      if (context != null) 'context': context,
      if (confidenceScore != null) 'confidence_score': confidenceScore,
      if (timestamp != null) 'timestamp': timestamp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VoiceAlertsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? chunkId,
    Value<String>? alertType,
    Value<String>? severity,
    Value<String>? flaggedPhrase,
    Value<String>? context,
    Value<double>? confidenceScore,
    Value<DateTime>? timestamp,
    Value<int>? rowid,
  }) {
    return VoiceAlertsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      chunkId: chunkId ?? this.chunkId,
      alertType: alertType ?? this.alertType,
      severity: severity ?? this.severity,
      flaggedPhrase: flaggedPhrase ?? this.flaggedPhrase,
      context: context ?? this.context,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      timestamp: timestamp ?? this.timestamp,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (chunkId.present) {
      map['chunk_id'] = Variable<String>(chunkId.value);
    }
    if (alertType.present) {
      map['alert_type'] = Variable<String>(alertType.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(severity.value);
    }
    if (flaggedPhrase.present) {
      map['flagged_phrase'] = Variable<String>(flaggedPhrase.value);
    }
    if (context.present) {
      map['context'] = Variable<String>(context.value);
    }
    if (confidenceScore.present) {
      map['confidence_score'] = Variable<double>(confidenceScore.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VoiceAlertsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('chunkId: $chunkId, ')
          ..write('alertType: $alertType, ')
          ..write('severity: $severity, ')
          ..write('flaggedPhrase: $flaggedPhrase, ')
          ..write('context: $context, ')
          ..write('confidenceScore: $confidenceScore, ')
          ..write('timestamp: $timestamp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$VoiceDatabase extends GeneratedDatabase {
  _$VoiceDatabase(QueryExecutor e) : super(e);
  $VoiceDatabaseManager get managers => $VoiceDatabaseManager(this);
  late final $VoiceSessionsTable voiceSessions = $VoiceSessionsTable(this);
  late final $VoiceChunksTable voiceChunks = $VoiceChunksTable(this);
  late final $VoiceAlertsTable voiceAlerts = $VoiceAlertsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    voiceSessions,
    voiceChunks,
    voiceAlerts,
  ];
}

typedef $$VoiceSessionsTableCreateCompanionBuilder =
    VoiceSessionsCompanion Function({
      required String id,
      required DateTime startTime,
      Value<DateTime?> endTime,
      Value<String> status,
      Value<int> totalChunks,
      Value<int> alertCount,
      Value<double> avgVolume,
      Value<int> totalDurationMs,
      Value<int> rowid,
    });
typedef $$VoiceSessionsTableUpdateCompanionBuilder =
    VoiceSessionsCompanion Function({
      Value<String> id,
      Value<DateTime> startTime,
      Value<DateTime?> endTime,
      Value<String> status,
      Value<int> totalChunks,
      Value<int> alertCount,
      Value<double> avgVolume,
      Value<int> totalDurationMs,
      Value<int> rowid,
    });

final class $$VoiceSessionsTableReferences
    extends BaseReferences<_$VoiceDatabase, $VoiceSessionsTable, VoiceSession> {
  $$VoiceSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$VoiceChunksTable, List<VoiceChunk>>
  _voiceChunksRefsTable(_$VoiceDatabase db) => MultiTypedResultKey.fromTable(
    db.voiceChunks,
    aliasName: $_aliasNameGenerator(
      db.voiceSessions.id,
      db.voiceChunks.sessionId,
    ),
  );

  $$VoiceChunksTableProcessedTableManager get voiceChunksRefs {
    final manager = $$VoiceChunksTableTableManager(
      $_db,
      $_db.voiceChunks,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_voiceChunksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$VoiceAlertsTable, List<VoiceAlert>>
  _voiceAlertsRefsTable(_$VoiceDatabase db) => MultiTypedResultKey.fromTable(
    db.voiceAlerts,
    aliasName: $_aliasNameGenerator(
      db.voiceSessions.id,
      db.voiceAlerts.sessionId,
    ),
  );

  $$VoiceAlertsTableProcessedTableManager get voiceAlertsRefs {
    final manager = $$VoiceAlertsTableTableManager(
      $_db,
      $_db.voiceAlerts,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_voiceAlertsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$VoiceSessionsTableFilterComposer
    extends Composer<_$VoiceDatabase, $VoiceSessionsTable> {
  $$VoiceSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalChunks => $composableBuilder(
    column: $table.totalChunks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get alertCount => $composableBuilder(
    column: $table.alertCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgVolume => $composableBuilder(
    column: $table.avgVolume,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalDurationMs => $composableBuilder(
    column: $table.totalDurationMs,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> voiceChunksRefs(
    Expression<bool> Function($$VoiceChunksTableFilterComposer f) f,
  ) {
    final $$VoiceChunksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.voiceChunks,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VoiceChunksTableFilterComposer(
            $db: $db,
            $table: $db.voiceChunks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> voiceAlertsRefs(
    Expression<bool> Function($$VoiceAlertsTableFilterComposer f) f,
  ) {
    final $$VoiceAlertsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.voiceAlerts,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VoiceAlertsTableFilterComposer(
            $db: $db,
            $table: $db.voiceAlerts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VoiceSessionsTableOrderingComposer
    extends Composer<_$VoiceDatabase, $VoiceSessionsTable> {
  $$VoiceSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalChunks => $composableBuilder(
    column: $table.totalChunks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get alertCount => $composableBuilder(
    column: $table.alertCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgVolume => $composableBuilder(
    column: $table.avgVolume,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalDurationMs => $composableBuilder(
    column: $table.totalDurationMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VoiceSessionsTableAnnotationComposer
    extends Composer<_$VoiceDatabase, $VoiceSessionsTable> {
  $$VoiceSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get totalChunks => $composableBuilder(
    column: $table.totalChunks,
    builder: (column) => column,
  );

  GeneratedColumn<int> get alertCount => $composableBuilder(
    column: $table.alertCount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get avgVolume =>
      $composableBuilder(column: $table.avgVolume, builder: (column) => column);

  GeneratedColumn<int> get totalDurationMs => $composableBuilder(
    column: $table.totalDurationMs,
    builder: (column) => column,
  );

  Expression<T> voiceChunksRefs<T extends Object>(
    Expression<T> Function($$VoiceChunksTableAnnotationComposer a) f,
  ) {
    final $$VoiceChunksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.voiceChunks,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VoiceChunksTableAnnotationComposer(
            $db: $db,
            $table: $db.voiceChunks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> voiceAlertsRefs<T extends Object>(
    Expression<T> Function($$VoiceAlertsTableAnnotationComposer a) f,
  ) {
    final $$VoiceAlertsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.voiceAlerts,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VoiceAlertsTableAnnotationComposer(
            $db: $db,
            $table: $db.voiceAlerts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VoiceSessionsTableTableManager
    extends
        RootTableManager<
          _$VoiceDatabase,
          $VoiceSessionsTable,
          VoiceSession,
          $$VoiceSessionsTableFilterComposer,
          $$VoiceSessionsTableOrderingComposer,
          $$VoiceSessionsTableAnnotationComposer,
          $$VoiceSessionsTableCreateCompanionBuilder,
          $$VoiceSessionsTableUpdateCompanionBuilder,
          (VoiceSession, $$VoiceSessionsTableReferences),
          VoiceSession,
          PrefetchHooks Function({bool voiceChunksRefs, bool voiceAlertsRefs})
        > {
  $$VoiceSessionsTableTableManager(
    _$VoiceDatabase db,
    $VoiceSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VoiceSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VoiceSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VoiceSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> startTime = const Value.absent(),
                Value<DateTime?> endTime = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> totalChunks = const Value.absent(),
                Value<int> alertCount = const Value.absent(),
                Value<double> avgVolume = const Value.absent(),
                Value<int> totalDurationMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VoiceSessionsCompanion(
                id: id,
                startTime: startTime,
                endTime: endTime,
                status: status,
                totalChunks: totalChunks,
                alertCount: alertCount,
                avgVolume: avgVolume,
                totalDurationMs: totalDurationMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime startTime,
                Value<DateTime?> endTime = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> totalChunks = const Value.absent(),
                Value<int> alertCount = const Value.absent(),
                Value<double> avgVolume = const Value.absent(),
                Value<int> totalDurationMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VoiceSessionsCompanion.insert(
                id: id,
                startTime: startTime,
                endTime: endTime,
                status: status,
                totalChunks: totalChunks,
                alertCount: alertCount,
                avgVolume: avgVolume,
                totalDurationMs: totalDurationMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$VoiceSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({voiceChunksRefs = false, voiceAlertsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (voiceChunksRefs) db.voiceChunks,
                    if (voiceAlertsRefs) db.voiceAlerts,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (voiceChunksRefs)
                        await $_getPrefetchedData<
                          VoiceSession,
                          $VoiceSessionsTable,
                          VoiceChunk
                        >(
                          currentTable: table,
                          referencedTable: $$VoiceSessionsTableReferences
                              ._voiceChunksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VoiceSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).voiceChunksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (voiceAlertsRefs)
                        await $_getPrefetchedData<
                          VoiceSession,
                          $VoiceSessionsTable,
                          VoiceAlert
                        >(
                          currentTable: table,
                          referencedTable: $$VoiceSessionsTableReferences
                              ._voiceAlertsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VoiceSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).voiceAlertsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$VoiceSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$VoiceDatabase,
      $VoiceSessionsTable,
      VoiceSession,
      $$VoiceSessionsTableFilterComposer,
      $$VoiceSessionsTableOrderingComposer,
      $$VoiceSessionsTableAnnotationComposer,
      $$VoiceSessionsTableCreateCompanionBuilder,
      $$VoiceSessionsTableUpdateCompanionBuilder,
      (VoiceSession, $$VoiceSessionsTableReferences),
      VoiceSession,
      PrefetchHooks Function({bool voiceChunksRefs, bool voiceAlertsRefs})
    >;
typedef $$VoiceChunksTableCreateCompanionBuilder =
    VoiceChunksCompanion Function({
      required String id,
      required String sessionId,
      required String filePath,
      required int durationMs,
      required DateTime timestamp,
      required double volumeDb,
      Value<String?> transcript,
      Value<String> severity,
      Value<String> flaggedWords,
      Value<int> rowid,
    });
typedef $$VoiceChunksTableUpdateCompanionBuilder =
    VoiceChunksCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String> filePath,
      Value<int> durationMs,
      Value<DateTime> timestamp,
      Value<double> volumeDb,
      Value<String?> transcript,
      Value<String> severity,
      Value<String> flaggedWords,
      Value<int> rowid,
    });

final class $$VoiceChunksTableReferences
    extends BaseReferences<_$VoiceDatabase, $VoiceChunksTable, VoiceChunk> {
  $$VoiceChunksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VoiceSessionsTable _sessionIdTable(_$VoiceDatabase db) =>
      db.voiceSessions.createAlias(
        $_aliasNameGenerator(db.voiceChunks.sessionId, db.voiceSessions.id),
      );

  $$VoiceSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$VoiceSessionsTableTableManager(
      $_db,
      $_db.voiceSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$VoiceAlertsTable, List<VoiceAlert>>
  _voiceAlertsRefsTable(_$VoiceDatabase db) => MultiTypedResultKey.fromTable(
    db.voiceAlerts,
    aliasName: $_aliasNameGenerator(db.voiceChunks.id, db.voiceAlerts.chunkId),
  );

  $$VoiceAlertsTableProcessedTableManager get voiceAlertsRefs {
    final manager = $$VoiceAlertsTableTableManager(
      $_db,
      $_db.voiceAlerts,
    ).filter((f) => f.chunkId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_voiceAlertsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$VoiceChunksTableFilterComposer
    extends Composer<_$VoiceDatabase, $VoiceChunksTable> {
  $$VoiceChunksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get volumeDb => $composableBuilder(
    column: $table.volumeDb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transcript => $composableBuilder(
    column: $table.transcript,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get flaggedWords => $composableBuilder(
    column: $table.flaggedWords,
    builder: (column) => ColumnFilters(column),
  );

  $$VoiceSessionsTableFilterComposer get sessionId {
    final $$VoiceSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.voiceSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VoiceSessionsTableFilterComposer(
            $db: $db,
            $table: $db.voiceSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> voiceAlertsRefs(
    Expression<bool> Function($$VoiceAlertsTableFilterComposer f) f,
  ) {
    final $$VoiceAlertsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.voiceAlerts,
      getReferencedColumn: (t) => t.chunkId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VoiceAlertsTableFilterComposer(
            $db: $db,
            $table: $db.voiceAlerts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VoiceChunksTableOrderingComposer
    extends Composer<_$VoiceDatabase, $VoiceChunksTable> {
  $$VoiceChunksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get volumeDb => $composableBuilder(
    column: $table.volumeDb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transcript => $composableBuilder(
    column: $table.transcript,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get flaggedWords => $composableBuilder(
    column: $table.flaggedWords,
    builder: (column) => ColumnOrderings(column),
  );

  $$VoiceSessionsTableOrderingComposer get sessionId {
    final $$VoiceSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.voiceSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VoiceSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.voiceSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VoiceChunksTableAnnotationComposer
    extends Composer<_$VoiceDatabase, $VoiceChunksTable> {
  $$VoiceChunksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<double> get volumeDb =>
      $composableBuilder(column: $table.volumeDb, builder: (column) => column);

  GeneratedColumn<String> get transcript => $composableBuilder(
    column: $table.transcript,
    builder: (column) => column,
  );

  GeneratedColumn<String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<String> get flaggedWords => $composableBuilder(
    column: $table.flaggedWords,
    builder: (column) => column,
  );

  $$VoiceSessionsTableAnnotationComposer get sessionId {
    final $$VoiceSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.voiceSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VoiceSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.voiceSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> voiceAlertsRefs<T extends Object>(
    Expression<T> Function($$VoiceAlertsTableAnnotationComposer a) f,
  ) {
    final $$VoiceAlertsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.voiceAlerts,
      getReferencedColumn: (t) => t.chunkId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VoiceAlertsTableAnnotationComposer(
            $db: $db,
            $table: $db.voiceAlerts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VoiceChunksTableTableManager
    extends
        RootTableManager<
          _$VoiceDatabase,
          $VoiceChunksTable,
          VoiceChunk,
          $$VoiceChunksTableFilterComposer,
          $$VoiceChunksTableOrderingComposer,
          $$VoiceChunksTableAnnotationComposer,
          $$VoiceChunksTableCreateCompanionBuilder,
          $$VoiceChunksTableUpdateCompanionBuilder,
          (VoiceChunk, $$VoiceChunksTableReferences),
          VoiceChunk,
          PrefetchHooks Function({bool sessionId, bool voiceAlertsRefs})
        > {
  $$VoiceChunksTableTableManager(_$VoiceDatabase db, $VoiceChunksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VoiceChunksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VoiceChunksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VoiceChunksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<double> volumeDb = const Value.absent(),
                Value<String?> transcript = const Value.absent(),
                Value<String> severity = const Value.absent(),
                Value<String> flaggedWords = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VoiceChunksCompanion(
                id: id,
                sessionId: sessionId,
                filePath: filePath,
                durationMs: durationMs,
                timestamp: timestamp,
                volumeDb: volumeDb,
                transcript: transcript,
                severity: severity,
                flaggedWords: flaggedWords,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String filePath,
                required int durationMs,
                required DateTime timestamp,
                required double volumeDb,
                Value<String?> transcript = const Value.absent(),
                Value<String> severity = const Value.absent(),
                Value<String> flaggedWords = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VoiceChunksCompanion.insert(
                id: id,
                sessionId: sessionId,
                filePath: filePath,
                durationMs: durationMs,
                timestamp: timestamp,
                volumeDb: volumeDb,
                transcript: transcript,
                severity: severity,
                flaggedWords: flaggedWords,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$VoiceChunksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({sessionId = false, voiceAlertsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (voiceAlertsRefs) db.voiceAlerts,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (sessionId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.sessionId,
                                    referencedTable:
                                        $$VoiceChunksTableReferences
                                            ._sessionIdTable(db),
                                    referencedColumn:
                                        $$VoiceChunksTableReferences
                                            ._sessionIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (voiceAlertsRefs)
                        await $_getPrefetchedData<
                          VoiceChunk,
                          $VoiceChunksTable,
                          VoiceAlert
                        >(
                          currentTable: table,
                          referencedTable: $$VoiceChunksTableReferences
                              ._voiceAlertsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VoiceChunksTableReferences(
                                db,
                                table,
                                p0,
                              ).voiceAlertsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.chunkId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$VoiceChunksTableProcessedTableManager =
    ProcessedTableManager<
      _$VoiceDatabase,
      $VoiceChunksTable,
      VoiceChunk,
      $$VoiceChunksTableFilterComposer,
      $$VoiceChunksTableOrderingComposer,
      $$VoiceChunksTableAnnotationComposer,
      $$VoiceChunksTableCreateCompanionBuilder,
      $$VoiceChunksTableUpdateCompanionBuilder,
      (VoiceChunk, $$VoiceChunksTableReferences),
      VoiceChunk,
      PrefetchHooks Function({bool sessionId, bool voiceAlertsRefs})
    >;
typedef $$VoiceAlertsTableCreateCompanionBuilder =
    VoiceAlertsCompanion Function({
      required String id,
      required String sessionId,
      required String chunkId,
      required String alertType,
      required String severity,
      required String flaggedPhrase,
      required String context,
      required double confidenceScore,
      required DateTime timestamp,
      Value<int> rowid,
    });
typedef $$VoiceAlertsTableUpdateCompanionBuilder =
    VoiceAlertsCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String> chunkId,
      Value<String> alertType,
      Value<String> severity,
      Value<String> flaggedPhrase,
      Value<String> context,
      Value<double> confidenceScore,
      Value<DateTime> timestamp,
      Value<int> rowid,
    });

final class $$VoiceAlertsTableReferences
    extends BaseReferences<_$VoiceDatabase, $VoiceAlertsTable, VoiceAlert> {
  $$VoiceAlertsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VoiceSessionsTable _sessionIdTable(_$VoiceDatabase db) =>
      db.voiceSessions.createAlias(
        $_aliasNameGenerator(db.voiceAlerts.sessionId, db.voiceSessions.id),
      );

  $$VoiceSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$VoiceSessionsTableTableManager(
      $_db,
      $_db.voiceSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $VoiceChunksTable _chunkIdTable(_$VoiceDatabase db) =>
      db.voiceChunks.createAlias(
        $_aliasNameGenerator(db.voiceAlerts.chunkId, db.voiceChunks.id),
      );

  $$VoiceChunksTableProcessedTableManager get chunkId {
    final $_column = $_itemColumn<String>('chunk_id')!;

    final manager = $$VoiceChunksTableTableManager(
      $_db,
      $_db.voiceChunks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_chunkIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$VoiceAlertsTableFilterComposer
    extends Composer<_$VoiceDatabase, $VoiceAlertsTable> {
  $$VoiceAlertsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alertType => $composableBuilder(
    column: $table.alertType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get flaggedPhrase => $composableBuilder(
    column: $table.flaggedPhrase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get context => $composableBuilder(
    column: $table.context,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidenceScore => $composableBuilder(
    column: $table.confidenceScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  $$VoiceSessionsTableFilterComposer get sessionId {
    final $$VoiceSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.voiceSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VoiceSessionsTableFilterComposer(
            $db: $db,
            $table: $db.voiceSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VoiceChunksTableFilterComposer get chunkId {
    final $$VoiceChunksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chunkId,
      referencedTable: $db.voiceChunks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VoiceChunksTableFilterComposer(
            $db: $db,
            $table: $db.voiceChunks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VoiceAlertsTableOrderingComposer
    extends Composer<_$VoiceDatabase, $VoiceAlertsTable> {
  $$VoiceAlertsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alertType => $composableBuilder(
    column: $table.alertType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get flaggedPhrase => $composableBuilder(
    column: $table.flaggedPhrase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get context => $composableBuilder(
    column: $table.context,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidenceScore => $composableBuilder(
    column: $table.confidenceScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  $$VoiceSessionsTableOrderingComposer get sessionId {
    final $$VoiceSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.voiceSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VoiceSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.voiceSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VoiceChunksTableOrderingComposer get chunkId {
    final $$VoiceChunksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chunkId,
      referencedTable: $db.voiceChunks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VoiceChunksTableOrderingComposer(
            $db: $db,
            $table: $db.voiceChunks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VoiceAlertsTableAnnotationComposer
    extends Composer<_$VoiceDatabase, $VoiceAlertsTable> {
  $$VoiceAlertsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get alertType =>
      $composableBuilder(column: $table.alertType, builder: (column) => column);

  GeneratedColumn<String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<String> get flaggedPhrase => $composableBuilder(
    column: $table.flaggedPhrase,
    builder: (column) => column,
  );

  GeneratedColumn<String> get context =>
      $composableBuilder(column: $table.context, builder: (column) => column);

  GeneratedColumn<double> get confidenceScore => $composableBuilder(
    column: $table.confidenceScore,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  $$VoiceSessionsTableAnnotationComposer get sessionId {
    final $$VoiceSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.voiceSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VoiceSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.voiceSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VoiceChunksTableAnnotationComposer get chunkId {
    final $$VoiceChunksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chunkId,
      referencedTable: $db.voiceChunks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VoiceChunksTableAnnotationComposer(
            $db: $db,
            $table: $db.voiceChunks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VoiceAlertsTableTableManager
    extends
        RootTableManager<
          _$VoiceDatabase,
          $VoiceAlertsTable,
          VoiceAlert,
          $$VoiceAlertsTableFilterComposer,
          $$VoiceAlertsTableOrderingComposer,
          $$VoiceAlertsTableAnnotationComposer,
          $$VoiceAlertsTableCreateCompanionBuilder,
          $$VoiceAlertsTableUpdateCompanionBuilder,
          (VoiceAlert, $$VoiceAlertsTableReferences),
          VoiceAlert,
          PrefetchHooks Function({bool sessionId, bool chunkId})
        > {
  $$VoiceAlertsTableTableManager(_$VoiceDatabase db, $VoiceAlertsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VoiceAlertsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VoiceAlertsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VoiceAlertsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> chunkId = const Value.absent(),
                Value<String> alertType = const Value.absent(),
                Value<String> severity = const Value.absent(),
                Value<String> flaggedPhrase = const Value.absent(),
                Value<String> context = const Value.absent(),
                Value<double> confidenceScore = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VoiceAlertsCompanion(
                id: id,
                sessionId: sessionId,
                chunkId: chunkId,
                alertType: alertType,
                severity: severity,
                flaggedPhrase: flaggedPhrase,
                context: context,
                confidenceScore: confidenceScore,
                timestamp: timestamp,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String chunkId,
                required String alertType,
                required String severity,
                required String flaggedPhrase,
                required String context,
                required double confidenceScore,
                required DateTime timestamp,
                Value<int> rowid = const Value.absent(),
              }) => VoiceAlertsCompanion.insert(
                id: id,
                sessionId: sessionId,
                chunkId: chunkId,
                alertType: alertType,
                severity: severity,
                flaggedPhrase: flaggedPhrase,
                context: context,
                confidenceScore: confidenceScore,
                timestamp: timestamp,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$VoiceAlertsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false, chunkId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable: $$VoiceAlertsTableReferences
                                    ._sessionIdTable(db),
                                referencedColumn: $$VoiceAlertsTableReferences
                                    ._sessionIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (chunkId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.chunkId,
                                referencedTable: $$VoiceAlertsTableReferences
                                    ._chunkIdTable(db),
                                referencedColumn: $$VoiceAlertsTableReferences
                                    ._chunkIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$VoiceAlertsTableProcessedTableManager =
    ProcessedTableManager<
      _$VoiceDatabase,
      $VoiceAlertsTable,
      VoiceAlert,
      $$VoiceAlertsTableFilterComposer,
      $$VoiceAlertsTableOrderingComposer,
      $$VoiceAlertsTableAnnotationComposer,
      $$VoiceAlertsTableCreateCompanionBuilder,
      $$VoiceAlertsTableUpdateCompanionBuilder,
      (VoiceAlert, $$VoiceAlertsTableReferences),
      VoiceAlert,
      PrefetchHooks Function({bool sessionId, bool chunkId})
    >;

class $VoiceDatabaseManager {
  final _$VoiceDatabase _db;
  $VoiceDatabaseManager(this._db);
  $$VoiceSessionsTableTableManager get voiceSessions =>
      $$VoiceSessionsTableTableManager(_db, _db.voiceSessions);
  $$VoiceChunksTableTableManager get voiceChunks =>
      $$VoiceChunksTableTableManager(_db, _db.voiceChunks);
  $$VoiceAlertsTableTableManager get voiceAlerts =>
      $$VoiceAlertsTableTableManager(_db, _db.voiceAlerts);
}
