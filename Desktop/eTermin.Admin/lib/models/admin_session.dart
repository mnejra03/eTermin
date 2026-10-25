class AdminSession {
  const AdminSession({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.token,
  });

  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final String token;

  factory AdminSession.fromJson(Map<String, dynamic> json) {
    return AdminSession(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
    );
  }
}
