import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_options.dart';
import '../models/user_profile.dart';
import '../services/google_oauth_desktop.dart';

/// Manages authentication state for Shadow Sentinel.
///
/// Tries to initialise Firebase on startup.
/// If Firebase is not configured (placeholder keys), the provider
/// transparently falls back to **demo mode** — all auth operations
/// work locally via SharedPreferences so the app remains fully
/// functional without a cloud backend.
class AuthProvider extends ChangeNotifier {
  // ── Public State ─────────────────────────────────────────
  UserProfile? _user;
  UserProfile? get user => _user;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isFirebaseAvailable = false;
  bool get isFirebaseAvailable => _isFirebaseAvailable;

  bool get isAuthenticated => _user != null;
  bool get isDemoMode => _user?.isDemo ?? false;

  String? _error;
  String? get error => _error;

  // ── Internals ────────────────────────────────────────────
  StreamSubscription<User?>? _authSub;

  // ────────────────────────────────────────────────────────
  // Initialisation
  // ────────────────────────────────────────────────────────

  /// Call once from `main()` before `runApp`.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    // 1) Attempt Firebase initialisation
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isFirebaseAvailable = true;

      // Listen for auth state changes
      _authSub = FirebaseAuth.instance.authStateChanges().listen(
        _onFirebaseAuthChanged,
      );

