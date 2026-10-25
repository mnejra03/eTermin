import 'service.dart';

class Recommendation {
  final int serviceId;
  final String serviceName;
  final String description;
  final int serviceCategoryId;
  final String serviceCategoryName;
  final int durationInMinutes;
  final double price;
  final int salonId;
  final String salonName;
  final String reason;

  const Recommendation({
    required this.serviceId,
    required this.serviceName,
    required this.description,
    required this.serviceCategoryId,
    required this.serviceCategoryName,
    required this.durationInMinutes,
    required this.price,
    required this.salonId,
    required this.salonName,
    required this.reason,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      serviceId: json['serviceId'] as int,
      serviceName: json['serviceName']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      serviceCategoryId: json['serviceCategoryId'] as int,
      serviceCategoryName: json['serviceCategoryName']?.toString() ?? '',
      durationInMinutes: json['durationInMinutes'] as int,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      salonId: json['salonId'] as int,
      salonName: json['salonName']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
    );
  }

  Service toService() => Service(
    id: serviceId,
    salonId: salonId,
    name: serviceName,
    description: description,
    durationInMinutes: durationInMinutes,
    price: price,
    isActive: true,
  );
}
