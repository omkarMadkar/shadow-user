/// User roles for Shadow Sentinel.
enum UserRole {
  admin,
  analyst,
  viewer;

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.analyst:
        return 'ANALYST';
      case UserRole.viewer:
        return 'VIEWER';
    }
  }

  String get description {
    switch (this) {
      case UserRole.admin:
        return 'Full system access — manage users, configure modules, view all data';
      case UserRole.analyst:
        return 'View dashboards, analyse threats, review voice logs';
      case UserRole.viewer:
        return 'Read-only access to dashboards and reports';
    }
  }
}

/// Authenticated user profile.
class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final UserRole role;
  final DateTime lastLogin;
  final bool isDemo;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.role,
    required this.lastLogin,
    this.isDemo = false,
  });

  String get initials {
    final name = displayName.trim();
    if (name.isEmpty) return '??';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoUrl,
    UserRole? role,
    DateTime? lastLogin,
    bool? isDemo,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      lastLogin: lastLogin ?? this.lastLogin,
      isDemo: isDemo ?? this.isDemo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'role': role.name,
      'lastLogin': lastLogin.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] as String,
      displayName: map['displayName'] as String,
      email: map['email'] as String,
      photoUrl: map['photoUrl'] as String?,
      role: UserRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => UserRole.viewer,
      ),
      lastLogin: DateTime.parse(map['lastLogin'] as String),
    );
  }

  /// Demo user for when Firebase is not configured.
  static UserProfile demo() {
    return UserProfile(
      uid: 'demo-user',
      displayName: 'Demo User',
      email: 'demo@shadowsentinel.io',
      photoUrl: null,
      role: UserRole.admin,
      lastLogin: DateTime.now(),
      isDemo: true,
    );
  }
}
