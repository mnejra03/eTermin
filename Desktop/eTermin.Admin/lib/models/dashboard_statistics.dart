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
    required this.mostActiveUser,
    required this.mostActiveUserCount,
    required this.reservationsByDay,
    required this.reservationsByStatus,
  });

  final int totalAppointments;
  final int totalUsers;
  final int totalSalons;
  final double totalRevenue;
  final String? mostPopularService;
  final int mostPopularServiceCount;
  final String? mostActiveSalon;
  final int mostActiveSalonCount;
  final String? mostActiveUser;
  final int mostActiveUserCount;
  final List<Map<String, dynamic>> reservationsByDay;
  final List<Map<String, dynamic>> reservationsByStatus;

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
      mostActiveUser: json['mostActiveUser']?.toString(),
      mostActiveUserCount: (json['mostActiveUserCount'] as num?)?.toInt() ?? 0,
      reservationsByDay: (json['reservationsByDay'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList(),
      reservationsByStatus: (json['reservationsByStatus'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList(),
    );
  }
}
