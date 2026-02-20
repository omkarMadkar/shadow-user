import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/sentinel_provider.dart';
import 'providers/voice_sentinel_provider.dart';
import 'providers/auth_provider.dart';
import 'theme/sentinel_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/email_threat_screen.dart';
import 'screens/neural_camera_screen.dart';
import 'screens/voice_sentinel_screen.dart';
import 'screens/login_screen.dart';
import 'screens/screen_capture_test_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'widgets/sentinel_header.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise auth (tries Firebase, falls back to demo mode)
  final authProvider = AuthProvider();
  await authProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => SentinelProvider()),
        ChangeNotifierProvider(create: (_) => VoiceSentinelProvider()),
      ],
      child: const ShadowSentinelApp(),
    ),
  );
}

class ShadowSentinelApp extends StatelessWidget {
  const ShadowSentinelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shadow Sentinel',
      debugShowCheckedModeBanner: false,
      theme: SentinelTheme.darkTheme,
      home: const _AuthGate(),
    );
  }
}

/// Redirects to [LoginScreen] or [MainShell] based on auth state.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return Scaffold(
        backgroundColor: SentinelTheme.bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: SentinelTheme.cyberBlue,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'INITIALISING SHADOW SENTINEL…',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 11,
                  color: SentinelTheme.textMuted,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    // Admin users go to oversight dashboard
    if (auth.isAdminLogin) {
      return const AdminDashboardScreen();
    }

    // Tag voice sessions with the current user's email
    final voiceProv = context.read<VoiceSentinelProvider>();
    voiceProv.currentUserEmail = auth.user?.email ?? 'unknown';

    return const MainShell();
  }
}

/// Main navigation shell with bottom navigation bar.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    DashboardScreen(),
    EmailThreatScreen(),
    NeuralCameraScreen(),
    VoiceSentinelScreen(),
    ScreenCaptureTestScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SentinelTheme.bg,
      body: Column(
        children: [
          const SentinelHeader(),
          Expanded(child: _screens[_currentIndex]),
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: SentinelTheme.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Shadow Sentinel v2.4.1 — Zero Trust Continuous Authentication',
                  style: SentinelTheme.sans.copyWith(
                    fontSize: 10,
                    color: SentinelTheme.textMuted,
                  ),
                ),
                Text(
                  'Encrypted Session • AES-256-GCM • TLS 1.3',
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 10,
                    color: SentinelTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: SentinelTheme.surface,
          border: Border(top: BorderSide(color: SentinelTheme.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: SentinelTheme.cyberBlue,
          unselectedItemColor: SentinelTheme.textMuted,
          selectedLabelStyle: SentinelTheme.mono.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: SentinelTheme.mono.copyWith(
            fontSize: 9,
            letterSpacing: 0.5,
          ),
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              activeIcon: _ActiveNavIcon(
                Icons.dashboard,
                SentinelTheme.cyberBlue,
              ),
              label: 'DASHBOARD',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.email),
              activeIcon: _ActiveNavIcon(Icons.email, SentinelTheme.alertRed),
              label: 'EMAIL SENTINEL',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.face_retouching_natural),
              activeIcon: _ActiveNavIcon(
                Icons.face_retouching_natural,
                SentinelTheme.cyberCyan,
              ),
              label: 'NEURAL CAMERA',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.mic),
              activeIcon: _ActiveNavIcon(Icons.mic, const Color(0xFF8B5CF6)),
              label: 'VOICE SENTINEL',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.screenshot),
              activeIcon: _ActiveNavIcon(Icons.screenshot, SentinelTheme.alertGreen),
              label: 'CAPTURE TEST',
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveNavIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _ActiveNavIcon(this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
