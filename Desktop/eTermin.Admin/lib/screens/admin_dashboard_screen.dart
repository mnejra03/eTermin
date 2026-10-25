import 'package:flutter/material.dart';

import '../models/admin_session.dart';
import '../models/dashboard_statistics.dart';
import '../services/admin_api_client.dart';
import '../services/dashboard_service.dart';
import 'appointments_screen.dart';
import 'catalog_screen.dart';
import 'notifications_screen.dart';
import 'reference_data_screen.dart';
import 'salons_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    required this.session,
    required this.apiClient,
    required this.dashboardService,
    required this.onLogout,
    super.key,
  });

  final AdminSession session;
  final AdminApiClient apiClient;
  final DashboardService dashboardService;
  final VoidCallback onLogout;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  late Future<DashboardStatistics> _todayStatistics;
  late Future<List<Map<String, dynamic>>> _todayAppointments;
  late Future<Map<String, dynamic>> _availableSlots;

  static const _sections = <({String title, IconData icon})>[
    (title: 'Pregled', icon: Icons.dashboard_outlined),
    (title: 'Saloni', icon: Icons.storefront_outlined),
    (title: 'Zaposlenici', icon: Icons.people_outline),
    (title: 'Usluge', icon: Icons.spa_outlined),
    (title: 'Šifarnici', icon: Icons.list_alt_outlined),
    (title: 'Termini', icon: Icons.calendar_month_outlined),
    (title: 'Statistika', icon: Icons.bar_chart_outlined),
    (title: 'Obavijesti', icon: Icons.notifications_outlined),
    (title: 'Postavke', icon: Icons.settings_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _reloadDashboard();
  }

  void _reloadDashboard() {
    _todayStatistics = widget.dashboardService.fetchToday(widget.session.token);
    _todayAppointments = widget.dashboardService.fetchTodayAppointments(
      widget.session.token,
    );
    _availableSlots = widget.dashboardService.fetchAvailableSlots(
      widget.session.token,
    );
  }

  @override
  Widget build(BuildContext context) {
    final section = _sections[_selectedIndex];
    final fullName = '${widget.session.firstName} ${widget.session.lastName}'
        .trim();

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() {
              _selectedIndex = index;
              if (index == 0) _reloadDashboard();
            }),
            leading: Padding(
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 24),
              child: Row(
                children: [
                  Icon(Icons.spa, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'eTermin',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            destinations: [
              for (final item in _sections)
                NavigationRailDestination(
                  icon: Icon(item.icon),
                  label: Text(item.title),
                ),
            ],
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton.icon(
                    onPressed: widget.onLogout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Odjava'),
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 8,
                  ),
                  title: Text(
                    section.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  subtitle: Text(
                    fullName.isEmpty ? widget.session.email : fullName,
                  ),
                  trailing: CircleAvatar(
                    child: Text(
                      widget.session.firstName.isNotEmpty
                          ? widget.session.firstName[0].toUpperCase()
                          : 'A',
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: switch (_selectedIndex) {
                    0 => _WelcomePanel(
                      firstName: widget.session.firstName,
                      email: widget.session.email,
                      statistics: _todayStatistics,
                      todayAppointments: _todayAppointments,
                      availableSlots: _availableSlots,
                      onRetry: () => setState(_reloadDashboard),
                    ),
                    1 => SalonsScreen(api: widget.apiClient),
                    2 => CatalogScreen(
                      api: widget.apiClient,
                      kind: CatalogKind.employees,
                    ),
                    3 => CatalogScreen(
                      api: widget.apiClient,
                      kind: CatalogKind.services,
                    ),
                    4 => ReferenceDataScreen(api: widget.apiClient),
                    5 => AppointmentsScreen(api: widget.apiClient),
                    6 => StatisticsScreen(api: widget.apiClient),
                    7 => NotificationsScreen(api: widget.apiClient),
                    8 => SettingsScreen(
                      api: widget.apiClient,
                      session: widget.session,
                    ),
                    _ => _ComingSoonPanel(section: section.title),
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel({
    required this.firstName,
    required this.email,
    required this.statistics,
    required this.todayAppointments,
    required this.availableSlots,
    required this.onRetry,
  });

  final String firstName;
  final String email;
  final Future<DashboardStatistics> statistics;
  final Future<List<Map<String, dynamic>>> todayAppointments;
  final Future<Map<String, dynamic>> availableSlots;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final greeting = switch (DateTime.now().hour) {
      < 12 => 'Dobro jutro',
      < 18 => 'Dobar dan',
      _ => 'Dobro veče',
    };

    return FutureBuilder<DashboardStatistics>(
      future: statistics,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Statistika se nije mogla učitati.'),
                const SizedBox(height: 8),
                Text(snapshot.error.toString()),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Pokušaj ponovo'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting${firstName.isEmpty ? '' : ', $firstName'}!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text('Pregled za danas · Prijavljeni ste kao $email.'),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _StatisticCard(
                    title: 'Termini danas',
                    value: '${stats.totalAppointments}',
                    icon: Icons.calendar_month_outlined,
                  ),
                  _StatisticCard(
                    title: 'Korisnici',
                    value: '${stats.totalUsers}',
                    icon: Icons.people_outline,
                  ),
                  _StatisticCard(
                    title: 'Saloni',
                    value: '${stats.totalSalons}',
                    icon: Icons.storefront_outlined,
                  ),
                  _StatisticCard(
                    title: 'Prihod danas',
                    value: '${stats.totalRevenue.toStringAsFixed(2)} KM',
                    icon: Icons.payments_outlined,
                  ),
                  _StatisticCard(
                    title: 'Najtraženija usluga',
                    value: stats.mostPopularService ?? 'Nema podataka',
                    detail: '${stats.mostPopularServiceCount} rezervacija',
                    icon: Icons.spa_outlined,
                  ),
                  _StatisticCard(
                    title: 'Najaktivniji salon',
                    value: stats.mostActiveSalon ?? 'Nema podataka',
                    detail: '${stats.mostActiveSalonCount} rezervacija',
                    icon: Icons.store_mall_directory_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FutureBuilder<Map<String, dynamic>>(
                future: availableSlots,
                builder: (context, slotsSnapshot) {
                  if (!slotsSnapshot.hasData) return const SizedBox.shrink();
                  final slots = slotsSnapshot.data!;
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.event_available_outlined),
                      title: const Text('Dostupnost termina danas'),
                      subtitle: Text(
                        '${slots['availableSlots'] ?? 0} slobodnih od ${slots['totalSlots'] ?? 0} termina',
                      ),
                      trailing: SizedBox(
                        width: 150,
                        child: LinearProgressIndicator(
                          value:
                              ((slots['percentage'] as num?)?.toDouble() ?? 0) /
                              100,
                          minHeight: 10,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: todayAppointments,
                builder: (context, appointmentsSnapshot) {
                  if (appointmentsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (appointmentsSnapshot.hasError) {
                    return Text(
                      'Današnje termine nije moguće učitati: ${appointmentsSnapshot.error}',
                    );
                  }
                  final appointments = appointmentsSnapshot.data ?? [];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Današnji termini',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          if (appointments.isEmpty)
                            const Text('Danas nema zakazanih termina.')
                          else
                            for (final appointment in appointments)
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.schedule),
                                title: Text(
                                  '${appointment['userName'] ?? ''} · ${appointment['serviceName'] ?? ''}',
                                ),
                                subtitle: Text(
                                  '${appointment['salonName'] ?? ''} · ${_appointmentTime(appointment['startTime'])} · ${appointment['status'] ?? ''}',
                                ),
                                trailing: Text(
                                  '${appointment['price'] ?? 0} KM',
                                ),
                              ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _appointmentTime(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return '—';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
    required this.title,
    required this.value,
    required this.icon,
    this.detail,
  });

  final String title;
  final String value;
  final String? detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 6),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (detail != null) ...[
                const SizedBox(height: 4),
                Text(detail!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ComingSoonPanel extends StatelessWidget {
  const _ComingSoonPanel({required this.section});

  final String section;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.construction_outlined,
            size: 44,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(section, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Ovaj modul je sljedeći na redu za prenos iz WPF-a.'),
        ],
      ),
    );
  }
}
