class Salon {
  final int id;
  final String name;
  final String description;
  final String address;
  final String city;
  final String phoneNumber;
  final String email;
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
    required this.imageUrl,
    required this.isActive,
  });

  factory Salon.fromJson(Map<String, dynamic> json) {
    return Salon(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      isActive: json['isActive'] ?? false,
    );
  }
}