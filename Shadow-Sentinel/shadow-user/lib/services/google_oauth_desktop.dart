import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Result from a successful Google OAuth2 desktop flow.
class GoogleOAuthResult {
  final String idToken;
  final String accessToken;

  const GoogleOAuthResult({required this.idToken, required this.accessToken});
}

/// Handles Google OAuth2 authorization code flow for Windows desktop.
///
/// Since the `google_sign_in` plugin does not support Windows natively,
/// this class implements the full OAuth2 flow manually:
///
/// 1. Generates a PKCE code verifier + challenge
/// 2. Opens Google's OAuth2 consent page in the system browser
/// 3. Starts a local HTTP server on `localhost:8734` to catch the redirect
/// 4. Exchanges the authorization code for tokens
/// 5. Returns [GoogleOAuthResult] with `idToken` and `accessToken`
///
/// These tokens can then be used to sign in to Firebase Auth via
/// `GoogleAuthProvider.credential(idToken:, accessToken:)`.
class GoogleOAuthDesktop {
  // ── OAuth2 Configuration ────────────────────────────────
  final String clientId;
  final String clientSecret;
  static const int _port = 8734;
  static const String _redirectUri = 'http://localhost:$_port';
  static const List<String> _scopes = ['openid', 'email', 'profile'];

  GoogleOAuthDesktop({required this.clientId, required this.clientSecret});

  // ────────────────────────────────────────────────────────
  // Public API
  // ────────────────────────────────────────────────────────

  /// Runs the full OAuth2 authorization code flow.
  /// Returns a [GoogleOAuthResult] on success.
  /// Throws on cancellation or errors.
  Future<GoogleOAuthResult> signIn() async {
    // 1) Generate PKCE values
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);

