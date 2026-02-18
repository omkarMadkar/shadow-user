import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/sentinel_theme.dart';
import '../providers/auth_provider.dart';
import '../models/user_profile.dart';

/// Dashboard header bar — brand, clock, session timer, status pills, user avatar.
class SentinelHeader extends StatefulWidget {
  const SentinelHeader({super.key});

  @override
  State<SentinelHeader> createState() => _SentinelHeaderState();
}

class _SentinelHeaderState extends State<SentinelHeader> {
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SentinelTheme.surface.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(color: SentinelTheme.border),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // Logo
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: SentinelTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: SentinelTheme.cyberBlue.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: SentinelTheme.cyberBlue.withValues(alpha: 0.15),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(Icons.shield, size: 18, color: SentinelTheme.cyberBlue),
          ),
          const SizedBox(width: 12),
          // Title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'SHADOW',
                    style: SentinelTheme.sans.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: SentinelTheme.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'SENTINEL',
                    style: SentinelTheme.sans.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: SentinelTheme.cyberBlue,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Text(
                'CONTINUOUS AUTHENTICATION PLATFORM',
                style: SentinelTheme.sans.copyWith(
                  fontSize: 8,
                  color: SentinelTheme.textMuted,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Status pills
          _StatusPill('Network', 'Secure', SentinelTheme.alertGreen),
          const SizedBox(width: 8),
          _StatusPill('Encryption', 'AES-256', SentinelTheme.cyberCyan),
          const SizedBox(width: 8),
          _StatusPill('Protocol', 'Zero Trust', SentinelTheme.cyberBlue),

          const SizedBox(width: 20),

          // Clock & session
          StreamBuilder(
            stream: Stream.periodic(const Duration(seconds: 1)),
            builder: (_, __) {
              final now = DateTime.now();
              final session = now.difference(_startTime);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
                    style: SentinelTheme.mono.copyWith(
                      fontSize: 12,
                      color: SentinelTheme.textSecondary,
                    ),
                  ),
                  Text(
                    'Session: ${_formatDuration(session)}',
                    style: SentinelTheme.mono.copyWith(
                      fontSize: 10,
                      color: SentinelTheme.textMuted,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(width: 16),
          Container(width: 1, height: 30, color: SentinelTheme.border),
          const SizedBox(width: 16),

          // User avatar & profile
          _UserProfileChip(),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatusPill(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '$label: ',
            style: SentinelTheme.mono.copyWith(
              fontSize: 9,
              color: SentinelTheme.textMuted,
            ),
          ),
          Text(
            value,
            style: SentinelTheme.mono.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dynamic user profile chip — shows avatar, name, role badge and sign-out.
class _UserProfileChip extends StatelessWidget {
  const _UserProfileChip();

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return SentinelTheme.alertRed;
      case UserRole.analyst:
        return SentinelTheme.cyberBlue;
      case UserRole.viewer:
        return SentinelTheme.alertGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      // Not signed in — show placeholder
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: SentinelTheme.cyberBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: SentinelTheme.cyberBlue.withValues(alpha: 0.2),
          ),
        ),
        child: Icon(Icons.person, size: 18, color: SentinelTheme.textMuted),
      );
    }

    final roleColor = _roleColor(user.role);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar (network photo or initials)
        _buildAvatar(user),
        const SizedBox(width: 8),

        // Name, email, role badge
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.displayName,
                  style: SentinelTheme.sans.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: SentinelTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: roleColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    user.role.label,
                    style: SentinelTheme.mono.copyWith(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: roleColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // Demo badge
                if (user.isDemo) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: SentinelTheme.alertAmber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'DEMO',
                      style: SentinelTheme.mono.copyWith(
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                        color: SentinelTheme.alertAmber,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Text(
              user.email,
              style: SentinelTheme.sans.copyWith(
                fontSize: 10,
                color: SentinelTheme.textMuted,
              ),
            ),
          ],
        ),

        const SizedBox(width: 8),

        // Sign-out button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => auth.signOut(),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: SentinelTheme.alertRed.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: SentinelTheme.alertRed.withValues(alpha: 0.15),
                ),
              ),
              child: Icon(
                Icons.logout,
                size: 14,
                color: SentinelTheme.alertRed.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(UserProfile user) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _roleColor(user.role).withValues(alpha: 0.3),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: user.photoUrl != null && user.photoUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: user.photoUrl!,
                width: 34,
                height: 34,
                fit: BoxFit.cover,
                placeholder: (_, __) => _initialsWidget(user),
                errorWidget: (_, __, ___) => _initialsWidget(user),
              )
            : _initialsWidget(user),
      ),
    );
  }

  Widget _initialsWidget(UserProfile user) {
    final color = _roleColor(user.role);
    return Container(
      color: color.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          user.initials,
          style: SentinelTheme.sans.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

