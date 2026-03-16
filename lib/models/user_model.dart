import 'package:cloud_firestore/cloud_firestore.dart';

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
  final String? companyName; // only for company role
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.companyName,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      role: roleFromString(data['role'] as String?),
      companyName: data['companyName'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': roleToString(role),
      if (companyName != null) 'companyName': companyName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isCompany => role == UserRole.company;
  bool get isApplicant => role == UserRole.applicant;
}