    // 2) Build the authorization URL
    final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
      'client_id': clientId,
      'redirect_uri': _redirectUri,
      'response_type': 'code',
      'scope': _scopes.join(' '),
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      'access_type': 'offline',
      'prompt': 'consent',
    });

    // 3) Start local server to receive the redirect
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, _port);
    debugPrint('[GoogleOAuth] Listening on $_redirectUri');

    // 4) Open the browser
    if (await canLaunchUrl(authUrl)) {
      await launchUrl(authUrl, mode: LaunchMode.externalApplication);
    } else {
      server.close();
      throw Exception('Could not launch browser for Google Sign-In');
    }

    // 5) Wait for the redirect (with timeout)
    String? authCode;
    String? error;

    try {
      final request = await server.first.timeout(
        const Duration(minutes: 3),
        onTimeout: () => throw TimeoutException('Sign-in timed out'),
      );

      final params = request.uri.queryParameters;
      authCode = params['code'];
      error = params['error'];

      // Send a nice response to the browser
      request.response
        ..statusCode = 200
        ..headers.set('Content-Type', 'text/html; charset=utf-8')
        ..write(_successHtml);
      await request.response.close();
    } catch (e) {
      debugPrint('[GoogleOAuth] Error receiving redirect: $e');
      rethrow;
    } finally {
      await server.close();
    }

    if (error != null) {
      throw Exception('Google sign-in was denied: $error');
    }

    if (authCode == null) {
      throw Exception('No authorization code received');
    }

    // 6) Exchange auth code for tokens
    return _exchangeCodeForTokens(authCode, codeVerifier);
  }

  // ────────────────────────────────────────────────────────
  // Token Exchange
  // ────────────────────────────────────────────────────────

  Future<GoogleOAuthResult> _exchangeCodeForTokens(
    String code,
    String codeVerifier,
  ) async {
    final client = HttpClient();

    try {
      final request = await client.postUrl(
        Uri.parse('https://oauth2.googleapis.com/token'),
      );

      request.headers.set('Content-Type', 'application/x-www-form-urlencoded');

      final body = Uri(
        queryParameters: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'code': code,
          'code_verifier': codeVerifier,
          'grant_type': 'authorization_code',
          'redirect_uri': _redirectUri,
        },
      ).query;

      request.write(body);

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw Exception(
          'Token exchange failed (${response.statusCode}): $responseBody',
        );
      }

      final data = json.decode(responseBody) as Map<String, dynamic>;

      final idToken = data['id_token'] as String?;
      final accessToken = data['access_token'] as String?;

      if (idToken == null || accessToken == null) {
        throw Exception('Missing tokens in response: $data');
      }

      debugPrint('[GoogleOAuth] Token exchange successful');

      return GoogleOAuthResult(idToken: idToken, accessToken: accessToken);
    } finally {
      client.close();
    }
  }

  // ────────────────────────────────────────────────────────
  // PKCE (Proof Key for Code Exchange)
  // ────────────────────────────────────────────────────────

  /// Generate a cryptographically random code verifier (43–128 chars).
  String _generateCodeVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  /// SHA-256 hash of the code verifier, base64url-encoded.
  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    // Using dart:io's built-in to avoid extra dependencies
    final digest = _sha256(bytes);
    return base64UrlEncode(digest).replaceAll('=', '');
  }

  /// Simple SHA-256 using dart:io's built-in support.
  List<int> _sha256(List<int> data) {
    // Use the system's crypto library
    final hash = _Sha256();
    hash.update(data);
    return hash.digest();
  }

  // ────────────────────────────────────────────────────────
  // Browser Response HTML
  // ────────────────────────────────────────────────────────

  static const String _successHtml = '''
<!DOCTYPE html>
<html>
<head>
  <title>Shadow Sentinel</title>
  <style>
    body {
      font-family: 'Segoe UI', system-ui, sans-serif;
      background: #0A0E17;
      color: #F1F5F9;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
    }
    .card {
      background: #111827;
      border: 1px solid #1E293B;
      border-radius: 16px;
      padding: 40px;
      text-align: center;
      max-width: 420px;
      box-shadow: 0 0 40px rgba(14, 165, 233, 0.1);
    }
    .shield { font-size: 48px; margin-bottom: 16px; }
    h1 { color: #0EA5E9; margin: 0 0 8px; font-size: 20px; letter-spacing: 2px; }
    p { color: #94A3B8; font-size: 14px; margin: 0; }
    .hint { margin-top: 16px; color: #64748B; font-size: 12px; }
  </style>
</head>
<body>
  <div class="card">
    <div class="shield">🛡️</div>
    <h1>AUTHENTICATION SUCCESSFUL</h1>
    <p>You've been authenticated with Google.</p>
    <p class="hint">You can close this tab and return to Shadow Sentinel.</p>
  </div>
  <script>setTimeout(() => window.close(), 3000);</script>
</body>
</html>
''';
}

// ─── Minimal SHA-256 Implementation ────────────────────────
// (avoids adding the `crypto` package just for one hash)

class _Sha256 {
  static const List<int> _k = [
    0x428a2f98,
    0x71374491,
    0xb5c0fbcf,
    0xe9b5dba5,
    0x3956c25b,
    0x59f111f1,
    0x923f82a4,
    0xab1c5ed5,
    0xd807aa98,
    0x12835b01,
    0x243185be,
    0x550c7dc3,
    0x72be5d74,
    0x80deb1fe,
    0x9bdc06a7,
    0xc19bf174,
    0xe49b69c1,
    0xefbe4786,
    0x0fc19dc6,
    0x240ca1cc,
    0x2de92c6f,
    0x4a7484aa,
    0x5cb0a9dc,
    0x76f988da,
    0x983e5152,
    0xa831c66d,
    0xb00327c8,
    0xbf597fc7,
    0xc6e00bf3,
    0xd5a79147,
    0x06ca6351,
    0x14292967,
    0x27b70a85,
    0x2e1b2138,
    0x4d2c6dfc,
    0x53380d13,
    0x650a7354,
    0x766a0abb,
    0x81c2c92e,
    0x92722c85,
    0xa2bfe8a1,
    0xa81a664b,
    0xc24b8b70,
    0xc76c51a3,
    0xd192e819,
    0xd6990624,
    0xf40e3585,
    0x106aa070,
    0x19a4c116,
    0x1e376c08,
    0x2748774c,
    0x34b0bcb5,
    0x391c0cb3,
    0x4ed8aa4a,
    0x5b9cca4f,
    0x682e6ff3,
    0x748f82ee,
    0x78a5636f,
    0x84c87814,
    0x8cc70208,
    0x90befffa,
    0xa4506ceb,
    0xbef9a3f7,
    0xc67178f2,
  ];

