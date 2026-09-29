import 'package:flutter/material.dart';

import '../models/salon.dart';
import '../models/service.dart';
import '../services/api_service.dart';

import 'salon_details_screen.dart';
import 'all_salons_screen.dart';

import '../models/employee.dart';

import 'booking_screen.dart';
import 'new_appointment_screen.dart';

import 'recommendations_screen.dart';

import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
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

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final ApiService _apiService = ApiService();

  List<Salon> _salons = [];
  List<Service> _services = [];
  List<Employee> _employees = [];

  List<Map<String, dynamic>> _myAppointments = [];
  bool _isLoadingAppointments = false;
  String? _appointmentsError;
  String _appointmentFilter = 'Aktivni';

  List<Map<String, dynamic>> _homeAvailableSlots = [];
  bool _isLoadingHomeSlots = true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isLoadingSalons = true;
  String? _salonsError;

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

    print('HOME INIT');

    _loadSalons();

    _loadMyAppointments();
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

  Future<void> _loadMyAppointments() async {
    setState(() {
      _isLoadingAppointments = true;
      _appointmentsError = null;
    });

    try {
      final appointments = await _apiService.getMyAppointments();

      if (!mounted) return;

      setState(() {
        _myAppointments = appointments;
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

    if (_salons.isEmpty) {
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
        itemCount: _salons.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final salon = _salons[index];

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
              child: Image.asset(
                _getSalonImage(salon),
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    color: const Color(0xFFF1ECF8),
                    child: const Center(
                      child: Icon(
                        Icons.storefront_rounded,
                        color: Color(0xFF9C27B0),
                        size: 35,
                      ),
                    ),
                  );
                },
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
            '📍 ${salon.city}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),

          const SizedBox(height: 6),

          SizedBox(
            width: double.infinity,
            height: 28,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SalonDetailsScreen(salon: salon),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              child: const Text('Pogledaj ›', style: TextStyle(fontSize: 10)),
            ),
          ),
        ],
      ),
    );
  }

  String _getSalonImage(Salon salon) {
    switch (salon.name.toLowerCase()) {
      case 'belle studio':
        return 'assets/images/belle.jpg';

      case 'glow beauty':
        return 'assets/images/glow_beauty.jpg';

      case 'beauty studio':
        return 'assets/images/beauty.jpg';

      case 'elegance beauty studio':
        return 'assets/images/elegance_beauty.jpg';

      default:
        return 'assets/images/elegance_beauty.jpg';
    }
  }

  Future<void> _loadSalons() async {
    try {
      final salons = await _apiService.getSalons();
      final services = await _apiService.getServices();
      final employees = await _apiService.getEmployees();

      if (!mounted) return;

      setState(() {
        _salons = salons.where((salon) => salon.isActive).toList();

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
                print(
                  'HOME SLOT: '
                  '${service.name} | '
                  '${employee.firstName} ${employee.lastName} | '
                  'employeeId=${employee.id} | '
                  '${slot['startTime']} - ${slot['endTime']}',
                );
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
                onPressed: () {},
                icon: Icon(
                  Icons.notifications_none_rounded,
                  color: primaryColor,
                  size: 27,
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
                const TextSpan(text: '👋', style: TextStyle(fontSize: 22)),
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
              border: Border.all(color: primaryColor.withOpacity(0.6)),
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
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // POPULAR SALONS
          _buildSectionHeader(
            'Popularni saloni',
            'Pogledaj sve',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AllSalonsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 9),

          _buildPopularSalons(),

          const SizedBox(height: 13),

          // RECOMMENDED SERVICES
          _buildSectionTitle('Preporučene usluge'),

          const SizedBox(height: 8),

          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._services.take(5).map((service) {
                  final salon = _salons.where(
                    (salon) => salon.id == service.salonId,
                  );

                  final salonName = salon.isNotEmpty ? salon.first.name : '';

                  return _buildServiceChip(
                    '${service.name} • $salonName',
                    onTap: () {
                      if (salon.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SalonDetailsScreen(salon: salon.first),
                          ),
                        );
                      }
                    },
                  );
                }),
              ],
            ),
          ),

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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingScreen(
                              salon: salon,
                              service: service,
                              initialDate: item['date'] as DateTime,
                              initialEmployeeId:
                                  (item['employee'] as Employee).id,
                            ),
                          ),
                        );
                      },
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NewAppointmentScreen(),
                      ),
                    );
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RecommendationsScreen(),
                      ),
                    );
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
              border: Border.all(color: primaryColor.withOpacity(0.15)),
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
  // SERVICE CHIP
  // ----------------------------------------------------------

  Widget _buildServiceChip(String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 7),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: primaryColor.withOpacity(0.55)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: darkText,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
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
        border: Border.all(color: primaryColor.withOpacity(0.55)),
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
                border: Border.all(color: primaryColor.withOpacity(0.6)),
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

            Text(
              'Saloni',
              style: TextStyle(
                color: darkText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

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
                                  color: primaryColor.withOpacity(0.25),
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(8),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    _getSalonImage(salon),
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
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          SalonDetailsScreen(salon: salon),
                                    ),
                                  );
                                },
                              ),
                            );
                          }),
                        ],

                        if (filteredServices.isNotEmpty) ...[
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
                                  color: primaryColor.withOpacity(0.25),
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
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          SalonDetailsScreen(salon: salon),
                                    ),
                                  );
                                },
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: lightPurple,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.calendar_month, color: primaryColor, size: 22),
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
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
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
    );
  }

  // ----------------------------------------------------------
  // PROFILE
  // ----------------------------------------------------------

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
            '${widget.firstName} ${widget.lastName}',
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
              border: Border.all(color: primaryColor.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.person_outline, color: primaryColor),
                  title: const Text('Ime i prezime'),
                  subtitle: Text('${widget.firstName} ${widget.lastName}'),
                ),

                const Divider(),

                ListTile(
                  leading: Icon(Icons.email_outlined, color: primaryColor),
                  title: const Text('Email'),
                  subtitle: Text(widget.email),
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
}