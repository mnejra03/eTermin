import 'dart:async';
import 'dart:math' as math;

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
import 'users_screen.dart';

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
  late AdminSession _session;
  int _selectedIndex = 0;
  int? _pendingCreateForSection;
  late Future<DashboardStatistics> _todayStatistics;
  late Future<DashboardStatistics> _weekStatistics;
  late Future<List<Map<String, dynamic>>> _todayAppointments;
  late Future<Map<String, dynamic>> _availableSlots;
  Timer? _notificationTimer;
  int _unreadNotificationCount = 0;

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Odjava'),
        content: const Text('Da li ste sigurni da se želite odjaviti?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Ne'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Da, odjavi me'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) widget.onLogout();
  }

  bool _loadingNotificationCount = false;

  static const _sections = <({String title, IconData icon})>[
    (title: 'Pregled', icon: Icons.dashboard_outlined),
    (title: 'Saloni', icon: Icons.storefront_outlined),
    (title: 'Zaposlenici', icon: Icons.people_outline),
    (title: 'Korisnici', icon: Icons.manage_accounts_outlined),
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
    _session = widget.session;
    _reloadDashboard();
    _refreshUnreadNotificationCount();
    _notificationTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshUnreadNotificationCount(),
    );
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshUnreadNotificationCount() async {
    if (_loadingNotificationCount) return;
    _loadingNotificationCount = true;
    try {
      final response = await widget.apiClient.getMap(
        'Notifications/my/unread-count',
      );
      if (!mounted) return;
      setState(() {
        _unreadNotificationCount =
            (response['unreadCount'] as num?)?.toInt() ?? 0;
      });
    } catch (_) {
      // A badge refresh failure should not block dashboard navigation.
    } finally {
      _loadingNotificationCount = false;
    }
  }

  void _reloadDashboard() {
    _todayStatistics = widget.dashboardService.fetchToday(_session.token);
    _weekStatistics = widget.dashboardService.fetchRecentWeek(_session.token);
    _todayAppointments = widget.dashboardService.fetchTodayAppointments(
      _session.token,
    );
    _availableSlots = widget.dashboardService.fetchAvailableSlots(
      _session.token,
    );
  }

  void _onProfileUpdated(AdminSession updatedSession) {
    setState(() => _session = updatedSession);
  }

  void _consumeCreateRequest(int sectionIndex) {
    if (_pendingCreateForSection != sectionIndex) return;
    setState(() => _pendingCreateForSection = null);
  }

  void _navigateFromQuickAction(int sectionIndex) {
    setState(() {
      _selectedIndex = sectionIndex;
      _pendingCreateForSection = const {1, 2, 4}.contains(sectionIndex)
          ? sectionIndex
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final section = _sections[_selectedIndex];
    final fullName = '${_session.firstName} ${_session.lastName}'.trim();

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
              for (var index = 0; index < _sections.length; index++)
                NavigationRailDestination(
                  icon: index == 8 && _unreadNotificationCount > 0
                      ? Badge(
                          label: Text('$_unreadNotificationCount'),
                          child: Icon(_sections[index].icon),
                        )
                      : Icon(_sections[index].icon),
                  label: Text(_sections[index].title),
                ),
            ],
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton.icon(
                    onPressed: _confirmLogout,
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
                  subtitle: Text(fullName.isEmpty ? _session.email : fullName),
                  trailing: CircleAvatar(
                    child: Text(
                      _session.firstName.isNotEmpty
                          ? _session.firstName[0].toUpperCase()
                          : 'A',
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: switch (_selectedIndex) {
                    0 => _WelcomePanel(
                      firstName: _session.firstName,
                      email: _session.email,
                      statistics: _todayStatistics,
                      weekStatistics: _weekStatistics,
                      todayAppointments: _todayAppointments,
                      availableSlots: _availableSlots,
                      onNavigate: _navigateFromQuickAction,
                      onRetry: () => setState(_reloadDashboard),
                    ),
                    1 => SalonsScreen(
                      api: widget.apiClient,
                      openCreateOnLoad: _pendingCreateForSection == 1,
                      onCreateRequestHandled: () => _consumeCreateRequest(1),
                    ),
                    2 => CatalogScreen(
                      api: widget.apiClient,
                      kind: CatalogKind.employees,
                      openCreateOnLoad: _pendingCreateForSection == 2,
                      onCreateRequestHandled: () => _consumeCreateRequest(2),
                    ),
                    3 => UsersScreen(api: widget.apiClient),
                    4 => CatalogScreen(
                      api: widget.apiClient,
                      kind: CatalogKind.services,
                      openCreateOnLoad: _pendingCreateForSection == 4,
                      onCreateRequestHandled: () => _consumeCreateRequest(4),
                    ),
                    5 => ReferenceDataScreen(api: widget.apiClient),
                    6 => AppointmentsScreen(api: widget.apiClient),
                    7 => StatisticsScreen(api: widget.apiClient),
                    8 => NotificationsScreen(api: widget.apiClient),
                    9 => SettingsScreen(
                      api: widget.apiClient,
                      session: _session,
                      onProfileUpdated: _onProfileUpdated,
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
    required this.weekStatistics,
    required this.todayAppointments,
    required this.availableSlots,
    required this.onNavigate,
    required this.onRetry,
  });

  final String firstName;
  final String email;
  final Future<DashboardStatistics> statistics;
  final Future<DashboardStatistics> weekStatistics;
  final Future<List<Map<String, dynamic>>> todayAppointments;
  final Future<Map<String, dynamic>> availableSlots;
  final ValueChanged<int> onNavigate;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
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
        final todayStats = snapshot.data!;
        return FutureBuilder<DashboardStatistics>(
          future: weekStatistics,
          builder: (context, weekSnapshot) {
            if (weekSnapshot.hasError) {
              return _DashboardLoadError(
                message:
                    'Sedmična statistika se nije mogla učitati: ${weekSnapshot.error}',
                onRetry: onRetry,
              );
            }
            if (!weekSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final weekStats = weekSnapshot.data!;
            return LayoutBuilder(
              builder: (context, constraints) {
                final sidebarWidth = constraints.maxWidth < 900 ? 210.0 : 258.0;
                final dashboard = SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 17,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF432A55), Color(0xFF8A5B91)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.18,
                              ),
                              foregroundColor: Colors.white,
                              child: Text(
                                firstName.isEmpty
                                    ? 'A'
                                    : firstName[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_greeting()}, ${firstName.isEmpty ? 'administratoru' : firstName}!',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    email,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.auto_awesome,
                              color: Colors.white70,
                              size: 27,
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Osvježi pregled',
                              onPressed: onRetry,
                              color: Colors.white,
                              icon: const Icon(Icons.refresh),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _StatisticCard(
                            title: 'Termini danas',
                            value: '${todayStats.totalAppointments}',
                            icon: Icons.calendar_month_outlined,
                            accent: const Color(0xFF6750A4),
                            width: 174,
                          ),
                          _StatisticCard(
                            title: 'Korisnici',
                            value: '${todayStats.totalUsers}',
                            icon: Icons.people_outline,
                            accent: const Color(0xFF258A78),
                            width: 174,
                          ),
                          _StatisticCard(
                            title: 'Saloni',
                            value: '${todayStats.totalSalons}',
                            icon: Icons.storefront_outlined,
                            accent: const Color(0xFFB46B35),
                            width: 174,
                          ),
                          _StatisticCard(
                            title: 'Prihod danas',
                            value:
                                '${todayStats.totalRevenue.toStringAsFixed(2)} KM',
                            icon: Icons.payments_outlined,
                            accent: const Color(0xFF3974B8),
                            width: 174,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, chartConstraints) {
                          final stacked = chartConstraints.maxWidth < 680;
                          final chartHeight = stacked ? 500.0 : 245.0;
                          final content = stacked
                              ? Column(
                                  children: [
                                    SizedBox(
                                      height: 243,
                                      child: _ReservationChart(
                                        data: weekStats.reservationsByDay,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    SizedBox(
                                      height: 243,
                                      child: _StatusChart(
                                        data: weekStats.reservationsByStatus,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: _ReservationChart(
                                        data: weekStats.reservationsByDay,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _StatusChart(
                                        data: weekStats.reservationsByStatus,
                                      ),
                                    ),
                                  ],
                                );
                          return SizedBox(height: chartHeight, child: content);
                        },
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _StatisticCard(
                            title: 'Najpopularnija usluga',
                            value:
                                weekStats.mostPopularService ?? 'Nema podataka',
                            detail:
                                '${weekStats.mostPopularServiceCount} rezervacija ove sedmice',
                            icon: Icons.spa_outlined,
                            accent: const Color(0xFFB14978),
                            width: 230,
                          ),
                          _StatisticCard(
                            title: 'Najaktivniji korisnik',
                            value: weekStats.mostActiveUser ?? 'Nema podataka',
                            detail:
                                '${weekStats.mostActiveUserCount} rezervacija ove sedmice',
                            icon: Icons.person_pin_circle_outlined,
                            accent: const Color(0xFF3974B8),
                            width: 230,
                          ),
                          _StatisticCard(
                            title: 'Najaktivniji salon',
                            value: weekStats.mostActiveSalon ?? 'Nema podataka',
                            detail:
                                '${weekStats.mostActiveSalonCount} rezervacija ove sedmice',
                            icon: Icons.store_mall_directory_outlined,
                            accent: const Color(0xFF66813F),
                            width: 230,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _TodayAppointmentsPanel(appointments: todayAppointments),
                    ],
                  ),
                );

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: dashboard),
                    const VerticalDivider(width: 1),
                    SizedBox(
                      width: sidebarWidth,
                      child: _DashboardQuickSidebar(
                        availableSlots: availableSlots,
                        onNavigate: onNavigate,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  String _greeting() => switch (DateTime.now().hour) {
    < 12 => 'Dobro jutro',
    < 18 => 'Dobar dan',
    _ => 'Dobro veče',
  };
}

class _DashboardQuickSidebar extends StatelessWidget {
  const _DashboardQuickSidebar({
    required this.availableSlots,
    required this.onNavigate,
  });

  final Future<Map<String, dynamic>> availableSlots;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFF1EEFF),
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Obavijesti',
                onPressed: () => onNavigate(8),
                icon: const Icon(
                  Icons.notifications_none,
                  color: Color(0xFF7468F7),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Postavke profila',
                onPressed: () => onNavigate(9),
                icon: const CircleAvatar(
                  radius: 19,
                  backgroundColor: Color(0xFFE0DCFF),
                  child: Icon(Icons.person, color: Color(0xFF7468F7)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 34),
          Text(
            'Brze akcije',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF6750A4),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _QuickActionButton(
            icon: Icons.add_circle_outline,
            label: 'Dodaj uslugu',
            onPressed: () => onNavigate(4),
          ),
          const SizedBox(height: 10),
          _QuickActionButton(
            icon: Icons.person_add_alt_1_outlined,
            label: 'Dodaj zaposlenika',
            onPressed: () => onNavigate(2),
          ),
          const SizedBox(height: 10),
          _QuickActionButton(
            icon: Icons.event_note_outlined,
            label: 'Pregled termina',
            onPressed: () => onNavigate(6),
          ),
          const SizedBox(height: 10),
          _QuickActionButton(
            icon: Icons.add_business_outlined,
            label: 'Dodaj salon',
            onPressed: () => onNavigate(1),
          ),
          const SizedBox(height: 28),
          FutureBuilder<Map<String, dynamic>>(
            future: availableSlots,
            builder: (context, snapshot) {
              final slots = snapshot.data ?? const <String, dynamic>{};
              final available = (slots['availableSlots'] as num?)?.toInt() ?? 0;
              final total = (slots['totalSlots'] as num?)?.toInt() ?? 0;
              final percent = ((slots['percentage'] as num?)?.toDouble() ?? 0)
                  .clamp(0, 100);
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 12,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Slobodni termini danas',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF6750A4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const LinearProgressIndicator(minHeight: 6)
                    else if (snapshot.hasError)
                      const Text('Dostupnost trenutno nije dostupna.')
                    else ...[
                      Text(
                        '$available / $total',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: const Color(0xFF7468F7),
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: percent / 100,
                          minHeight: 7,
                          color: const Color(0xFF7468F7),
                          backgroundColor: const Color(0xFFE5E2EC),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(30),
    elevation: 2,
    shadowColor: const Color(0x33000000),
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF7468F7), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF6750A4),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFAAA3D9)),
          ],
        ),
      ),
    ),
  );
}

class _DashboardLoadError extends StatelessWidget {
  const _DashboardLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
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

class _DashboardChartPanel extends StatelessWidget {
  const _DashboardChartPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE9E3EB)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF6750A4)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(child: child),
      ],
    ),
  );
}

class _ReservationChart extends StatelessWidget {
  const _ReservationChart({required this.data});

  final List<Map<String, dynamic>> data;

  @override
  Widget build(BuildContext context) {
    final counts = data
        .map((item) => (item['count'] as num? ?? 0).toInt())
        .toList();
    final labels = data.map((item) {
      final date = DateTime.tryParse(item['date']?.toString() ?? '');
      return date == null ? '' : '${date.day}.${date.month}';
    }).toList();
    final total = counts.fold<int>(0, (sum, count) => sum + count);

    return _DashboardChartPanel(
      title: 'Rezervacije po danima',
      subtitle: 'Posljednjih 7 dana · ukupno $total',
      icon: Icons.show_chart,
      child: data.isEmpty
          ? const Center(child: Text('Nema podataka za ovaj period.'))
          : Column(
              children: [
                Expanded(
                  child: CustomPaint(
                    painter: _ReservationLinePainter(counts),
                    child: const SizedBox.expand(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (var i = 0; i < labels.length; i++)
                      Expanded(
                        child: Text(
                          labels[i],
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _ReservationLinePainter extends CustomPainter {
  const _ReservationLinePainter(this.values);

  final List<int> values;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 12.0;
    const right = 12.0;
    const top = 14.0;
    const bottom = 10.0;
    final width = size.width - left - right;
    final height = size.height - top - bottom;
    final gridPaint = Paint()
      ..color = const Color(0xFFECE8EF)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = top + height * i / 3;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
    }
    if (values.isEmpty) return;
    final maxValue = values.fold<int>(
      1,
      (max, value) => value > max ? value : max,
    );
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : left + width * i / (values.length - 1);
      final y = top + height - height * values[i] / maxValue;
      points.add(Offset(x, y));
    }
    final fillPath = Path()..moveTo(points.first.dx, top + height);
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
      fillPath.lineTo(point.dx, point.dy);
    }
    fillPath
      ..lineTo(points.last.dx, top + height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x336750A4), Color(0x006750A4)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, top, size.width, height)),
    );
    canvas.drawPath(
      linePath,
      Paint()
        ..color = const Color(0xFF6750A4)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 5, Paint()..color = Colors.white);
      canvas.drawCircle(
        points[i],
        4,
        Paint()
          ..color = const Color(0xFF6750A4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ReservationLinePainter oldDelegate) =>
      oldDelegate.values != values;
}

class _StatusChart extends StatelessWidget {
  const _StatusChart({required this.data});

  final List<Map<String, dynamic>> data;

  static const _colors = <String, Color>{
    'Pending': Color(0xFFE99A24),
    'Confirmed': Color(0xFF3978C5),
    'Completed': Color(0xFF32936F),
    'Cancelled': Color(0xFFD65B5B),
  };

  String _label(String value) => switch (value) {
    'Pending' => 'Na čekanju',
    'Confirmed' => 'Potvrđeni',
    'Completed' => 'Završeni',
    'Cancelled' => 'Otkazani',
    _ => value,
  };

  @override
  Widget build(BuildContext context) {
    final entries = data
        .map(
          (item) => MapEntry(
            item['status']?.toString() ?? '',
            (item['count'] as num? ?? 0).toInt(),
          ),
        )
        .where((entry) => entry.value > 0)
        .toList();
    final total = entries.fold<int>(0, (sum, entry) => sum + entry.value);

    return _DashboardChartPanel(
      title: 'Statusi rezervacija',
      subtitle: 'Raspodjela za posljednjih 7 dana',
      icon: Icons.donut_small_outlined,
      child: total == 0
          ? const Center(child: Text('Nema podataka za ovaj period.'))
          : Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Center(
                    child: SizedBox(
                      width: 170,
                      height: 170,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size.square(170),
                            painter: _StatusDonutPainter(entries),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$total',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const Text(
                                'rezervacija',
                                style: TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final entry in entries)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _colors[entry.key] ?? Colors.blueGrey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _label(entry.key),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${entry.value}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _StatusDonutPainter extends CustomPainter {
  const _StatusDonutPainter(this.entries);

  final List<MapEntry<String, int>> entries;

  @override
  void paint(Canvas canvas, Size size) {
    final total = entries.fold<int>(0, (sum, entry) => sum + entry.value);
    if (total == 0) return;
    final rect = Offset.zero & size;
    var startAngle = -math.pi / 2;
    for (final entry in entries) {
      final sweep = entry.value / total * math.pi * 2;
      canvas.drawArc(
        rect,
        startAngle,
        sweep,
        false,
        Paint()
          ..color = _StatusChart._colors[entry.key] ?? Colors.blueGrey
          ..style = PaintingStyle.stroke
          ..strokeWidth = 24
          ..strokeCap = StrokeCap.butt,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _StatusDonutPainter oldDelegate) =>
      oldDelegate.entries != entries;
}

class _TodayAppointmentsPanel extends StatelessWidget {
  const _TodayAppointmentsPanel({required this.appointments});

  final Future<List<Map<String, dynamic>>> appointments;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE9E3EB)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.today_outlined, color: Color(0xFF6750A4)),
            const SizedBox(width: 10),
            Text(
              'Današnji termini',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: appointments,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Text(
                'Današnje termine nije moguće učitati: ${snapshot.error}',
              );
            }
            final rows = snapshot.data ?? [];
            if (rows.isEmpty)
              return const Text('Danas nema zakazanih termina.');
            return Column(
              children: [
                const _AppointmentHeaderRow(),
                for (final appointment in rows)
                  _TodayAppointmentTile(appointment: appointment),
              ],
            );
          },
        ),
      ],
    ),
  );
}

class _AppointmentHeaderRow extends StatelessWidget {
  const _AppointmentHeaderRow();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
    child: Row(
      children: [
        Expanded(flex: 3, child: Text('Korisnik')),
        Expanded(flex: 3, child: Text('Usluga')),
        Expanded(flex: 3, child: Text('Salon')),
        Expanded(flex: 2, child: Text('Vrijeme')),
        Expanded(flex: 2, child: Text('Status')),
      ],
    ),
  );
}

class _TodayAppointmentTile extends StatelessWidget {
  const _TodayAppointmentTile({required this.appointment});

  final Map<String, dynamic> appointment;

  @override
  Widget build(BuildContext context) {
    final status = (appointment['status'] ?? '').toString();
    final color = switch (status.toLowerCase()) {
      'confirmed' => const Color(0xFF258A78),
      'completed' => const Color(0xFF3974B8),
      'cancelled' => const Color(0xFFB34D4D),
      _ => const Color(0xFFB46B35),
    };
    final start = DateTime.tryParse(appointment['startTime']?.toString() ?? '')
        ?.toLocal();
    final time = start == null
        ? '—'
        : '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final statusLabel = switch (status) {
      'Pending' => 'Na čekanju',
      'Confirmed' => 'Potvrđen',
      'Completed' => 'Završen',
      'Cancelled' => 'Otkazan',
      _ => status,
    };

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              appointment['userName']?.toString() ?? '—',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              appointment['serviceName']?.toString() ?? '—',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              appointment['salonName']?.toString() ?? '—',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              time,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  statusLabel,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
    required this.title,
    required this.value,
    required this.icon,
    this.detail,
    required this.accent,
    this.width = 260,
  });

  final String title;
  final String value;
  final String? detail;
  final IconData icon;
  final Color accent;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accent.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.07),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent),
                ),
                const Spacer(),
                Icon(Icons.north_east, size: 17, color: accent),
              ],
            ),
            const SizedBox(height: 18),
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
