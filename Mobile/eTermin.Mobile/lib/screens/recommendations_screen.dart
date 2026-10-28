import 'package:flutter/material.dart';

import '../models/recommendation.dart';
import '../models/salon.dart';
import '../services/api_service.dart';
import 'booking_screen.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({
    super.key,
    this.apiService,
    required this.onNavigateToTab,
  });

  final ApiService? apiService;
  final ValueChanged<int> onNavigateToTab;

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  late final ApiService _apiService = widget.apiService ?? ApiService();

  List<Salon> _salons = [];
  List<Recommendation> _recommendations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    if (!_isLoading && mounted) {
      setState(() => _isLoading = true);
    }
    try {
      final recommendations = await _apiService.getMyRecommendations();
      final salons = await _apiService.getSalons();
      if (!mounted) return;
      setState(() {
        _recommendations = recommendations;
        _salons = salons.where((salon) => salon.isActive).toList();
        _error = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _openRecommendation(Recommendation recommendation) async {
    final matchingSalons = _salons.where(
      (salon) => salon.id == recommendation.salonId,
    );
    if (matchingSalons.isEmpty) return;

    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(
          salon: matchingSalons.first,
          service: recommendation.toService(),
          onNavigateToTab: widget.onNavigateToTab,
        ),
      ),
    );
    if (!mounted) return;
    if (completed == true) {
      Navigator.pop(context, true);
      return;
    }
    await _loadRecommendations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preporuke')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _loadRecommendations,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Pokušaj ponovo'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadRecommendations,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Preporučeno za vas',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Prijedlozi su zasnovani na vašim prethodnim terminima.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  if (_recommendations.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'Trenutno nema novih preporuka.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ..._recommendations.map((recommendation) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.star)),
                        title: Text(recommendation.serviceName),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${recommendation.salonName} • '
                            '${recommendation.price.toStringAsFixed(2)} KM\n'
                            '${recommendation.reason}',
                          ),
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _openRecommendation(recommendation),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
