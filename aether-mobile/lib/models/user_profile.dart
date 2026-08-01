// lib/models/user_profile.dart
//
// Backend /api/v1/users/profile endpoint'inden dönen response'u parse eder.
// UserProfileResponse { id, username, email, kycStatus, twoFaEnabled, createdAt }

class UserProfileModel {
  final String id;
  final String username;
  final String email;
  final String kycStatus;
  final bool twoFaEnabled;
  final String createdAt;

  const UserProfileModel({
    required this.id,
    required this.username,
    required this.email,
    required this.kycStatus,
    required this.twoFaEnabled,
    required this.createdAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) => UserProfileModel(
        id: (json['id'] as String?) ?? '',
        username: (json['username'] as String?) ?? '',
        email: (json['email'] as String?) ?? '',
        kycStatus: (json['kycStatus'] as String?) ?? 'PENDING',
        twoFaEnabled: (json['twoFaEnabled'] as bool?) ?? false,
        createdAt: (json['createdAt'] as String?) ?? '',
      );
}
