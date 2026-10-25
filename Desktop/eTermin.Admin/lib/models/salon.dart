class Salon {
  const Salon({
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

  final int id;
  final String name;
  final String description;
  final String address;
  final String city;
  final String phoneNumber;
  final String email;
  final String imageUrl;
  final bool isActive;

  factory Salon.fromJson(Map<String, dynamic> json) => Salon(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    address: json['address']?.toString() ?? '',
    city: json['city']?.toString() ?? '',
    phoneNumber: json['phoneNumber']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    imageUrl: json['imageUrl']?.toString() ?? '',
    isActive: json['isActive'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'address': address,
    'city': city,
    'phoneNumber': phoneNumber,
    'email': email,
    'imageUrl': imageUrl,
    'isActive': isActive,
  };
}
