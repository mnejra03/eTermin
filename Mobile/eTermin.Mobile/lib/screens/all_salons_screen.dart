import 'package:flutter/material.dart';

import '../models/salon.dart';
import '../services/api_service.dart';
import 'salon_details_screen.dart';

class AllSalonsScreen extends StatefulWidget {
  const AllSalonsScreen({super.key});

  @override
  State<AllSalonsScreen> createState() => _AllSalonsScreenState();
}

class _AllSalonsScreenState extends State<AllSalonsScreen> {
  final ApiService _apiService = ApiService();

  List<Salon> _salons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSalons();
  }

  Future<void> _loadSalons() async {
    try {
      final salons = await _apiService.getSalons();

      if (!mounted) return;

      setState(() {
        _salons = salons.where((salon) => salon.isActive).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Svi saloni',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: _salons.length,
              itemBuilder: (context, index) {
                final salon = _salons[index];

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SalonDetailsScreen(salon: salon),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                _getSalonImage(salon),
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            salon.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '📍 ${salon.city}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            height: 30,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SalonDetailsScreen(salon: salon),
                                  ),
                                );
                              },
                              child: const Text(
                                'Pogledaj',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
