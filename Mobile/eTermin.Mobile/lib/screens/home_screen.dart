import 'package:flutter/material.dart';

import '../models/salon.dart';
import '../models/service.dart';
import '../services/api_service.dart';

import 'salon_details_screen.dart';
import 'all_salons_screen.dart';

import '../models/employee.dart';

import 'booking_screen.dart';

class HomeScreen extends StatefulWidget {
  final String firstName;
  final String token;

  const HomeScreen({super.key, required this.firstName, required this.token});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final ApiService _apiService = ApiService();

  List<Salon> _salons = [];
  List<Service> _services = [];
  List<Employee> _employees = [];

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
    _loadSalons();
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

    for (final service in _services) {
      final employees = _employees.where(
        (employee) =>
            employee.salonId == service.salonId &&
            employee.serviceIds.contains(service.id),
      );

      if (employees.isEmpty) {
        continue;
      }

      final slots = await _apiService.getAvailableSlots(
        salonId: service.salonId,
        employeeId: employees.first.id,
        serviceId: service.id,
        date: today,
      );

      for (final slot in slots) {
        if (slot['isAvailable'] == true) {
          result.add({
            'slot': slot,
            'service': service,
            'employee': employees.first,
          });
        }
      }
    }

    return result;
  }

  // ----------------------------------------------------------
  // HOME
  // ----------------------------------------------------------

  Widget _buildHome() {
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
                SizedBox(
                  height: 72,
                  child: _isLoadingHomeSlots
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : _homeAvailableSlots.isEmpty
                      ? const Center(
                          child: Text(
                            'Trenutno nema slobodnih termina.',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _homeAvailableSlots.length,
                          itemBuilder: (context, index) {
                            final item = _homeAvailableSlots[index];

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
                          },
                        ),
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
                  Icons.calendar_month_outlined,
                  'Novi termin',
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _buildQuickAction(
                  Icons.calendar_today_outlined,
                  'Moji termini',
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _buildQuickAction(
                  Icons.star_border_rounded,
                  'Preporuke',
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
            child: Column(
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
                          'Bella',
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
                  'Šišanje - danas u 14:00',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _smallActionButton('+ Novi termin', Icons.add),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _smallActionButton(
                        'Moji termini',
                        Icons.calendar_today,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _smallActionButton('Preporuke', Icons.star),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  Widget _buildQuickAction(IconData icon, String title) {
    return SizedBox(
      height: 38,
      child: ElevatedButton.icon(
        onPressed: () {},
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
    return Center(
      child: Text(
        'Moji termini',
        style: TextStyle(
          color: primaryColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // PROFILE
  // ----------------------------------------------------------

  Widget _buildProfile() {
    return Center(
      child: Text(
        'Profil',
        style: TextStyle(
          color: primaryColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
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
}
