class User {
  final int id;
  final String name;
  final String email;
  final String? mobile;
  final String role;
  final bool isVerified;
  final bool isBlocked;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.mobile,
    required this.role,
    this.isVerified = false,
    this.isBlocked = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      mobile: json['mobile'],
      role: json['role'],
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
      isBlocked: json['is_blocked'] == true || json['is_blocked'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'mobile': mobile,
      'role': role,
      'is_verified': isVerified,
      'is_blocked': isBlocked,
    };
  }

  bool get isCustomer => role == 'customer';
  bool get isProvider => role == 'provider';
  bool get isAdmin => role == 'admin';
}
