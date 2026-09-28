import 'package:flutter/material.dart';

import '../models/salon.dart';
import '../models/service.dart';
import '../services/api_service.dart';

import 'booking_screen.dart';

class SalonDetailsScreen extends StatefulWidget {
  final Salon salon;

  const SalonDetailsScreen({super.key, required this.salon});

  @override
  State<SalonDetailsScreen> createState() => _SalonDetailsScreenState();
}

class _SalonDetailsScreenState extends State<SalonDetailsScreen> {
  final ApiService _apiService = ApiService();

  List<Service> _services = [];
  bool _isLoading = true;
  String? _error;

  final Color primaryColor = const Color(0xFF7568F5);

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      final services = await _apiService.getServices();

      if (!mounted) return;

      setState(() {
        _services = services
            .where(
              (service) =>
                  service.salonId == widget.salon.id && service.isActive,
            )
            .toList();

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (remainingMinutes == 0) {
      return '${hours} h';
    }

    return '${hours} h ${remainingMinutes} min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF7568F5),
            size: 20,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'eTermin',
          style: TextStyle(
            color: Color(0xFF7568F5),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================
            // SLIKA SALONA
            // ==========================

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                _getSalonImage(),
                width: double.infinity,
                height: 145,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return _buildImagePlaceholder();
                },
              ),
            ),

            const SizedBox(height: 8),

            // ==========================
            // NAZIV
            // ==========================
            Text(
              widget.salon.name,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 2),

            // ==========================
            // LOKACIJA
            // ==========================
            Row(
              children: [
                const Text('📍', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 3),
                Text(
                  widget.salon.city,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 2),

            // Za sada prikazujemo fiksnu vrijednost
            // dok backend nema rating podatak.
            const Text(
              '⭐ 4.8',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),

            const SizedBox(height: 14),

            // ==========================
            // USLUGE
            // ==========================
            const Text(
              'Usluge:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 8),

            _buildServices(),
          ],
        ),
      ),

      // ==========================
      // BOTTOM NAVIGATION
      // ==========================
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildServices() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(25),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F1FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'Greška pri učitavanju usluga:\n$_error',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }

    if (_services.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F1FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Ovaj salon trenutno nema dostupnih usluga.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: _services.map((service) {
        return _buildServiceCard(service);
      }).toList(),
    );
  }

  Widget _buildServiceCard(Service service) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Row(
        children: [
          // IKONA
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F1FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getServiceIcon(service.name),
              color: primaryColor,
              size: 25,
            ),
          ),

          const SizedBox(width: 10),

          // NAZIV + TRAJANJE
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7568F5),
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  'Trajanje: ${_formatDuration(service.durationInMinutes)}',
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                ),
              ],
            ),
          ),

          // CIJENA + REZERVIŠI
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${service.price.toStringAsFixed(0)} KM',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7568F5),
                ),
              ),

              const SizedBox(height: 3),

              SizedBox(
                height: 23,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingScreen(
                          salon: widget.salon,
                          service: service,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: const Text('Rezerviši', style: TextStyle(fontSize: 9)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getServiceIcon(String name) {
    final lowerName = name.toLowerCase();

    if (lowerName.contains('nok')) {
      return Icons.back_hand_outlined;
    }

    if (lowerName.contains('šiš') || lowerName.contains('sis')) {
      return Icons.content_cut;
    }

    if (lowerName.contains('farb')) {
      return Icons.brush_outlined;
    }

    if (lowerName.contains('lice')) {
      return Icons.face_retouching_natural;
    }

    if (lowerName.contains('masa')) {
      return Icons.spa_outlined;
    }

    return Icons.spa_outlined;
  }

  String _getSalonImage() {
    switch (widget.salon.name.toLowerCase()) {
      case 'bella':
        return 'assets/images/beauty.jpg';

      case 'glow beauty':
        return 'assets/images/glow_beauty.jpg';

      case 'belle studio':
        return 'assets/images/belle.jpg';

      default:
        return 'assets/images/elegance_beauty.jpg';
    }
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 145,
      color: const Color(0xFFF1ECF8),
      child: const Center(
        child: Icon(
          Icons.storefront_rounded,
          color: Color(0xFF9C27B0),
          size: 50,
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E0EA))),
      ),
      child: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF7568F5),
        unselectedItemColor: const Color(0xFF7568F5),
        selectedFontSize: 9,
        unselectedFontSize: 9,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
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
      ),
    );
  }
}
