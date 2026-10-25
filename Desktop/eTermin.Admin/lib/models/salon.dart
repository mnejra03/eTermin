class Salon {
  const Salon({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.cityId,
    required this.cityName,
    required this.phoneNumber,
    required this.email,
    required this.employeeCount,
    required this.imageUrl,
    required this.images,
    required this.isActive,
  });

  final int id;
  final String name;
  final String description;
  final String address;
  final int cityId;
  final String cityName;
  final String phoneNumber;
  final String email;
  final int employeeCount;
  final String imageUrl;
  final List<Map<String, dynamic>> images;
  final bool isActive;

  factory Salon.fromJson(Map<String, dynamic> json) => Salon(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    address: json['address']?.toString() ?? '',
    cityId: (json['cityId'] as num?)?.toInt() ?? 0,
    cityName: json['cityName']?.toString() ?? '',
    phoneNumber: json['phoneNumber']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    employeeCount: (json['employeeCount'] as num?)?.toInt() ?? 0,
    imageUrl:
        json['imageUrl']?.toString() ??
        ((json['images'] as List?)?.firstOrNull
                as Map<String, dynamic>?)?['imageUrl']
            ?.toString() ??
        '',
    images: ((json['images'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList(),
    isActive: json['isActive'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'address': address,
    'cityId': cityId,
    'cityName': cityName,
    'phoneNumber': phoneNumber,
    'email': email,
    'imageUrl': imageUrl,
    'images': images,
    'isActive': isActive,
  };
}
