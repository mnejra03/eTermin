class Employee {
  final int id;
  final int salonId;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String position;
  final String workingHours;
  final bool isActive;
  final List<int> serviceIds;

  Employee({
    required this.id,
    required this.salonId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.position,
    required this.workingHours,
    required this.isActive,
    required this.serviceIds,
  });

  String get fullName => '$firstName $lastName';

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      salonId: json['salonId'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      position: json['position'] ?? '',
      workingHours: json['workingHours'] ?? '',
      isActive: json['isActive'] ?? false,
      serviceIds: (json['serviceIds'] as List<dynamic>? ?? [])
          .map((id) => id as int)
          .toList(),
    );
  }
}