class DashboardStatistics {
  const DashboardStatistics({
    required this.totalAppointments,
    required this.totalUsers,
    required this.totalSalons,
    required this.totalRevenue,
    required this.mostPopularService,
    required this.mostPopularServiceCount,
    required this.mostActiveSalon,
    required this.mostActiveSalonCount,
  });

  final int totalAppointments;
  final int totalUsers;
  final int totalSalons;
  final double totalRevenue;
  final String? mostPopularService;
  final int mostPopularServiceCount;
  final String? mostActiveSalon;
  final int mostActiveSalonCount;

  factory DashboardStatistics.fromJson(Map<String, dynamic> json) {
    return DashboardStatistics(
      totalAppointments: (json['totalAppointments'] as num?)?.toInt() ?? 0,
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
      totalSalons: (json['totalSalons'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
      mostPopularService: json['mostPopularService']?.toString(),
      mostPopularServiceCount:
          (json['mostPopularServiceCount'] as num?)?.toInt() ?? 0,
      mostActiveSalon: json['mostActiveSalon']?.toString(),
      mostActiveSalonCount:
          (json['mostActiveSalonCount'] as num?)?.toInt() ?? 0,
    );
  }
}
