import 'package:flutter/material.dart';

import '../models/salon.dart';
import '../services/api_service.dart';
import 'salon_details_screen.dart';
import '../widgets/salon_image.dart';

class AllSalonsScreen extends StatefulWidget {
  const AllSalonsScreen({super.key});

  @override
  State<AllSalonsScreen> createState() => _AllSalonsScreenState();
}

class _AllSalonsScreenState extends State<AllSalonsScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  List<Salon> _salons = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _page = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadNextPageWhenVisible);
    _loadSalons();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadNextPageWhenVisible)
      ..dispose();
    super.dispose();
  }

  void _loadNextPageWhenVisible() {
    if (_scrollController.position.extentAfter < 400 &&
        !_isLoading &&
        !_isLoadingMore &&
        _page < _totalPages) {
      _loadSalons(page: _page + 1, append: true);
    }
  }

  Future<void> _loadSalons({int page = 1, bool append = false}) async {
    if (append) {
      _isLoadingMore = true;
    } else {
      _isLoading = true;
    }
    try {
      final result = await _apiService.getSalonsPage(page: page);

      if (!mounted) return;

      setState(() {
        final salons = result.items.where((salon) => salon.isActive).toList();
        _salons = append ? [..._salons, ...salons] : salons;
        _page = result.page;
        _totalPages = result.totalPages;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
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
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: _salons.length + (_page < _totalPages ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _salons.length) {
                  return const Center(child: CircularProgressIndicator());
                }
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
                              child: SalonImageView(
                                imageUrl: salon.imageUrl,
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
