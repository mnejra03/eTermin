import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/salon.dart';
import '../models/service.dart';

import '../models/employee.dart';

import '../models/notification.dart';

class ApiService {
  static String? _token;
  static const String baseUrl = 'http://10.0.2.2:5130/api';

  void logout() {
    _token = null;
  }

  Map<String, String> get _authHeaders => {'Authorization': 'Bearer $_token'};

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.body.isEmpty) {
      throw Exception(
        'API je vratio prazan odgovor. Status: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      _token = data['token'];

      if (_token == null || _token!.isEmpty) {
        throw Exception('Login nije vratio JWT token.');
      }

      return data;
    }

    throw Exception(data['message'] ?? 'Prijava nije uspjela.');
  }

  Future<List<Salon>> getSalons() async {
    final response = await http.get(
      Uri.parse('$baseUrl/Salons'),
      headers: _authHeaders,
    );

    if (response.body.isEmpty) {
      throw Exception(
        'Saloni API je vratio prazan odgovor. '
        'Status: ${response.statusCode}',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Saloni API greška. '
        'Status: ${response.statusCode}\n'
        'Body: ${response.body}',
      );
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw Exception(
        'Neočekivan odgovor za salone.\n'
        'Tip: ${data.runtimeType}\n'
        'Body: ${response.body}',
      );
    }

    return data
        .map((json) => Salon.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Service>> getServices() async {
    final response = await http.get(
      Uri.parse('$baseUrl/Services'),
      headers: _authHeaders,
    );

    if (response.body.isEmpty) {
      throw Exception('API je vratio prazan odgovor.');
    }

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return (data as List).map((json) => Service.fromJson(json)).toList();
    }

    throw Exception('Usluge se ne mogu učitati.');
  }

  Future<List<Employee>> getEmployees() async {
    final response = await http.get(
      Uri.parse('$baseUrl/Employees'),
      headers: _authHeaders,
    );

    if (response.body.isEmpty) {
      throw Exception('API je vratio prazan odgovor.');
    }

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return (data as List).map((json) => Employee.fromJson(json)).toList();
    }

    throw Exception('Zaposlenici se ne mogu učitati.');
  }

  Future<List<Map<String, dynamic>>> getAvailableSlots({
    required int salonId,
    required int employeeId,
    required int serviceId,
    required DateTime date,
  }) async {
    final formattedDate =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final uri = Uri.parse(
      '$baseUrl/Appointments/available-slots'
      '?salonId=$salonId'
      '&employeeId=$employeeId'
      '&serviceId=$serviceId'
      '&date=$formattedDate',
    );

    if (_token == null || _token!.isEmpty) {
      throw Exception('JWT TOKEN NIJE POSTAVLJEN.');
    }

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $_token'},
    );

    if (response.body.isEmpty) {
      throw Exception(
        'API je vratio prazan odgovor. '
        'Status: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return List<Map<String, dynamic>>.from(data);
    }

    throw Exception('Slobodni termini se ne mogu učitati.');
  }

  Future<List<Map<String, dynamic>>> getMyAppointments() async {
    if (_token == null || _token!.isEmpty) {
      throw Exception('JWT TOKEN NIJE POSTAVLJEN.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/Appointments/my'),
      headers: {'Authorization': 'Bearer $_token'},
    );

    if (response.body.isEmpty) {
      throw Exception(
        'API je vratio prazan odgovor. '
        'Status: ${response.statusCode}',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Moji termini API greška.\n'
        'Status: ${response.statusCode}\n'
        'Body: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw Exception(
        'Neočekivan odgovor za moje termine.\n'
        'Tip: ${decoded.runtimeType}',
      );
    }

    return decoded
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item as Map),
        )
        .toList();
  }

  Future<int> createAppointment({
    required int salonId,
    required int employeeId,
    required int serviceId,
    required DateTime startTime,
    required DateTime endTime,
    required double price,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Appointments'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'salonId': salonId,
        'employeeId': employeeId,
        'serviceId': serviceId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'status': 'Pending',
        'price': price,
      }),
    );

    if (response.body.isEmpty) {
      throw Exception(
        'API je vratio prazan odgovor. '
        'Status: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data['id'] as int;
    }

    throw Exception(
      'Status: ${response.statusCode}\n'
      'Odgovor API-ja: ${response.body}',
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/Auth/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.body.isEmpty) {
      throw Exception(
        'API je vratio prazan odgovor. Status: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(data['message'] ?? 'Promjena lozinke nije uspjela.');
  }

  Future<List<AppNotification>> getMyNotifications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/Notifications/my'),
      headers: _authHeaders,
    );

    if (response.body.isEmpty) {
      throw Exception(
        'API je vratio prazan odgovor. '
        'Status: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return (data as List)
          .map((json) => AppNotification.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Obavijesti se ne mogu učitati.');
  }

  Future<void> markNotificationAsRead(int id) async {
    final response = await http.put(
      Uri.parse('$baseUrl/Notifications/$id/read'),
      headers: _authHeaders,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception('Obavijest se ne može označiti kao pročitana.');
  }

  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
      }),
    );

    if (response.body.isEmpty) {
      throw Exception(
        'API je vratio prazan odgovor. '
        'Status: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw Exception(data['message'] ?? 'Registracija nije uspjela.');
  }

  Future<int> createPayment({
    required int appointmentId,
    required double amount,
    required String paymentMethod,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Payments'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'appointmentId': appointmentId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'status': 'Pending',
        'transactionId': '',
      }),
    );

    if (response.body.isEmpty) {
      throw Exception(
        'API je vratio prazan odgovor. Status: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data['id'] as int;
    }

    throw Exception(data['message'] ?? 'Kreiranje plaćanja nije uspjelo.');
  }

  Future<Map<String, dynamic>> createPayPalOrder({
    required double amount,
    required String currency,
    required String description,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Payments/paypal/create-order'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'amount': amount,
        'currency': currency,
        'description': description,
      }),
    );

    if (response.body.isEmpty) {
      throw Exception(
        'PayPal API je vratio prazan odgovor. '
        'Status: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data['message'] ?? 'Kreiranje PayPal narudžbe nije uspjelo.',
    );
  }

  Future<String> capturePayPalOrder({
    required String orderId,
    required int paymentId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Payments/paypal/capture-order'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({'orderId': orderId, 'paymentId': paymentId}),
    );

    if (response.body.isEmpty) {
      throw Exception(
        'PayPal capture API je vratio prazan odgovor. '
        'Status: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data['captureId'] as String;
    }

    throw Exception(data['message'] ?? 'PayPal plaćanje nije uspjelo.');
  }
}
