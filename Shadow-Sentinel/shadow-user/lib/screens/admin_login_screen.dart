import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/sentinel_theme.dart';
import 'admin_dashboard_screen.dart';

/// Admin oversight login screen — separate entry point for admins
/// to view flagged/malicious data for monitored users.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.2, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: SentinelTheme.bg,
      body: Stack(
        children: [
          // Animated red-tinted grid background
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (_, __) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _AdminGridPainter(_glowAnimation.value),
            ),
          ),

          // Back button
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: SentinelTheme.textMuted,
                size: 18,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // Main content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAdminLogo(),
                    const SizedBox(height: 40),
                    _buildLoginCard(auth),
                    const SizedBox(height: 24),
                    Text(
                      'ADMIN OVERSIGHT PORTAL — AUTHORIZED PERSONNEL ONLY',
                      style: SentinelTheme.mono.copyWith(
                        fontSize: 9,
                        color: SentinelTheme.alertRed.withValues(alpha: 0.5),
                        letterSpacing: 2,
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

  Widget _buildAdminLogo() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (_, child) {
            return Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: SentinelTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: SentinelTheme.alertRed.withValues(alpha: 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: SentinelTheme.alertRed.withValues(
                      alpha: _glowAnimation.value * 0.3,
                    ),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.admin_panel_settings,
                size: 36,
                color: SentinelTheme.alertRed,
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ADMIN',
              style: SentinelTheme.sans.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: SentinelTheme.alertRed,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'OVERSIGHT',
              style: SentinelTheme.sans.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: SentinelTheme.textPrimary,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'USER ACTIVITY MONITORING & THREAT REVIEW',
          style: SentinelTheme.mono.copyWith(
            fontSize: 10,
            color: SentinelTheme.textMuted,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(AuthProvider auth) {
    return Container(
      decoration: BoxDecoration(
        color: SentinelTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: SentinelTheme.alertRed.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: SentinelTheme.alertRed.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SentinelTheme.alertRed,
                  boxShadow: [
                    BoxShadow(
                      color: SentinelTheme.alertRed.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'ADMIN AUTHENTICATION',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: SentinelTheme.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: SentinelTheme.alertRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: SentinelTheme.alertRed.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'RESTRICTED',
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: SentinelTheme.alertRed,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Username
          _buildField(
            controller: _usernameController,
            label: 'ADMIN USERNAME',
            icon: Icons.person_outline,
            hint: 'Enter admin username',
          ),
          const SizedBox(height: 14),

          // Password
          _buildField(
            controller: _passwordController,
            label: 'ADMIN PASSWORD',
            icon: Icons.lock_outline,
            hint: '••••••••',
            obscure: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: SentinelTheme.textMuted,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 20),

          // Error
          if (auth.error != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: SentinelTheme.alertRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: SentinelTheme.alertRed.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 16,
                    color: SentinelTheme.alertRed,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      auth.error!,
                      style: SentinelTheme.sans.copyWith(
                        fontSize: 11,
                        color: SentinelTheme.alertRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Submit
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: auth.isLoading ? null : _handleAdminLogin,
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: SentinelTheme.alertRed.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'ACCESS OVERSIGHT PANEL',
                          style: SentinelTheme.mono.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: SentinelTheme.mono.copyWith(
            fontSize: 10,
            color: SentinelTheme.textMuted,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: SentinelTheme.bg.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: SentinelTheme.border),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: SentinelTheme.mono.copyWith(
              fontSize: 13,
              color: SentinelTheme.textPrimary,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 18, color: SentinelTheme.textMuted),
              suffixIcon: suffixIcon,
              hintText: hint,
              hintStyle: SentinelTheme.mono.copyWith(
                fontSize: 12,
                color: SentinelTheme.textMuted.withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAdminLogin() async {
    final auth = context.read<AuthProvider>();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) return;

    final success = await auth.signInAsAdmin(username, password);

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    }
  }
}

// ─── Red-tinted Admin Grid ─────────────────────────────────

class _AdminGridPainter extends CustomPainter {
  final double pulse;
  _AdminGridPainter(this.pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SentinelTheme.alertRed.withValues(alpha: 0.02 + pulse * 0.015)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final center = Offset(size.width / 2, size.height * 0.35);
    final glowPaint = Paint()
      ..color = SentinelTheme.alertRed.withValues(alpha: 0.04 + pulse * 0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    canvas.drawCircle(center, 150 + pulse * 30, glowPaint);
  }

  @override
  bool shouldRepaint(_AdminGridPainter old) => old.pulse != pulse;
}
