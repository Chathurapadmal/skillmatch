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

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final String? companyName;
  final bool emailVerified;
  final bool twoFactorEnabled;
  final bool profileCompleted;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? totpSecret;
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

  bool get isAdmin => role == UserRole.admin;
  bool get isCompany => role == UserRole.company;
  bool get isApplicant => role == UserRole.applicant;
}
