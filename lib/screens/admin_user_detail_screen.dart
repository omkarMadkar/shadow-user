import 'package:flutter/material.dart';
import '../database/voice_database.dart';
import '../theme/sentinel_theme.dart';

/// Per-user detail view — shows all sessions, alerts, transcripts
/// for a single monitored user. Accessed from the admin user list.
class AdminUserDetailScreen extends StatefulWidget {
  final MonitoredUser user;

  const AdminUserDetailScreen({super.key, required this.user});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen>
    with SingleTickerProviderStateMixin {
  final VoiceDatabase _db = VoiceDatabase();

  List<VoiceAlert> _alerts = [];
  List<VoiceSession> _sessions = [];
  List<VoiceChunk> _flaggedChunks = [];
  List<VoiceChunk> _allChunks = [];
  Map<String, int> _alertBreakdown = {};
  bool _loading = true;
  int _selectedTab = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final email = widget.user.email;
      final sessions = await _db.getSessionsForUser(email);
      final alerts = await _db.getAlertsForUser(email);
      final allChunks = await _db.getChunksForUser(email);
      final flaggedChunks = allChunks
          .where((c) => c.severity != 'clean' && c.severity.isNotEmpty)
          .toList();

      // Build alert breakdown
      final breakdown = <String, int>{};
      for (final alert in alerts) {
        breakdown[alert.alertType] = (breakdown[alert.alertType] ?? 0) + 1;
      }

      setState(() {
        _alerts = alerts;
        _sessions = sessions;
        _alertBreakdown = breakdown;
        _allChunks = allChunks;
        _flaggedChunks = flaggedChunks;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[AdminUserDetail] Error loading data: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SentinelTheme.bg,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(
                      color: SentinelTheme.alertRed,
                      strokeWidth: 2,
                    ),
                  )
                : _buildTabContent(),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 40, 20, 16),
      decoration: BoxDecoration(
        color: SentinelTheme.surface,
        border: Border(bottom: BorderSide(color: SentinelTheme.border)),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(Icons.arrow_back, color: SentinelTheme.textMuted),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back to user list',
          ),
          const SizedBox(width: 4),
          // User avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: SentinelTheme.alertRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: SentinelTheme.alertRed.withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: Text(
                _initials(widget.user.displayName),
                style: SentinelTheme.mono.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: SentinelTheme.alertRed,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.user.displayName.toUpperCase(),
                        style: SentinelTheme.mono.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: SentinelTheme.textPrimary,
                          letterSpacing: 1.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, __) => Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: SentinelTheme.alertRed.withValues(
                            alpha: _pulseAnim.value,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.user.email,
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 11,
                    color: SentinelTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Refresh
          IconButton(
            icon: Icon(Icons.refresh, color: SentinelTheme.textMuted, size: 20),
            onPressed: _loadData,
            tooltip: 'Refresh data',
          ),
        ],
      ),
    );
  }

  // ── Tab Bar ──────────────────────────────────────────────

  Widget _buildTabBar() {
    final tabs = [
      ('OVERVIEW', Icons.dashboard),
      ('ALERTS', Icons.warning_amber),
      ('TRANSCRIPTS', Icons.text_snippet),
      ('SESSIONS', Icons.history),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: SentinelTheme.surface.withValues(alpha: 0.5),
        border: Border(bottom: BorderSide(color: SentinelTheme.border)),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isSelected = _selectedTab == i;
          final (label, icon) = tabs[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? SentinelTheme.alertRed.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? SentinelTheme.alertRed.withValues(alpha: 0.3)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 14,
                      color: isSelected
                          ? SentinelTheme.alertRed
                          : SentinelTheme.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: SentinelTheme.mono.copyWith(
                        fontSize: 10,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w400,
                        color: isSelected
                            ? SentinelTheme.alertRed
                            : SentinelTheme.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildAlertsTab();
      case 2:
        return _buildTranscriptsTab();
      case 3:
        return _buildSessionsTab();
      default:
        return _buildOverviewTab();
    }
  }

  // ── Overview Tab ─────────────────────────────────────────

  Widget _buildOverviewTab() {
    final totalAlerts = _alerts.length;
    final totalSessions = _sessions.length;
    final totalChunks = _allChunks.length;
    final flaggedCount = _flaggedChunks.length;
    final cleanRatio = totalChunks > 0
        ? ((totalChunks - flaggedCount) / totalChunks * 100).toStringAsFixed(1)
        : '100.0';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: _cardDecor(
              borderColor: SentinelTheme.cyberBlue.withValues(alpha: 0.3),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: SentinelTheme.cyberBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: SentinelTheme.cyberBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _initials(widget.user.displayName),
                      style: SentinelTheme.mono.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: SentinelTheme.cyberBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.displayName,
                        style: SentinelTheme.sans.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: SentinelTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.user.email,
                        style: SentinelTheme.mono.copyWith(
                          fontSize: 11,
                          color: SentinelTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: SentinelTheme.cyberBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color:
                              SentinelTheme.cyberBlue.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        widget.user.role.toUpperCase(),
                        style: SentinelTheme.mono.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: SentinelTheme.cyberBlue,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'First seen: ${_formatDate(widget.user.firstSeen)}',
                      style: SentinelTheme.mono.copyWith(
                        fontSize: 9,
                        color: SentinelTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Stats grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatCard(
                label: 'TOTAL ALERTS',
                value: '$totalAlerts',
                icon: Icons.warning_amber,
                color: SentinelTheme.alertRed,
              ),
              _StatCard(
                label: 'FLAGGED CHUNKS',
                value: '$flaggedCount',
                icon: Icons.flag,
                color: SentinelTheme.alertAmber,
              ),
              _StatCard(
                label: 'TOTAL SESSIONS',
                value: '$totalSessions',
                icon: Icons.history,
                color: SentinelTheme.cyberBlue,
              ),
              _StatCard(
                label: 'TOTAL CHUNKS',
                value: '$totalChunks',
                icon: Icons.mic,
                color: SentinelTheme.cyberCyan,
              ),
              _StatCard(
                label: 'CLEAN RATIO',
                value: '$cleanRatio%',
                icon: Icons.check_circle_outline,
                color: SentinelTheme.alertGreen,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Alert breakdown
          if (_alertBreakdown.isNotEmpty) ...[
            _sectionHeader('ALERT BREAKDOWN BY TYPE'),
            const SizedBox(height: 12),
            Container(
              decoration: _cardDecor(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: _alertBreakdown.entries.map((entry) {
                  final maxVal = _alertBreakdown.values
                      .reduce((a, b) => a > b ? a : b);
                  final ratio = maxVal > 0 ? entry.value / maxVal : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text(
                            entry.key.toUpperCase(),
                            style: SentinelTheme.mono.copyWith(
                              fontSize: 10,
                              color: _alertTypeColor(entry.key),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                height: 16,
                                decoration: BoxDecoration(
                                  color: SentinelTheme.bg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: ratio,
                                child: Container(
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: _alertTypeColor(entry.key)
                                        .withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${entry.value}',
                          style: SentinelTheme.mono.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: SentinelTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Recent alerts preview
          _sectionHeader('RECENT ALERTS'),
          const SizedBox(height: 12),
          ...(_alerts.take(5).map((a) => _buildAlertTile(a))),
          if (_alerts.isEmpty) _emptyState('No alerts recorded for this user.'),
        ],
      ),
    );
  }

  // ── Alerts Tab ───────────────────────────────────────────

  Widget _buildAlertsTab() {
    if (_alerts.isEmpty) {
      return Center(child: _emptyState('No alerts recorded.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _alerts.length,
      itemBuilder: (_, i) => _buildAlertTile(_alerts[i]),
    );
  }

  Widget _buildAlertTile(VoiceAlert alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _cardDecor(
        borderColor: _alertTypeColor(alert.alertType).withValues(alpha: 0.3),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _alertTypeColor(alert.alertType)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  alert.alertType.toUpperCase(),
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _alertTypeColor(alert.alertType),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      _severityColor(alert.severity).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  alert.severity.toUpperCase(),
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _severityColor(alert.severity),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatTime(alert.timestamp),
                style: SentinelTheme.mono.copyWith(
                  fontSize: 9,
                  color: SentinelTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.format_quote,
                size: 14,
                color: SentinelTheme.alertRed.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  alert.flaggedPhrase,
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 12,
                    color: SentinelTheme.alertRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            alert.context,
            style: SentinelTheme.sans.copyWith(
              fontSize: 11,
              color: SentinelTheme.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Confidence: ${alert.confidenceScore.toStringAsFixed(0)}%',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 9,
                  color: SentinelTheme.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Session: ${alert.sessionId.substring(0, alert.sessionId.length.clamp(0, 16))}',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 9,
                  color: SentinelTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Transcripts Tab ──────────────────────────────────────

  Widget _buildTranscriptsTab() {
    final transcribedChunks = _allChunks.where((c) {
      final t = c.transcript;
      return t != null &&
          t.isNotEmpty &&
          t != 'Transcribing...' &&
          !t.startsWith('(No speech');
    }).toList();

    if (transcribedChunks.isEmpty) {
      return Center(child: _emptyState('No transcriptions available.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transcribedChunks.length,
      itemBuilder: (_, i) {
        final chunk = transcribedChunks[i];
        final isFlagged = chunk.severity != 'clean';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: _cardDecor(
            borderColor: isFlagged
                ? SentinelTheme.alertRed.withValues(alpha: 0.3)
                : null,
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isFlagged ? Icons.flag : Icons.mic,
                    size: 14,
                    color: isFlagged
                        ? SentinelTheme.alertRed
                        : SentinelTheme.cyberBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chunk ${chunk.id.substring(0, chunk.id.length.clamp(0, 16))}',
                      style: SentinelTheme.mono.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: SentinelTheme.textPrimary,
                      ),
                    ),
                  ),
                  if (isFlagged)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _severityColor(chunk.severity)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        chunk.severity.toUpperCase(),
                        style: SentinelTheme.mono.copyWith(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: _severityColor(chunk.severity),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(chunk.timestamp),
                    style: SentinelTheme.mono.copyWith(
                      fontSize: 9,
                      color: SentinelTheme.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: SentinelTheme.bg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isFlagged
                        ? SentinelTheme.alertRed.withValues(alpha: 0.15)
                        : SentinelTheme.border,
                  ),
                ),
                child: Text(
                  chunk.transcript ?? '',
                  style: SentinelTheme.sans.copyWith(
                    fontSize: 12,
                    color: isFlagged
                        ? SentinelTheme.alertRed.withValues(alpha: 0.9)
                        : SentinelTheme.textPrimary.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
              ),
              if (chunk.flaggedWords.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: chunk.flaggedWords
                      .split(',')
                      .where((w) => w.trim().isNotEmpty)
                      .map((word) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            SentinelTheme.alertRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: SentinelTheme.alertRed
                              .withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        word.trim(),
                        style: SentinelTheme.mono.copyWith(
                          fontSize: 9,
                          color: SentinelTheme.alertRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ── Sessions Tab ─────────────────────────────────────────

  Widget _buildSessionsTab() {
    if (_sessions.isEmpty) {
      return Center(child: _emptyState('No sessions recorded.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sessions.length,
      itemBuilder: (_, i) {
        final session = _sessions[i];
        final durationMin =
            (session.totalDurationMs / 60000).toStringAsFixed(1);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: _cardDecor(),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.history,
                    size: 14,
                    color: SentinelTheme.cyberBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Session: ${session.id.substring(0, session.id.length.clamp(0, 20))}…',
                      style: SentinelTheme.mono.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: SentinelTheme.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: session.status == 'recording'
                          ? SentinelTheme.alertGreen.withValues(alpha: 0.15)
                          : SentinelTheme.textMuted.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      session.status.toUpperCase(),
                      style: SentinelTheme.mono.copyWith(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: session.status == 'recording'
                            ? SentinelTheme.alertGreen
                            : SentinelTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _miniStat(
                    Icons.timer,
                    '$durationMin min',
                    SentinelTheme.cyberBlue,
                  ),
                  const SizedBox(width: 16),
                  _miniStat(
                    Icons.mic,
                    '${session.totalChunks} chunks',
                    SentinelTheme.cyberCyan,
                  ),
                  const SizedBox(width: 16),
                  _miniStat(
                    Icons.warning_amber,
                    '${session.alertCount} alerts',
                    session.alertCount > 0
                        ? SentinelTheme.alertRed
                        : SentinelTheme.alertGreen,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Started: ${_formatTime(session.startTime)}',
                    style: SentinelTheme.mono.copyWith(
                      fontSize: 9,
                      color: SentinelTheme.textMuted,
                    ),
                  ),
                  if (session.endTime != null) ...[
                    const SizedBox(width: 12),
                    Text(
                      'Ended: ${_formatTime(session.endTime!)}',
                      style: SentinelTheme.mono.copyWith(
                        fontSize: 9,
                        color: SentinelTheme.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Footer ───────────────────────────────────────────────

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: SentinelTheme.surface,
        border: Border(top: BorderSide(color: SentinelTheme.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Shadow Sentinel — User Detail: ${widget.user.email}',
            style: SentinelTheme.sans.copyWith(
              fontSize: 10,
              color: SentinelTheme.textMuted,
            ),
          ),
          Text(
            'Read-Only Access • Data Integrity Protected',
            style: SentinelTheme.mono.copyWith(
              fontSize: 10,
              color: SentinelTheme.alertRed.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: SentinelTheme.alertRed,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: SentinelTheme.mono.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: SentinelTheme.textPrimary,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _emptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecor(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 36,
            color: SentinelTheme.alertGreen.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: SentinelTheme.sans.copyWith(
              fontSize: 12,
              color: SentinelTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: SentinelTheme.mono.copyWith(fontSize: 10, color: color),
        ),
      ],
    );
  }

  BoxDecoration _cardDecor({Color? borderColor}) {
    return BoxDecoration(
      color: SentinelTheme.surface.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: borderColor ?? SentinelTheme.border),
    );
  }

  Color _alertTypeColor(String type) {
    switch (type) {
      case 'threat':
        return SentinelTheme.alertRed;
      case 'harassment':
        return const Color(0xFFE879F9);
      case 'hostility':
        return SentinelTheme.alertAmber;
      case 'profanity':
        return const Color(0xFFF97316);
      case 'toxic':
        return const Color(0xFF8B5CF6);
      default:
        return SentinelTheme.textMuted;
    }
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'severe':
        return SentinelTheme.alertRed;
      case 'moderate':
        return SentinelTheme.alertAmber;
      case 'mild':
        return const Color(0xFFF59E0B);
      case 'clean':
        return SentinelTheme.alertGreen;
      default:
        return SentinelTheme.textMuted;
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    final d = '${dt.day}/${dt.month}/${dt.year}';
    return '$d $h:$m:$s';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─── Stat Card Widget ──────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SentinelTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: SentinelTheme.mono.copyWith(
                  fontSize: 9,
                  color: SentinelTheme.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: SentinelTheme.sans.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