  final List<int> _h = [
    0x6a09e667,
    0xbb67ae85,
    0x3c6ef372,
    0xa54ff53a,
    0x510e527f,
    0x9b05688c,
    0x1f83d9ab,
    0x5be0cd19,
  ];

  final List<int> _buffer = [];
  int _totalLength = 0;

  void update(List<int> data) {
    _buffer.addAll(data);
    _totalLength += data.length;

    while (_buffer.length >= 64) {
      _processBlock(_buffer.sublist(0, 64));
      _buffer.removeRange(0, 64);
    }
  }

  List<int> digest() {
    // Padding
    final bitLength = _totalLength * 8;
    _buffer.add(0x80);
    while (_buffer.length % 64 != 56) {
      _buffer.add(0);
    }
    // Length in bits (big-endian, 64-bit)
    for (int i = 56; i >= 0; i -= 8) {
      _buffer.add((bitLength >> i) & 0xff);
    }

    while (_buffer.length >= 64) {
      _processBlock(_buffer.sublist(0, 64));
      _buffer.removeRange(0, 64);
    }

    final result = <int>[];
    for (final h in _h) {
      result.add((h >> 24) & 0xff);
      result.add((h >> 16) & 0xff);
      result.add((h >> 8) & 0xff);
      result.add(h & 0xff);
    }
    return result;
  }

  void _processBlock(List<int> block) {
    final w = List<int>.filled(64, 0);

    for (int i = 0; i < 16; i++) {
      w[i] =
          (block[i * 4] << 24) |
          (block[i * 4 + 1] << 16) |
          (block[i * 4 + 2] << 8) |
          block[i * 4 + 3];
    }

    for (int i = 16; i < 64; i++) {
      final s0 = _rotr(w[i - 15], 7) ^ _rotr(w[i - 15], 18) ^ (w[i - 15] >>> 3);
      final s1 = _rotr(w[i - 2], 17) ^ _rotr(w[i - 2], 19) ^ (w[i - 2] >>> 10);
      w[i] = _add32(w[i - 16], s0, w[i - 7], s1);
    }

    int a = _h[0], b = _h[1], c = _h[2], d = _h[3];
    int e = _h[4], f = _h[5], g = _h[6], h = _h[7];

    for (int i = 0; i < 64; i++) {
      final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
      final ch = (e & f) ^ ((~e) & g);
      final temp1 = _add32(h, s1, ch, _k[i], w[i]);
      final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
      final maj = (a & b) ^ (a & c) ^ (b & c);
      final temp2 = _add32(s0, maj);

      h = g;
      g = f;
      f = e;
      e = _add32(d, temp1);
      d = c;
      c = b;
      b = a;
      a = _add32(temp1, temp2);
    }

    _h[0] = _add32(_h[0], a);
    _h[1] = _add32(_h[1], b);
    _h[2] = _add32(_h[2], c);
    _h[3] = _add32(_h[3], d);
    _h[4] = _add32(_h[4], e);
    _h[5] = _add32(_h[5], f);
    _h[6] = _add32(_h[6], g);
    _h[7] = _add32(_h[7], h);
  }

  static int _rotr(int x, int n) => ((x >>> n) | (x << (32 - n))) & 0xffffffff;

  static int _add32(int a, int b, [int c = 0, int d = 0, int e = 0]) =>
      (a + b + c + d + e) & 0xffffffff;
}
