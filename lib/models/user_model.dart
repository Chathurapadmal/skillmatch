import 'package:cloud_firestore/cloud_firestore.dart';

// ── Role enum ─────────────────────────────────────────────────────────────────

enum UserRole { applicant, company, admin }

UserRole roleFromString(String? value) {
  switch (value) {
    case 'company':
      return UserRole.company;
    case 'admin':
      return UserRole.admin;
    case 'applicant':
    default:
      return UserRole.applicant;
  }
}

String roleToString(UserRole role) {
  switch (role) {
    case UserRole.company:
      return 'company';
    case UserRole.admin:
      return 'admin';
    case UserRole.applicant:
      return 'applicant';
  }
}

// ── UserModel ─────────────────────────────────────────────────────────────────
//
// Firestore document: users/{uid}
//
//  displayName       String
//  email             String
//  role              String  ('applicant' | 'company' | 'admin')
//  companyName       String?
//  emailVerified     bool    (updated when user verifies email)
//  twoFactorEnabled  bool    (updated after 2FA setup)
//  profileCompleted  bool
//  createdAt         Timestamp
//  updatedAt         Timestamp
//
//  ⚠ SECURITY NOTE (production):
//  totpSecret and backupCodesHash are stored in Firestore for this demo.
//  In production, store totpSecret server-side only and never expose it
//  to the client after initial setup. Backup codes should be hashed
//  before storage (SHA-256).
//
//  totpSecret        String?       [DEMO ONLY – move to backend in production]
//  backupCodesHash   List<String>  [SHA-256 hashed backup codes]

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final String? companyName;

  /// Mirrors Firebase Auth emailVerified (stored in Firestore so it can be
  /// streamed and acted on without polling the Auth SDK repeatedly).
  final bool emailVerified;

  /// True once the user has completed TOTP 2FA setup.
  final bool twoFactorEnabled;

  /// True once the user has filled in their profile details.
  final bool profileCompleted;

  final DateTime createdAt;
  final DateTime? updatedAt;

  // ── 2FA fields (stored in Firestore; see security note above) ─────────────

  /// TOTP secret (BASE32). Stored here for demo; move to secure backend
  /// in production.
  // TODO (production): never store totpSecret on the client / in Firestore.
  final String? totpSecret;

  /// SHA-256 hashed backup recovery codes.
  final List<String> backupCodesHash;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.companyName,
    this.emailVerified = false,
    this.twoFactorEnabled = false,
    this.profileCompleted = false,
    required this.createdAt,
    this.updatedAt,
    this.totpSecret,
    this.backupCodesHash = const [],
  });

  // ── Firestore deserialiser ─────────────────────────────────────────────────

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      role: roleFromString(data['role'] as String?),
      companyName: data['companyName'] as String?,
      emailVerified: data['emailVerified'] as bool? ?? false,
      twoFactorEnabled: data['twoFactorEnabled'] as bool? ?? false,
      profileCompleted: data['profileCompleted'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      totpSecret: data['totpSecret'] as String?,
      backupCodesHash:
          (data['backupCodesHash'] as List?)?.cast<String>() ?? const [],
    );
  }

  // ── Firestore serialiser ───────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': roleToString(role),
      if (companyName != null) 'companyName': companyName,
      'emailVerified': emailVerified,
      'twoFactorEnabled': twoFactorEnabled,
      'profileCompleted': profileCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      if (totpSecret != null) 'totpSecret': totpSecret,
      if (backupCodesHash.isNotEmpty) 'backupCodesHash': backupCodesHash,
    };
  }

  // ── Convenience getters ────────────────────────────────────────────────────

  bool get isAdmin => role == UserRole.admin;
  bool get isCompany => role == UserRole.company;
  bool get isApplicant => role == UserRole.applicant;
}
