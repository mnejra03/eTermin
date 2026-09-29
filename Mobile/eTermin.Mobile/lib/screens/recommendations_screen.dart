import 'package:flutter/material.dart';

import '../models/salon.dart';
import '../models/service.dart';
import '../services/api_service.dart';
import 'booking_screen.dart';
import 'salon_details_screen.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() =>
      _RecommendationsScreenState();
}

class _RecommendationsScreenState
    extends State<RecommendationsScreen> {
  final ApiService _apiService = ApiService();

  List<Salon> _salons = [];
  List<Service> _services = [];
  List<Map<String, dynamic>> _appointments = [];

  List<Service> _recommendations = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
      final services = await _apiService.getServices();
      final salons = await _apiService.getSalons();
      final appointments = await _apiService.getMyAppointments();

      final activeServices =
          services.where((service) => service.isActive).toList();

      final usedServiceIds = appointments
          .map((appointment) => appointment['serviceId'])
          .whereType<int>()
          .toSet();

      final recommendations = activeServices
          .where((service) => !usedServiceIds.contains(service.id))
          .take(5)
          .toList();

      if (!mounted) return;

      setState(() {
        _services = activeServices;
        _salons = salons.where((salon) => salon.isActive).toList();
        _appointments = appointments;
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Preporuke se trenutno ne mogu učitati.';
        _isLoading = false;
      });
    }
  }

  Salon? _getSalonForService(Service service) {
    for (final salon in _salons) {
      if (salon.id == service.salonId) {
        return salon;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preporuke'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                  ),
                )
              : _recommendations.isEmpty
                  ? const Center(
                      child: Text(
                        'Trenutno nema novih preporuka.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text(
                          'Preporučeno za vas',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Na osnovu vaših prethodnih termina '
                          'predlažemo vam sljedeće usluge.',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 20),

                        ..._recommendations.map(
                          (service) {
                            final salon =
                                _getSalonForService(service);

                            return Card(
                              margin: const EdgeInsets.only(
                                bottom: 12,
                              ),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(
                                    Icons.star,
                                  ),
                                ),
                                title: Text(service.name),
                                subtitle: Text(
                                  '${salon?.name ?? 'Salon'} • '
                                  '${service.price.toStringAsFixed(2)} KM',
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                ),
                                onTap: salon == null
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                BookingScreen(
                                              salon: salon,
                                              service: service,
                                            ),
                                          ),
                                        );
                                      },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
    );
  }
}