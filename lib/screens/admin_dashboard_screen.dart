import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../database/voice_database.dart';
import '../theme/sentinel_theme.dart';
import 'admin_user_detail_screen.dart';

/// Admin oversight dashboard — shows a roster of all monitored users.
/// Tapping a user card drills into their detailed stats, alerts, and
/// transcripts via [AdminUserDetailScreen].
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final VoiceDatabase _db = VoiceDatabase();

  List<MonitoredUser> _users = [];
  Map<String, Map<String, dynamic>> _userStats = {};
  bool _loading = true;

  // Global aggregates
  int _totalUsers = 0;
  int _totalSessions = 0;
  int _totalAlerts = 0;
  int _totalFlagged = 0;

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
      final users = await _db.getAllMonitoredUsers();
      final statsMap = <String, Map<String, dynamic>>{};
      int totalSessions = 0;
      int totalAlerts = 0;
      int totalFlagged = 0;

      for (final user in users) {
        final stats = await _db.getUserStats(user.email);
        statsMap[user.uid] = stats;
        totalSessions += (stats['totalSessions'] as int?) ?? 0;
        totalAlerts += (stats['totalAlerts'] as int?) ?? 0;
        totalFlagged += (stats['flaggedChunks'] as int?) ?? 0;
      }

      setState(() {
        _users = users;
        _userStats = statsMap;
        _totalUsers = users.length;
        _totalSessions = totalSessions;
        _totalAlerts = totalAlerts;
        _totalFlagged = totalFlagged;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[AdminDashboard] Error loading data: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: SentinelTheme.bg,
      body: Column(
        children: [
          _buildHeader(auth),
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(
                      color: SentinelTheme.alertRed,
                      strokeWidth: 2,
                    ),
                  )
                : _buildContent(),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────

  Widget _buildHeader(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
      decoration: BoxDecoration(
        color: SentinelTheme.surface,
        border: Border(bottom: BorderSide(color: SentinelTheme.border)),
      ),
      child: Row(
        children: [
          // Admin badge
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
            child: Icon(
              Icons.admin_panel_settings,
              color: SentinelTheme.alertRed,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'ADMIN OVERSIGHT',
                      style: SentinelTheme.mono.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: SentinelTheme.alertRed,
                        letterSpacing: 1.5,
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
                          boxShadow: [
                            BoxShadow(
                              color: SentinelTheme.alertRed.withValues(
                                alpha: _pulseAnim.value * 0.5,
                              ),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'MONITORED USER ROSTER',
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 10,
                    color: SentinelTheme.textMuted,
                    letterSpacing: 1,
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
          const SizedBox(width: 4),
          // Sign out
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                auth.signOut();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: SentinelTheme.alertRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: SentinelTheme.alertRed.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout, size: 14, color: SentinelTheme.alertRed),
                    const SizedBox(width: 6),
                    Text(
                      'EXIT',
                      style: SentinelTheme.mono.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: SentinelTheme.alertRed,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Content ──────────────────────────────────────────────

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Global stats bar
          _buildGlobalStats(),
          const SizedBox(height: 24),

          // Section header
          _sectionHeader('MONITORED USERS', Icons.people),
          const SizedBox(height: 14),

          if (_users.isEmpty)
            _emptyState(
              'No users detected yet.',
              'Users will appear here once they sign in to Shadow Sentinel.',
            )
          else
            ..._users.map((user) => _buildUserCard(user)),
        ],
      ),
    );
  }

  // ── Global Stats ─────────────────────────────────────────

  Widget _buildGlobalStats() {
    return Row(
      children: [
        _GlobalStatChip(
          label: 'USERS',
          value: '$_totalUsers',
          icon: Icons.people,
          color: SentinelTheme.cyberBlue,
        ),
        const SizedBox(width: 12),
        _GlobalStatChip(
          label: 'SESSIONS',
          value: '$_totalSessions',
          icon: Icons.history,
          color: SentinelTheme.cyberCyan,
        ),
        const SizedBox(width: 12),
        _GlobalStatChip(
          label: 'ALERTS',
          value: '$_totalAlerts',
          icon: Icons.warning_amber,
          color: SentinelTheme.alertRed,
        ),
        const SizedBox(width: 12),
        _GlobalStatChip(
          label: 'FLAGGED',
          value: '$_totalFlagged',
          icon: Icons.flag,
          color: SentinelTheme.alertAmber,
        ),
      ],
    );
  }

  // ── User Card ────────────────────────────────────────────

  Widget _buildUserCard(MonitoredUser user) {
    final stats = _userStats[user.uid] ?? {};
    final sessions = (stats['totalSessions'] as int?) ?? 0;
    final alerts = (stats['totalAlerts'] as int?) ?? 0;
    final chunks = (stats['totalChunks'] as int?) ?? 0;
    final flagged = (stats['flaggedChunks'] as int?) ?? 0;

    final hasAlerts = alerts > 0;
    final accentColor = hasAlerts
        ? SentinelTheme.alertRed
        : SentinelTheme.cyberBlue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AdminUserDetailScreen(user: user),
              ),
            );
            // Refresh stats after returning from detail
            _loadData();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SentinelTheme.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                // Top row: avatar, name/email, role badge, arrow
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _initials(user.displayName),
                          style: SentinelTheme.mono.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Name & email
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName,
                            style: SentinelTheme.sans.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: SentinelTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: SentinelTheme.mono.copyWith(
                              fontSize: 11,
                              color: SentinelTheme.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        user.role.toUpperCase(),
                        style: SentinelTheme.mono.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: SentinelTheme.textMuted,
                      size: 22,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Bottom row: stats chips
                Row(
                  children: [
                    _UserStatChip(
                      icon: Icons.history,
                      label: '$sessions sessions',
                      color: SentinelTheme.cyberBlue,
                    ),
                    const SizedBox(width: 12),
                    _UserStatChip(
                      icon: Icons.mic,
                      label: '$chunks chunks',
                      color: SentinelTheme.cyberCyan,
                    ),
                    const SizedBox(width: 12),
                    _UserStatChip(
                      icon: Icons.warning_amber,
                      label: '$alerts alerts',
                      color: alerts > 0
                          ? SentinelTheme.alertRed
                          : SentinelTheme.alertGreen,
                    ),
                    const SizedBox(width: 12),
                    _UserStatChip(
                      icon: Icons.flag,
                      label: '$flagged flagged',
                      color: flagged > 0
                          ? SentinelTheme.alertAmber
                          : SentinelTheme.alertGreen,
                    ),
                    const Spacer(),
                    // Last login
                    Text(
                      'Last login: ${_formatDate(user.lastLogin)}',
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
        ),
      ),
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
            'Shadow Sentinel v2.4.1 — Admin Oversight Portal',
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

  Widget _sectionHeader(String title, IconData icon) {
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
        Icon(icon, size: 14, color: SentinelTheme.alertRed),
        const SizedBox(width: 6),
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

  Widget _emptyState(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: SentinelTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SentinelTheme.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_off,
            size: 48,
            color: SentinelTheme.textMuted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: SentinelTheme.mono.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: SentinelTheme.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: SentinelTheme.sans.copyWith(
              fontSize: 11,
              color: SentinelTheme.textMuted.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} $h:$m';
  }
}

// ─── Small Widgets ──────────────────────────────────────────

class _GlobalStatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _GlobalStatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: SentinelTheme.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: SentinelTheme.sans.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
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
      ),
    );
  }
}

class _UserStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _UserStatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
}
