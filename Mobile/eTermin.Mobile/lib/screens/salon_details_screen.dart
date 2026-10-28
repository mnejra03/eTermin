import 'package:flutter/material.dart';

import '../models/salon.dart';
import '../models/service.dart';
import '../services/api_service.dart';

import 'booking_screen.dart';
import '../widgets/salon_image.dart';

class SalonDetailsScreen extends StatefulWidget {
  final Salon salon;
  final ValueChanged<int> onNavigateToTab;

  const SalonDetailsScreen({
    super.key,
    required this.salon,
    required this.onNavigateToTab,
  });

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
      return '$hours h';
    }

    return '$hours h $remainingMinutes min';
  }

  @override
  Widget build(BuildContext context) {
    final location = [
      widget.salon.address.trim(),
      widget.salon.city.trim(),
    ].where((part) => part.isNotEmpty).join(', ');

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
              child: SalonImageView(
                imageUrl: widget.salon.imageUrl,
                width: double.infinity,
                height: 145,
                fit: BoxFit.cover,
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F5FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryColor.withValues(alpha: 0.12)),
              ),
              child: Column(
                children: [
                  _salonInfoRow(
                    Icons.location_on_outlined,
                    'Adresa',
                    location.isEmpty ? 'Adresa nije dostupna' : location,
                  ),
                  if (widget.salon.phoneNumber.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _salonInfoRow(
                      Icons.phone_outlined,
                      'Telefon',
                      widget.salon.phoneNumber,
                    ),
                  ],
                  if (widget.salon.email.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _salonInfoRow(
                      Icons.email_outlined,
                      'Email',
                      widget.salon.email,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEAE7F2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF5D9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star_outline_rounded,
                      color: Color(0xFFE5A100),
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recenzije',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Jo\u0161 nema recenzija za ovaj salon.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            // USLUGE
            // ==========================
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Usluge',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF292638),
                    ),
                  ),
                ),
                if (!_isLoading && _error == null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F1FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_services.length} dostupnih',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
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

  Widget _salonInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: primaryColor, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAE7F2)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F1FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  _getServiceIcon(service.name),
                  color: primaryColor,
                  size: 23,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  service.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF292638),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${service.price.toStringAsFixed(2)} KM',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                'Trajanje: ${_formatDuration(service.durationInMinutes)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () async {
                  final completed = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingScreen(
                        salon: widget.salon,
                        service: service,
                        onNavigateToTab: widget.onNavigateToTab,
                      ),
                    ),
                  );
                  if (completed == true && mounted) {
                    Navigator.pop(context, true);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                icon: const Icon(Icons.calendar_month_rounded, size: 15),
                label: const Text('Rezervi\u0161i'),
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

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E0EA))),
      ),
      child: BottomNavigationBar(
        currentIndex: 0,
        onTap: widget.onNavigateToTab,
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
