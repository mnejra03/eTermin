class Salon {
  final int id;
  final String name;
  final String description;
  final String address;
  final String city;
  final String phoneNumber;
  final String email;
  final int reservationCount;
  final String imageUrl;
  final bool isActive;

  Salon({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.city,
    required this.phoneNumber,
    required this.email,
    this.reservationCount = 0,
    required this.imageUrl,
    required this.isActive,
  });

  factory Salon.fromJson(Map<String, dynamic> json) {
    return Salon(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      city: json['cityName'] ?? json['city'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      reservationCount: (json['reservationCount'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      isActive: json['isActive'] ?? false,
    );
  }
}
