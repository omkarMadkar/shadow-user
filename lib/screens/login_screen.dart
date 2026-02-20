import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_profile.dart';
import '../theme/sentinel_theme.dart';
import 'admin_login_screen.dart';

/// Cyberpunk-themed login screen for Shadow Sentinel.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isRegistering = false;
  bool _obscurePassword = true;
  UserRole _selectedRole = UserRole.admin;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: SentinelTheme.bg,
      body: Stack(
        children: [
          // Animated background grid
          _AnimatedGrid(animation: _pulseAnimation),

          // Main content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo & title
                    _buildLogo(),
                    const SizedBox(height: 40),

                    // Login card
                    _buildLoginCard(auth),

                    const SizedBox(height: 24),

                    // Demo mode button
                    _buildDemoButton(auth),

                    const SizedBox(height: 12),

                    // Admin login button
                    _buildAdminButton(),

                    const SizedBox(height: 16),

                    // Firebase status
                    if (!auth.isFirebaseAvailable)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: SentinelTheme.alertAmber.withValues(
                            alpha: 0.08,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: SentinelTheme.alertAmber.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: SentinelTheme.alertAmber,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Demo Mode — Firebase not configured',
                              style: SentinelTheme.mono.copyWith(
                                fontSize: 10,
                                color: SentinelTheme.alertAmber,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 40),

                    // Footer
                    Text(
                      'Shadow Sentinel v2.4.1 — Zero Trust Authentication',
                      style: SentinelTheme.mono.copyWith(
                        fontSize: 10,
                        color: SentinelTheme.textMuted,
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

  // ── Logo ─────────────────────────────────────────────────

  Widget _buildLogo() {
    return Column(
      children: [
        // Shield icon with glow
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (_, child) {
            return Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: SentinelTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: SentinelTheme.cyberBlue.withValues(alpha: 0.4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: SentinelTheme.cyberBlue.withValues(
                      alpha: _pulseAnimation.value * 0.3,
                    ),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.shield,
                size: 36,
                color: SentinelTheme.cyberBlue,
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SHADOW',
              style: SentinelTheme.sans.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: SentinelTheme.textPrimary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'SENTINEL',
              style: SentinelTheme.sans.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: SentinelTheme.cyberBlue,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'ZERO TRUST CONTINUOUS AUTHENTICATION PLATFORM',
          style: SentinelTheme.mono.copyWith(
            fontSize: 10,
            color: SentinelTheme.textMuted,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

  // ── Login Card ───────────────────────────────────────────

  Widget _buildLoginCard(AuthProvider auth) {
    return Container(
      decoration: SentinelTheme.glassCard(),
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
                  color: SentinelTheme.cyberBlue,
                  boxShadow: [
                    BoxShadow(
                      color: SentinelTheme.cyberBlue.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _isRegistering ? 'CREATE ACCOUNT' : 'AUTHENTICATE',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: SentinelTheme.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Google Sign-In button
          _buildGoogleButton(auth),
          const SizedBox(height: 16),

          // Divider
          Row(
            children: [
              Expanded(
                child: Container(height: 1, color: SentinelTheme.border),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR',
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 10,
                    color: SentinelTheme.textMuted,
                  ),
                ),
              ),
              Expanded(
                child: Container(height: 1, color: SentinelTheme.border),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Name field (only for registration)
          if (_isRegistering) ...[
            _buildTextField(
              controller: _nameController,
              label: 'DISPLAY NAME',
              icon: Icons.person_outline,
              hint: 'John Doe',
            ),
            const SizedBox(height: 12),
          ],

          // Email field
          _buildTextField(
            controller: _emailController,
            label: 'EMAIL',
            icon: Icons.email_outlined,
            hint: 'operator@sentinel.io',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),

          // Password field
          _buildTextField(
            controller: _passwordController,
            label: 'PASSWORD',
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

          // Role selector (registration only)
          if (_isRegistering) ...[
            const SizedBox(height: 16),
            Text(
              'SELECT ROLE',
              style: SentinelTheme.mono.copyWith(
                fontSize: 10,
                color: SentinelTheme.textMuted,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            _buildRoleSelector(),
          ],

          const SizedBox(height: 20),

          // Error message
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

          // Submit button
          _buildSubmitButton(auth),

          const SizedBox(height: 16),

          // Toggle register / login
          TextButton(
            onPressed: () => setState(() {
              _isRegistering = !_isRegistering;
            }),
            child: Text(
              _isRegistering
                  ? 'Already have an account? Sign in'
                  : 'Need an account? Create one',
              style: SentinelTheme.sans.copyWith(
                fontSize: 12,
                color: SentinelTheme.cyberBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Google Sign-In Button ────────────────────────────────

  Widget _buildGoogleButton(AuthProvider auth) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: auth.isLoading ? null : () => auth.signInWithGoogle(),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: SentinelTheme.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Google "G" icon
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Continue with Google',
                style: SentinelTheme.sans.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: SentinelTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Text Field ───────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
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
            keyboardType: keyboardType,
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

  // ── Role Selector ────────────────────────────────────────

  Widget _buildRoleSelector() {
    return Row(
      children: UserRole.values.map((role) {
        final isSelected = _selectedRole == role;
        final color = _roleColor(role);
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedRole = role),
            child: Container(
              margin: EdgeInsets.only(right: role != UserRole.viewer ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.12)
                    : SentinelTheme.bg.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? color.withValues(alpha: 0.5)
                      : SentinelTheme.border,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _roleIcon(role),
                    size: 18,
                    color: isSelected ? color : SentinelTheme.textMuted,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role.label,
                    style: SentinelTheme.mono.copyWith(
                      fontSize: 9,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isSelected ? color : SentinelTheme.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Submit Button ────────────────────────────────────────

  Widget _buildSubmitButton(AuthProvider auth) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: auth.isLoading ? null : _handleSubmit,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [SentinelTheme.cyberBlue, SentinelTheme.cyberCyan],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: SentinelTheme.cyberBlue.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: auth.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isRegistering ? 'CREATE ACCOUNT' : 'SIGN IN',
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
    );
  }

  // ── Demo Button ──────────────────────────────────────────

  Widget _buildDemoButton(AuthProvider auth) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: auth.isLoading
            ? null
            : () => auth.signInDemo(role: _selectedRole),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: SentinelTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: SentinelTheme.alertAmber.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.science_outlined,
                size: 18,
                color: SentinelTheme.alertAmber,
              ),
              const SizedBox(width: 8),
              Text(
                'ENTER DEMO MODE',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: SentinelTheme.alertAmber,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Admin Button ─────────────────────────────────────────

  Widget _buildAdminButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AdminLoginScreen()));
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: SentinelTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: SentinelTheme.alertRed.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.admin_panel_settings,
                size: 18,
                color: SentinelTheme.alertRed.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'ADMIN OVERSIGHT LOGIN',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: SentinelTheme.alertRed.withValues(alpha: 0.7),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Handlers ─────────────────────────────────────────────

  void _handleSubmit() {
    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) return;

    if (_isRegistering) {
      final name = _nameController.text.trim();
      auth.createAccount(email, password, name.isEmpty ? 'User' : name);
    } else {
      auth.signInWithEmail(email, password);
    }
  }

  // ── Helpers ──────────────────────────────────────────────

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

  IconData _roleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.analyst:
        return Icons.analytics;
      case UserRole.viewer:
        return Icons.visibility;
    }
  }
}

// ─── Animated Background Grid ──────────────────────────────

class _AnimatedGrid extends StatelessWidget {
  final Animation<double> animation;
  const _AnimatedGrid({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _GridPainter(animation.value),
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  final double pulse;
  _GridPainter(this.pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SentinelTheme.cyberBlue.withValues(alpha: 0.03 + pulse * 0.02)
      ..strokeWidth = 0.5;

    // Vertical lines
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Glowing center point
    final center = Offset(size.width / 2, size.height * 0.35);
    final glowPaint = Paint()
      ..color = SentinelTheme.cyberBlue.withValues(alpha: 0.05 + pulse * 0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    canvas.drawCircle(center, 150 + pulse * 30, glowPaint);
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => oldDelegate.pulse != pulse;
}
