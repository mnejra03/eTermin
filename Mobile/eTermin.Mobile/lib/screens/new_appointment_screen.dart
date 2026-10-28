import 'package:flutter/material.dart';

import '../models/salon.dart';
import '../models/service.dart';
import '../services/api_service.dart';
import 'booking_screen.dart';

class NewAppointmentScreen extends StatefulWidget {
  const NewAppointmentScreen({required this.onNavigateToTab, super.key});

  final ValueChanged<int> onNavigateToTab;

  @override
  State<NewAppointmentScreen> createState() => _NewAppointmentScreenState();
}

class _NewAppointmentScreenState extends State<NewAppointmentScreen> {
  final ApiService _apiService = ApiService();

  List<Salon> _salons = [];
  List<Service> _services = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final salons = await _apiService.getSalons();
      final services = await _apiService.getServices();

      setState(() {
        _salons = salons.where((salon) => salon.isActive).toList();
        _services = services.where((service) => service.isActive).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Podaci se ne mogu učitati.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novi termin'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: widget.onNavigateToTab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF7568F5),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 9,
        unselectedFontSize: 9,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Po\u010Detna'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Pretra\u017Ei'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Termini'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
                  child: Text(_error!),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Odaberite salon',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    ..._salons.map((salon) {
                      final salonServices = _services
                          .where(
                            (service) => service.salonId == salon.id,
                          )
                          .toList();

                      if (salonServices.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                salon.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 12),

                              ...salonServices.map(
                                (service) {
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(service.name),
                                    subtitle: Text(
                                      '${service.durationInMinutes} min • '
                                      '${service.price.toStringAsFixed(2)} KM',
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              BookingScreen(
                                            salon: salon,
                                            service: service,
                                            onNavigateToTab: widget.onNavigateToTab,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
    );
  }
}