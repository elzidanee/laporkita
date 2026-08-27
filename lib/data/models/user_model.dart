// STATUS: VERIFIED — dari backend/src/modules/auth/auth.service.ts (AuthTokens interface)
// user.role enum: citizen | operator | admin | policy_maker

enum UserRole {
  citizen,
  operator,
  admin,
  policyMaker;

  static UserRole fromString(String value) {
    switch (value) {
      case 'operator':
        return UserRole.operator;
      case 'admin':
        return UserRole.admin;
      case 'policy_maker':
        return UserRole.policyMaker;
      default:
        return UserRole.citizen;
    }
  }

  bool get isCommandCenter =>
      this == UserRole.operator ||
      this == UserRole.admin ||
      this == UserRole.policyMaker;
}

class UserModel {
  final String id;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final UserRole role;
  final String? agencyId;
  final int contributionPoints;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.fullName,
    this.email,
    this.phoneNumber,
    required this.role,
    this.agencyId,
    required this.contributionPoints,
    this.avatarUrl,
  });

  // STATUS: VERIFIED — field names dari auth.service.ts generateTokens()
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? json['name']?.toString() ?? 'Warga',
      email: json['email']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      role: UserRole.fromString(json['role']?.toString() ?? 'citizen'),
      agencyId: json['agency_id']?.toString(),
      contributionPoints: (json['contribution_points'] as num?)?.toInt() ?? 0,
      avatarUrl: json['avatar_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'phone_number': phoneNumber,
        'role': role.name,
        'agency_id': agencyId,
        'contribution_points': contributionPoints,
        'avatar_url': avatarUrl,
      };

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    UserRole? role,
    String? agencyId,
    int? contributionPoints,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      agencyId: agencyId ?? this.agencyId,
      contributionPoints: contributionPoints ?? this.contributionPoints,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