      // Check if a user is already signed in
      final current = FirebaseAuth.instance.currentUser;
      if (current != null) {
        _user = await _resolveFirebaseUser(current);
      }
    } catch (e) {
      // Firebase not configured — use demo mode
      _isFirebaseAvailable = false;
      debugPrint('[AuthProvider] Firebase unavailable — demo mode ($e)');
    }

    // 2) Check for a saved demo session
    if (!_isFirebaseAvailable) {
      await _restoreDemoSession();
    }

    _isLoading = false;
    notifyListeners();
  }

  // ────────────────────────────────────────────────────────
  // Sign-In Methods
  // ────────────────────────────────────────────────────────

  /// Sign in as a demo user (works without Firebase).
  Future<void> signInDemo({
    String name = 'Shadow Operator',
    String email = 'operator@shadowsentinel.io',
    UserRole role = UserRole.admin,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Simulate brief network delay for UX polish
    await Future.delayed(const Duration(milliseconds: 800));

    _user = UserProfile(
      uid: 'demo-${DateTime.now().millisecondsSinceEpoch}',
      displayName: name,
      email: email,
      photoUrl: null,
      role: role,
      lastLogin: DateTime.now(),
      isDemo: true,
    );

    await _saveDemoSession();

    _isLoading = false;
    notifyListeners();
  }

  /// Sign in with email & password (Firebase).
  Future<void> signInWithEmail(String email, String password) async {
    if (!_isFirebaseAvailable) {
      await signInDemo(email: email);
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // `_onFirebaseAuthChanged` handles setting `_user`
    } on FirebaseAuthException catch (e) {
      _error = _friendlyError(e.code);
    } catch (e) {
      _error = 'Authentication failed: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Create a new account with email & password (Firebase).
  Future<void> createAccount(String email, String password, String name) async {
    if (!_isFirebaseAvailable) {
      await signInDemo(name: name, email: email);
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user?.updateDisplayName(name);
      await cred.user?.reload();
      // `_onFirebaseAuthChanged` handles setting `_user`
    } on FirebaseAuthException catch (e) {
      _error = _friendlyError(e.code);
    } catch (e) {
      _error = 'Registration failed: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Sign in with Google.
  /// On Windows, uses a manual OAuth2 browser flow (PKCE) since the
  /// `google_sign_in` plugin does not support Windows natively.
  /// Opens the system browser → user signs in → redirect captured on
  /// `localhost:8734` → tokens exchanged → Firebase credential created.
  Future<void> signInWithGoogle() async {
    if (!_isFirebaseAvailable) {
      await signInDemo(name: 'Google User', email: 'user@gmail.com');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (defaultTargetPlatform == TargetPlatform.windows) {
        // Desktop OAuth2 flow via system browser
        final oauth = GoogleOAuthDesktop(
          clientId:
              '1054561929122-03seduj3qla01q79tb2pea2htp7pthln.apps.googleusercontent.com',
          clientSecret: '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',
        );

        final result = await oauth.signIn();

        // Create Firebase credential from the Google tokens
        final credential = GoogleAuthProvider.credential(
          idToken: result.idToken,
          accessToken: result.accessToken,
        );

        await FirebaseAuth.instance.signInWithCredential(credential);
        // `_onFirebaseAuthChanged` handles setting `_user`
      } else {
        // Mobile / web path
        final provider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithProvider(provider);
      }
    } on FirebaseAuthException catch (e) {
      _error = _friendlyError(e.code);
    } catch (e) {
      _error = 'Google sign-in failed: $e';
      debugPrint('[AuthProvider] Google sign-in error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ────────────────────────────────────────────────────────
  // Sign Out
  // ────────────────────────────────────────────────────────

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    if (_isFirebaseAvailable) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }

    _user = null;
    await _clearDemoSession();

    _isLoading = false;
    notifyListeners();
  }

  // ────────────────────────────────────────────────────────
  // Role Management
  // ────────────────────────────────────────────────────────

  /// Update the current user's role (admin only).
  Future<void> updateUserRole(UserRole newRole) async {
    if (_user == null) return;

    _user = _user!.copyWith(role: newRole);

    if (_isFirebaseAvailable) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .update({'role': newRole.name});
      } catch (_) {}
    } else {
      await _saveDemoSession();
    }

    notifyListeners();
  }

  // ────────────────────────────────────────────────────────
  // Firebase Auth Listener
  // ────────────────────────────────────────────────────────

  Future<void> _onFirebaseAuthChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
    } else {
      _user = await _resolveFirebaseUser(firebaseUser);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<UserProfile> _resolveFirebaseUser(User fbUser) async {
    // Try to load role from Firestore
    UserRole role = UserRole.viewer;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(fbUser.uid)
          .get();
      if (doc.exists && doc.data()?['role'] != null) {
        role = UserRole.values.firstWhere(
          (r) => r.name == doc.data()!['role'],
          orElse: () => UserRole.viewer,
        );
      } else {
        // First sign-in — create user document with default role
        await FirebaseFirestore.instance
            .collection('users')
            .doc(fbUser.uid)
            .set({
              'displayName': fbUser.displayName ?? 'User',
              'email': fbUser.email ?? '',
              'photoUrl': fbUser.photoURL,
              'role': UserRole.viewer.name,
              'createdAt': FieldValue.serverTimestamp(),
              'lastLogin': FieldValue.serverTimestamp(),
            });
      }
    } catch (_) {
      // Firestore unavailable — default to viewer
    }

    return UserProfile(
      uid: fbUser.uid,
      displayName: fbUser.displayName ?? 'User',
      email: fbUser.email ?? '',
      photoUrl: fbUser.photoURL,
      role: role,
      lastLogin: DateTime.now(),
    );
  }

  // ────────────────────────────────────────────────────────
  // Demo Session Persistence
  // ────────────────────────────────────────────────────────

  Future<void> _saveDemoSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (_user == null) return;
    prefs.setString('demo_uid', _user!.uid);
    prefs.setString('demo_name', _user!.displayName);
    prefs.setString('demo_email', _user!.email);
    prefs.setString('demo_role', _user!.role.name);
    prefs.setString('demo_lastLogin', _user!.lastLogin.toIso8601String());
  }

  Future<void> _restoreDemoSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('demo_uid');
      if (uid == null) return;

      _user = UserProfile(
        uid: uid,
        displayName: prefs.getString('demo_name') ?? 'Demo User',
        email: prefs.getString('demo_email') ?? 'demo@shadowsentinel.io',
        photoUrl: null,
        role: UserRole.values.firstWhere(
          (r) => r.name == (prefs.getString('demo_role') ?? 'admin'),
          orElse: () => UserRole.admin,
        ),
        lastLogin:
            DateTime.tryParse(prefs.getString('demo_lastLogin') ?? '') ??
            DateTime.now(),
        isDemo: true,
      );
    } catch (_) {}
  }

  Future<void> _clearDemoSession() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('demo_uid');
    prefs.remove('demo_name');
    prefs.remove('demo_email');
    prefs.remove('demo_role');
    prefs.remove('demo_lastLogin');
  }

  // ────────────────────────────────────────────────────────
  // Helpers
  // ────────────────────────────────────────────────────────

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password must be at least 6 characters';
      case 'invalid-email':
        return 'Invalid email address';
      case 'too-many-requests':
        return 'Too many attempts — try again later';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled';
      default:
        return 'Authentication error ($code)';
    }
  }

  // ── Cleanup ──────────────────────────────────────────────

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
