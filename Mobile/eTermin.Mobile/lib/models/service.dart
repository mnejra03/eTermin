class Service {
  final int id;
  final int salonId;
  final String name;
  final String description;
  final int durationInMinutes;
  final double price;
  final bool isActive;

  Service({
    required this.id,
    required this.salonId,
    required this.name,
    required this.description,
    required this.durationInMinutes,
    required this.price,
    required this.isActive,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      salonId: json['salonId'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      durationInMinutes: json['durationInMinutes'] ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      isActive: json['isActive'] ?? false,
    );
  }
}
