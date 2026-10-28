import 'dart:async';

import 'package:flutter/material.dart';

import '../models/salon.dart';
import '../models/service.dart';
import '../models/recommendation.dart';
import '../services/api_service.dart';
import '../services/app_route_observer.dart';

import 'salon_details_screen.dart';
import 'all_salons_screen.dart';

import '../models/employee.dart';

import 'booking_screen.dart';
import 'payment_screen.dart';
import 'new_appointment_screen.dart';

import 'recommendations_screen.dart';

import 'login_screen.dart';
import 'appointment_details_screen.dart';

import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'notifications_screen.dart';
import '../widgets/salon_image.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  final String firstName;
  final String email;
  final String token;
  final String lastName;

  const HomeScreen({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.token,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  int _selectedIndex = 0;

  final ApiService _apiService = ApiService();
  bool _hasUnreadNotifications = false;
  Timer? _notificationTimer;
  bool _checkingNotifications = false;

  List<Salon> _salons = [];
  List<Salon> _popularSalons = [];
  List<Service> _services = [];
  List<Recommendation> _recommendations = [];
  List<Employee> _employees = [];

  List<Map<String, dynamic>> _myAppointments = [];
  bool _isLoadingAppointments = false;
  String? _appointmentsError;
  String _appointmentFilter = 'Aktivni';
  int _appointmentsPage = 1;
  int _appointmentsTotalPages = 1;
  final Set<int> _payingAppointmentIds = {};

  List<Map<String, dynamic>> _homeAvailableSlots = [];
  bool _isLoadingHomeSlots = true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isLoadingSalons = true;
  bool _isLoadingRecommendations = true;
  String? _salonsError;
  late String _profileFirstName;
  late String _profileLastName;
  late String _profileEmail;

  final Color primaryColor = const Color(0xFF7568F5);
  final Color lightPurple = const Color(0xFFF3F1FF);
  final Color darkText = const Color(0xFF292638);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHome(),
            _buildSearch(),
            _buildAppointments(),
            _buildProfile(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  @override
  void initState() {
    super.initState();

    _profileFirstName = widget.firstName;
    _profileLastName = widget.lastName;
    _profileEmail = widget.email;

    _loadSalons();
    _loadRecommendations();

    _loadMyAppointments();

    _checkUnreadNotifications();
    _notificationTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkUnreadNotifications(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    _loadMyAppointments();
    _loadRecommendations();
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _notificationTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _getNextAppointment() {
    final now = DateTime.now();

    final upcoming = _myAppointments.where((appointment) {
      final status = appointment['status']?.toString() ?? '';

      if (status != 'Pending' && status != 'Confirmed') {
        return false;
      }

      final startTime = DateTime.tryParse(
        appointment['startTime']?.toString() ?? '',
      );

      return startTime != null && startTime.isAfter(now);
    }).toList();

    upcoming.sort((a, b) {
      final dateA = DateTime.parse(a['startTime'].toString());
      final dateB = DateTime.parse(b['startTime'].toString());

      return dateA.compareTo(dateB);
    });

    return upcoming.isEmpty ? null : upcoming.first;
  }

  Future<void> _loadMyAppointments({int page = 1}) async {
    if (!mounted) return;
    setState(() {
      _isLoadingAppointments = true;
      _appointmentsError = null;
    });

    try {
      final status = switch (_appointmentFilter) {
        'Završeni' => 'Completed',
        'Otkazani' => 'Cancelled',
        _ => 'Active',
      };
      final result = await _apiService.getMyAppointmentsPage(
        page: page,
        status: status,
      );

      if (!mounted) return;

      setState(() {
        _myAppointments = result.items;
        _appointmentsPage = result.page;
        _appointmentsTotalPages = result.totalPages;
        _isLoadingAppointments = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _appointmentsError = e.toString();
        _isLoadingAppointments = false;
      });
    }
  }

  Future<void> _loadRecommendations() async {
    try {
      final recommendations = await _apiService.getMyRecommendations();
      if (!mounted) return;
      setState(() {
        _recommendations = recommendations;
        _isLoadingRecommendations = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recommendations = [];
        _isLoadingRecommendations = false;
      });
    }
  }

  Future<void> _openAppointmentDetails(Map<String, dynamic> appointment) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AppointmentDetailsScreen(appointment: appointment),
      ),
    );
  }

  void _showMyAppointmentsAfterPayment() {
    if (!mounted) return;
    setState(() => _selectedIndex = 2);
    _loadMyAppointments();
  }

  void _navigateToTab(int index) {
    Navigator.of(context)
        .popUntil((route) => route.settings.name == HomeScreen.routeName);
    if (!mounted) return;
    setState(() => _selectedIndex = index);
    if (index == 2) _loadMyAppointments();
  }

  Future<bool?> _openBooking({
    required Salon salon,
    required Service service,
    DateTime? initialDate,
    int? initialEmployeeId,
  }) async {
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(
          salon: salon,
          service: service,
          initialDate: initialDate,
          initialEmployeeId: initialEmployeeId,
          onNavigateToTab: _navigateToTab,
        ),
      ),
    );
    if (completed == true) _showMyAppointmentsAfterPayment();
    return completed;
  }

  Future<bool?> _openSalonDetails(Salon salon) async {
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SalonDetailsScreen(salon: salon, onNavigateToTab: _navigateToTab),
      ),
    );
    if (completed == true) _showMyAppointmentsAfterPayment();
    return completed;
  }

  Future<void> _payAppointment(Map<String, dynamic> appointment) async {
    final appointmentId = appointment['id'];
    final salonId = appointment['salonId'];
    final serviceId = appointment['serviceId'];
    final startTime = DateTime.tryParse(
      appointment['startTime']?.toString() ?? '',
    )?.toLocal();

    if (appointmentId is! int ||
        salonId is! int ||
        serviceId is! int ||
        startTime == null ||
        appointment['status'] != 'Pending' ||
        appointment['isPaid'] == true) {
      return;
    }

    setState(() => _payingAppointmentIds.add(appointmentId));

    try {
      var salon = _firstOrNull(_salons.where((item) => item.id == salonId));
      var service = _firstOrNull(
        _services.where((item) => item.id == serviceId),
      );

      if (salon == null || service == null) {
        final salons = await _apiService.getSalons();
        final services = await _apiService.getServices();
        salon ??= _firstOrNull(salons.where((item) => item.id == salonId));
        service ??= _firstOrNull(
          services.where((item) => item.id == serviceId),
        );
      }

      if (salon == null || service == null) {
        throw Exception('Podaci o salonu ili usluzi nisu dostupni.');
      }

      final payments = await _apiService.getPaymentsForAppointment(
        appointmentId,
      );
      if (payments.any((payment) => payment['status'] == 'Completed')) {
        await _loadMyAppointments();
        if (mounted) _message('Ovaj termin je već plaćen.');
        return;
      }

      final pendingPayment = _firstOrNull(
        payments.where((payment) => payment['status'] == 'Pending'),
      );
      final paymentId = pendingPayment == null
          ? await _apiService.createPayment(
              appointmentId: appointmentId,
              amount:
                  (appointment['price'] as num?)?.toDouble() ?? service.price,
              paymentMethod: 'PayPal',
            )
          : pendingPayment['id'] as int;

      final order = await _apiService.createPayPalOrder(paymentId: paymentId);
      final approvalUrl = order['approvalUrl']?.toString();
      if (approvalUrl == null || approvalUrl.isEmpty) {
        throw Exception('PayPal nije vratio link za plaćanje.');
      }

      final timeText =
          '${startTime.hour.toString().padLeft(2, '0')}:'
          '${startTime.minute.toString().padLeft(2, '0')}';

      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            salon: salon!,
            service: service!,
            selectedDate: startTime,
            selectedTime: timeText,
            appointmentId: appointmentId,
            paymentId: paymentId,
            approvalUrl: approvalUrl,
          ),
        ),
      );

      if (!mounted) return;
      await _loadMyAppointments();
    } catch (error) {
      if (mounted) _message('Plaćanje nije pokrenuto: $error');
    } finally {
      if (mounted) setState(() => _payingAppointmentIds.remove(appointmentId));
    }
  }

  T? _firstOrNull<T>(Iterable<T> values) =>
      values.isEmpty ? null : values.first;

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Widget _buildPopularSalons() {
    if (_isLoadingSalons) {
      return const SizedBox(
        height: 145,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_salonsError != null) {
      return const SizedBox(
        height: 145,
        child: Center(
          child: Text(
            'Saloni trenutno nisu dostupni.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    if (_popularSalons.isEmpty) {
      return const SizedBox(
        height: 145,
        child: Center(
          child: Text(
            'Nema dostupnih salona.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return SizedBox(
      height: 145,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _popularSalons.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final salon = _popularSalons[index];

          return _buildSalonCard(salon);
        },
      ),
    );
  }

  Widget _buildSalonCard(Salon salon) {
    return Container(
      width: 165,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF9C8CFF), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SalonImageView(
                imageUrl: salon.imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(height: 5),

          Text(
            salon.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),

          Text(
            '\u{1F4CD} ${salon.city}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),

          const SizedBox(height: 6),

          SizedBox(
            width: double.infinity,
            height: 28,
            child: ElevatedButton(
              onPressed: () => _openSalonDetails(salon),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Pogledaj', style: TextStyle(fontSize: 10)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSalons() async {
    try {
      final salons = await _apiService.getSalons();
      final popularSalons = await _apiService.getPopularSalons();
      final services = await _apiService.getServices();
      final employees = await _apiService.getEmployees();

      if (!mounted) return;

      setState(() {
        _salons = salons.where((salon) => salon.isActive).toList();
        _popularSalons = popularSalons;

        _services = services.where((service) => service.isActive).toList();

        _employees = employees.where((employee) => employee.isActive).toList();

        _isLoadingSalons = false;
      });

      try {
        final slots = await _loadHomeAvailableSlots();

        if (!mounted) return;

        setState(() {
          _homeAvailableSlots = slots.take(5).toList();
          _isLoadingHomeSlots = false;
        });
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _isLoadingHomeSlots = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _salonsError = e.toString();
        _isLoadingSalons = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadHomeAvailableSlots() async {
    final result = <Map<String, dynamic>>[];
    final today = DateTime.now();

    // Tražimo termine za narednih 7 dana.
    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final date = DateTime(
        today.year,
        today.month,
        today.day,
      ).add(Duration(days: dayOffset));

      for (final service in _services) {
        final employees = _employees
            .where(
              (employee) =>
                  employee.salonId == service.salonId &&
                  employee.serviceIds.contains(service.id) &&
                  employee.isActive,
            )
            .toList();

        // Provjeri svakog zaposlenika koji pruža tu uslugu.
        for (final employee in employees) {
          try {
            final slots = await _apiService.getAvailableSlots(
              salonId: service.salonId,
              employeeId: employee.id,
              serviceId: service.id,
              date: date,
            );

            for (final slot in slots) {
              if (slot['isAvailable'] == true) {
                result.add({
                  'slot': slot,
                  'service': service,
                  'employee': employee,
                  'date': date,
                });

                // Dovoljno je nekoliko termina za Home ekran.
                if (result.length >= 5) {
                  return result;
                }
              }
            }
          } catch (_) {
            // Ako jedan zaposlenik/termin ne uspije,
            // nastavljamo provjeravati ostale.
            continue;
          }
        }
      }
    }

    return result;
  }

  // ----------------------------------------------------------
  // HOME
  // ----------------------------------------------------------

  Widget _buildHome() {
    final nextAppointment = _getNextAppointment();
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'eTermin',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              IconButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );

                  _checkUnreadNotifications();
                },
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      color: primaryColor,
                      size: 27,
                    ),

                    if (_hasUnreadNotifications)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // GREETING
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Pozdrav, ${widget.firstName} ',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const TextSpan(text: '\u2728', style: TextStyle(fontSize: 22)),
              ],
            ),
          ),

          const SizedBox(height: 2),

          Text(
            'Rezerviši svoj termin brzo i jednostavno',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),

          const SizedBox(height: 20),

          // SEARCH
          Container(
            height: 42,
            decoration: BoxDecoration(
              border: Border.all(color: primaryColor.withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(9),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              onSubmitted: (value) {
                setState(() {
                  _selectedIndex = 1;
                });
              },
              decoration: InputDecoration(
                hintText: 'Pretraži salon ili uslugu...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: primaryColor, size: 19),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 42,
                  minHeight: 40,
                ),
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              textAlignVertical: TextAlignVertical.center,
            ),
          ),

          const SizedBox(height: 20),

          // POPULAR SALONS
          _buildSectionHeader(
            'Popularni saloni',
            'Pogledaj sve',
            onTap: () async {
              final completed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AllSalonsScreen(onNavigateToTab: _navigateToTab),
                ),
              );
              if (completed == true) _showMyAppointmentsAfterPayment();
            },
          ),
          const SizedBox(height: 9),

          _buildPopularSalons(),

          const SizedBox(height: 13),

          // RECOMMENDED SERVICES
          _buildSectionTitle('Preporučene usluge'),

          const SizedBox(height: 8),

          _buildRecommendedServices(),

          const SizedBox(height: 15),

          // FREE APPOINTMENTS
          _buildSectionTitle('Slobodni termini'),

          const SizedBox(height: 8),

          SizedBox(
            height: 72,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _homeAvailableSlots.take(5).map((item) {
                    final slot = item['slot'] as Map<String, dynamic>;
                    final service = item['service'] as Service;

                    final salon = _salons.firstWhere(
                      (salon) => salon.id == service.salonId,
                    );

                    final startTime = DateTime.parse(
                      slot['startTime'].toString(),
                    );

                    final time =
                        '${startTime.hour.toString().padLeft(2, '0')}:'
                        '${startTime.minute.toString().padLeft(2, '0')}';

                    return GestureDetector(
                      onTap: () => _openBooking(
                        salon: salon,
                        service: service,
                        initialDate: item['date'] as DateTime,
                        initialEmployeeId: (item['employee'] as Employee).id,
                      ),
                      child: _buildAvailableSlot(
                        time,
                        service.name,
                        salon.name,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // QUICK ACTIONS
          _buildSectionTitle('Brze radnje'),

          const SizedBox(height: 9),

          Row(
            children: [
              Expanded(
                child: _buildQuickAction(
                  Icons.calendar_today,
                  'Novi termin',
                  onTap: () async {
                    final completed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewAppointmentScreen(
                          onNavigateToTab: _navigateToTab,
                        ),
                      ),
                    );
                    if (completed == true) {
                      _showMyAppointmentsAfterPayment();
                    }
                  },
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _buildQuickAction(
                  Icons.calendar_today_outlined,
                  'Moji termini',
                  onTap: () {
                    setState(() {
                      _selectedIndex = 2;
                    });
                  },
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _buildQuickAction(
                  Icons.star_border_rounded,
                  'Preporuke',
                  onTap: () async {
                    final completed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecommendationsScreen(
                          onNavigateToTab: _navigateToTab,
                        ),
                      ),
                    );
                    if (completed == true) {
                      _showMyAppointmentsAfterPayment();
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // NEXT APPOINTMENT
          _buildSectionTitle('Sljedeći termin'),

          const SizedBox(height: 8),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: lightPurple,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryColor.withValues(alpha: 0.15)),
            ),
            child: nextAppointment == null
                ? const Text(
                    'Trenutno nemate zakazanih termina.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_month,
                                color: primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 7),
                              const Text(
                                'Sljedeći termin',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),

                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                nextAppointment['salonName']?.toString() ??
                                    'Salon',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Text(
                        '${nextAppointment['serviceName'] ?? 'Usluga'} - '
                        '${_formatNextAppointmentDate(nextAppointment['startTime'])}',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedServices() {
    if (_isLoadingRecommendations) {
      return const SizedBox(
        height: 176,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_recommendations.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F5FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: primaryColor.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(Icons.auto_awesome_outlined, color: primaryColor),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Preporuke za vas će se pojaviti čim pronađemo usluge koje vam odgovaraju.',
                style: TextStyle(fontSize: 13, height: 1.35),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 184,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _recommendations.length,
        padding: const EdgeInsets.only(right: 4, bottom: 5),
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final recommendation = _recommendations[index];
          final salon = _salons.where(
            (item) => item.id == recommendation.salonId,
          );
          return SizedBox(
            width: 278,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: salon.isEmpty
                    ? null
                    : () async {
                        await _openBooking(
                          salon: salon.first,
                          service: recommendation.toService(),
                        );
                        if (mounted) _loadRecommendations();
                      },
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF8F6FF), Color(0xFFEDEAFF)],
                    ),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 14,
                                    color: primaryColor,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'ZA VAS',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${recommendation.price.toStringAsFixed(0)} KM',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 11),
                        Text(
                          recommendation.serviceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: darkText,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(
                              Icons.storefront_outlined,
                              size: 15,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                recommendation.salonName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            recommendation.reason,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'Rezervi\u0161i termin',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: primaryColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatNextAppointmentDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');

    if (date == null) {
      return '';
    }

    final today = DateTime.now();

    final isToday =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;

    final time =
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';

    if (isToday) {
      return 'danas u $time';
    }

    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}. u $time';
  }

  // ----------------------------------------------------------
  // SECTION HEADER
  // ----------------------------------------------------------

  Widget _buildSectionHeader(
    String title,
    String action, {
    VoidCallback? onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: darkText,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style: TextStyle(color: primaryColor, fontSize: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: darkText,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // ----------------------------------------------------------
  // AVAILABLE SLOT
  // ----------------------------------------------------------

  Widget _buildAvailableSlot(String time, String service, String salon) {
    return Container(
      width: 125,
      margin: const EdgeInsets.only(right: 7),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryColor.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 18,
            color: Colors.red.shade400,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                Text(
                  service,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9),
                ),
                Text(
                  salon,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // QUICK ACTION
  // ----------------------------------------------------------
  Widget _buildQuickAction(IconData icon, String title, {VoidCallback? onTap}) {
    return SizedBox(
      height: 38,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14),
        label: Text(title, style: const TextStyle(fontSize: 9)),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // SMALL BUTTON
  // ----------------------------------------------------------

  Widget _smallActionButton(String text, IconData icon) {
    return SizedBox(
      height: 27,
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 11),
        label: Text(text, style: const TextStyle(fontSize: 8)),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // SEARCH
  // ----------------------------------------------------------

  Widget _buildSearch() {
    final filteredSalons = _salons.where((salon) {
      final query = _searchQuery.toLowerCase().trim();

      if (query.isEmpty) {
        return true;
      }

      return salon.name.toLowerCase().contains(query) ||
          salon.city.toLowerCase().contains(query) ||
          salon.address.toLowerCase().contains(query);
    }).toList();

    final filteredServices = _services.where((service) {
      final query = _searchQuery.toLowerCase().trim();

      if (query.isEmpty) {
        return true;
      }

      return service.name.toLowerCase().contains(query) ||
          service.description.toLowerCase().contains(query);
    }).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pretraži',
              style: TextStyle(
                color: primaryColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Container(
              height: 45,
              decoration: BoxDecoration(
                border: Border.all(color: primaryColor.withValues(alpha: 0.6)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Pretraži salon...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(Icons.search, color: primaryColor, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: (filteredSalons.isEmpty && filteredServices.isEmpty)
                  ? Center(
                      child: Text(
                        'Nema rezultata pretrage.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView(
                      children: [
                        if (filteredSalons.isNotEmpty) ...[
                          Text(
                            'Saloni',
                            style: TextStyle(
                              color: darkText,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),

                          ...filteredSalons.map((salon) {
                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: primaryColor.withValues(alpha: 0.25),
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(8),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SalonImageView(
                                    imageUrl: salon.imageUrl,
                                    width: 65,
                                    height: 65,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                title: Text(
                                  salon.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  '${salon.city}, ${salon.address}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 15,
                                  color: primaryColor,
                                ),
                                onTap: () => _openSalonDetails(salon),
                              ),
                            );
                          }),
                        ],

                        if (filteredServices.isNotEmpty) ...[
                          if (filteredSalons.isNotEmpty)
                            const SizedBox(height: 10),

                          Text(
                            'Usluge',
                            style: TextStyle(
                              color: darkText,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          ...filteredServices.map((service) {
                            final salon = _salons.firstWhere(
                              (s) => s.id == service.salonId,
                            );

                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: primaryColor.withValues(alpha: 0.25),
                                ),
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 45,
                                  height: 45,
                                  decoration: BoxDecoration(
                                    color: lightPurple,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.spa_outlined,
                                    color: primaryColor,
                                  ),
                                ),
                                title: Text(
                                  service.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  '${salon.name} • ${service.price.toStringAsFixed(0)} KM',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 15,
                                  color: primaryColor,
                                ),
                                onTap: () => _openSalonDetails(salon),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // APPOINTMENTS
  // ----------------------------------------------------------

  Widget _buildAppointments() {
    List<Map<String, dynamic>> filteredAppointments;

    if (_appointmentFilter == 'Aktivni') {
      filteredAppointments = _myAppointments.where((appointment) {
        final status = appointment['status']?.toString() ?? '';
        return status == 'Pending' || status == 'Confirmed';
      }).toList();
    } else if (_appointmentFilter == 'Završeni') {
      filteredAppointments = _myAppointments.where((appointment) {
        return appointment['status']?.toString() == 'Completed';
      }).toList();
    } else {
      filteredAppointments = _myAppointments.where((appointment) {
        return appointment['status']?.toString() == 'Cancelled';
      }).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Moji termini',
            style: TextStyle(
              color: darkText,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // FILTERI
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildAppointmentFilter('Aktivni'),
              _buildAppointmentFilter('Završeni'),
              _buildAppointmentFilter('Otkazani'),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: lightPurple,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 17,
                  color: Color(0xFF7568F5),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Termini na \u010dekanju nalaze se u kartici Aktivni. Nepla\u0107eni termin mo\u017ee\u0161 platiti odatle.',
                    style: TextStyle(fontSize: 11, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        Expanded(
          child: _isLoadingAppointments
              ? const Center(child: CircularProgressIndicator())
              : _appointmentsError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Termini se trenutno ne mogu učitati.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : filteredAppointments.isEmpty
              ? Center(
                  child: Text(
                    'Nema termina u kategoriji "$_appointmentFilter".',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  itemCount: filteredAppointments.length,
                  itemBuilder: (context, index) {
                    final appointment = filteredAppointments[index];

                    return _buildAppointmentCard(appointment);
                  },
                ),
        ),
        if (_appointmentsError == null && !_isLoadingAppointments)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Prethodna stranica',
                  onPressed: _appointmentsPage <= 1
                      ? null
                      : () => _loadMyAppointments(page: _appointmentsPage - 1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('$_appointmentsPage / $_appointmentsTotalPages'),
                IconButton(
                  tooltip: 'Sljedeća stranica',
                  onPressed: _appointmentsPage >= _appointmentsTotalPages
                      ? null
                      : () => _loadMyAppointments(page: _appointmentsPage + 1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAppointmentFilter(String title) {
    final isSelected = _appointmentFilter == title;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _appointmentFilter = title;
          });
          _loadMyAppointments();
        },
        child: Container(
          margin: const EdgeInsets.only(right: 5),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : lightPurple,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : primaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final serviceName = appointment['serviceName']?.toString() ?? 'Usluga';

    final salonName = appointment['salonName']?.toString() ?? 'Salon';

    final status = appointment['status']?.toString() ?? '';
    final isPaid = appointment['isPaid'] == true;
    final cancellationReason =
        appointment['cancellationReason']?.toString().trim() ?? '';

    final startTime = DateTime.tryParse(
      appointment['startTime']?.toString() ?? '',
    );

    String dateText = '';

    if (startTime != null) {
      dateText =
          '${startTime.day.toString().padLeft(2, '0')}.'
          '${startTime.month.toString().padLeft(2, '0')}.'
          '${startTime.year}. u '
          '${startTime.hour.toString().padLeft(2, '0')}:'
          '${startTime.minute.toString().padLeft(2, '0')}';
    }

    Color statusColor;
    String statusText;

    switch (status) {
      case 'Confirmed':
        statusColor = Colors.green;
        statusText = 'Potvrđeno';
        break;

      case 'Pending':
        statusColor = Colors.orange;
        statusText = 'Na čekanju';
        break;

      case 'Completed':
        statusColor = Colors.blueGrey;
        statusText = 'Završeno';
        break;

      case 'Cancelled':
        statusColor = Colors.red;
        statusText = 'Otkazano';
        break;

      default:
        statusColor = Colors.grey;
        statusText = status;
    }

    return InkWell(
      onTap: () => _openAppointmentDetails(appointment),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: lightPurple,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calendar_month,
                    color: primaryColor,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$serviceName - $salonName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        dateText,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPaid ? Icons.check_circle : Icons.pending_outlined,
                    size: 16,
                    color: isPaid ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isPaid ? 'Plaćeno' : 'Nije plaćeno',
                    style: TextStyle(
                      color: isPaid ? Colors.green : Colors.orange.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (status == 'Cancelled' && cancellationReason.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2F1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF4D2CF)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFB5473C),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Razlog otkazivanja',
                            style: TextStyle(
                              color: Color(0xFF8E352D),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            cancellationReason,
                            style: const TextStyle(
                              color: Color(0xFF5F3835),
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (status == 'Pending' || status == 'Confirmed')
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 4,
                  children: [
                    if (status == 'Pending' && !isPaid)
                      FilledButton.tonalIcon(
                        onPressed:
                            _payingAppointmentIds.contains(appointment['id'])
                            ? null
                            : () => _payAppointment(appointment),
                        icon: _payingAppointmentIds.contains(appointment['id'])
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.payment),
                        label: const Text('Plati putem PayPal-a'),
                      ),
                    if (isPaid)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Plaćeni termin se ne može otkazati.'),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // PROFILE
  // ----------------------------------------------------------

  Future<void> _editProfile() async {
    final profile = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          firstName: _profileFirstName,
          lastName: _profileLastName,
          email: _profileEmail,
        ),
      ),
    );
    if (!mounted || profile == null) return;
    setState(() {
      _profileFirstName = profile['firstName']!;
      _profileLastName = profile['lastName']!;
      _profileEmail = profile['email']!;
    });
  }

  Widget _buildProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 25),

          CircleAvatar(
            radius: 45,
            backgroundColor: lightPurple,
            child: Icon(Icons.person, size: 50, color: primaryColor),
          ),

          const SizedBox(height: 15),

          Text(
            '$_profileFirstName $_profileLastName',
            style: TextStyle(
              color: primaryColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 30),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryColor.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.person_outline, color: primaryColor),
                  title: const Text('Ime i prezime'),
                  subtitle: Text('$_profileFirstName $_profileLastName'),
                ),

                const Divider(),

                ListTile(
                  leading: Icon(Icons.email_outlined, color: primaryColor),
                  title: const Text('Email'),
                  subtitle: Text(_profileEmail),
                ),

                const Divider(),

                ListTile(
                  leading: Icon(Icons.edit_outlined, color: primaryColor),
                  title: const Text('Izmijeni profil'),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: primaryColor,
                  ),
                  onTap: _editProfile,
                ),

                const Divider(),

                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: Icon(Icons.lock_outline, color: primaryColor),
                    title: const Text('Promijeni lozinku'),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: primaryColor,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _confirmLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Odjava'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // BOTTOM NAVIGATION
  // ----------------------------------------------------------

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
        if (index == 2) _loadMyAppointments();
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
      selectedFontSize: 9,
      unselectedFontSize: 9,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded),
          label: 'Početna',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Pretraži'),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_outlined),
          label: 'Termini',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profil',
        ),
      ],
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Odjava'),
          content: const Text('Da li ste sigurni da se želite odjaviti?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Otkaži'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Odjavi se'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !mounted) {
      return;
    }

    _apiService.logout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _checkUnreadNotifications() async {
    if (_checkingNotifications) return;
    _checkingNotifications = true;
    try {
      final unreadCount = await _apiService.getMyUnreadNotificationCount();

      if (!mounted) return;

      setState(() {
        _hasUnreadNotifications = unreadCount > 0;
      });
    } catch (_) {
      // Badge refresh failures should not interrupt other home-screen actions.
    } finally {
      _checkingNotifications = false;
    }
  }
}
