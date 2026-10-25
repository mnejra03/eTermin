import 'package:etermin_mobile/models/recommendation.dart';
import 'package:etermin_mobile/models/salon.dart';
import 'package:etermin_mobile/screens/recommendations_screen.dart';
import 'package:etermin_mobile/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders backend recommendation reasons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RecommendationsScreen(apiService: _RecommendationApi()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Feniranje'), findsOneWidget);
    expect(
      find.textContaining('Rezervisali ste usluge iz kategorije'),
      findsWidgets,
    );
  });
}

class _RecommendationApi extends ApiService {
  @override
  Future<List<Recommendation>> getMyRecommendations() async => [
    const Recommendation(
      serviceId: 12,
      serviceName: 'Feniranje',
      description: 'Njega i oblikovanje kose.',
      serviceCategoryId: 3,
      serviceCategoryName: 'Njega kose',
      durationInMinutes: 45,
      price: 25,
      salonId: 5,
      salonName: 'Studio Ljepote',
      reason: 'Rezervisali ste usluge iz kategorije Njega kose.',
    ),
    const Recommendation(
      serviceId: 14,
      serviceName: 'Tretman za kosu',
      description: 'Hidratantni tretman.',
      serviceCategoryId: 3,
      serviceCategoryName: 'Njega kose',
      durationInMinutes: 60,
      price: 35,
      salonId: 5,
      salonName: 'Studio Ljepote',
      reason: 'Rezervisali ste usluge iz kategorije Njega kose.',
    ),
  ];

  @override
  Future<List<Salon>> getSalons() async => [
    Salon(
      id: 5,
      name: 'Studio Ljepote',
      description: '',
      address: 'Centar',
      city: 'Sarajevo',
      phoneNumber: '',
      email: '',
      imageUrl: '',
      isActive: true,
    ),
  ];
}
