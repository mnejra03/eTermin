import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/salon.dart';
import '../models/service.dart';

import '../models/employee.dart';

import '../models/notification.dart';
import '../models/recommendation.dart';

class ApiPage<T> {
  const ApiPage({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;
}

class ApiService {
  static String? _token;
  static const String baseUrl = 'http://10.0.2.2:5130/api';
  static const int defaultPageSize = 20;

  static Uri? salonImageUri(String imageUrl) {
    if (imageUrl.trim().isEmpty) return null;
    final parsed = Uri.tryParse(imageUrl);
    if (parsed == null) return null;
    if (parsed.hasScheme) return parsed;

    return Uri.parse(baseUrl).replace(
      path: imageUrl.startsWith('/') ? imageUrl : '/$imageUrl',
      query: null,
      fragment: null,
    );
  }

  void logout() {
    _token = null;
  }

  Map<String, String> get _authHeaders => {'Authorization': 'Bearer $_token'};

  Future<ApiPage<Map<String, dynamic>>> _getPagedData(
    String path, {
    int page = 1,
    int pageSize = defaultPageSize,
    Map<String, String> queryParameters = const {},
  }) async {
    final uri = Uri.parse('$baseUrl/$path').replace(
      queryParameters: {
        'page': '$page',
        'pageSize': '$pageSize',
        ...queryParameters,
      },
    );
    final response = await http.get(uri, headers: _authHeaders);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _errorMessage(response.body, fallback: 'Podaci se ne mogu učitati.'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['items'] is! List) {
      throw Exception('API je vratio neočekivan odgovor za stranicu.');
    }

    final items = (decoded['items'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    return ApiPage(
      items: items,
      totalCount: (decoded['totalCount'] as num).toInt(),
      page: (decoded['page'] as num).toInt(),
      pageSize: (decoded['pageSize'] as num).toInt(),
      totalPages: (decoded['totalPages'] as num).toInt(),
    );
  }

  Future<List<Map<String, dynamic>>> _getAllPagedData(String path) async {
    final firstPage = await _getPagedData(path);
    final items = [...firstPage.items];
    for (var page = 2; page <= firstPage.totalPages; page++) {
      items.addAll((await _getPagedData(path, page: page)).items);
    }
    return items;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        throw Exception('Prijava nije uspjela. Pokušajte ponovo.');
      }
      final data = jsonDecode(response.body);
      _token = data['token'];

      if (_token == null || _token!.isEmpty) {
        throw Exception('Login nije vratio JWT token.');
      }

      return data;
    }

    throw Exception(
      _errorMessage(response.body, fallback: 'Prijava nije uspjela.'),
    );
  }

  Future<List<Salon>> getSalons() async =>
      (await _getAllPagedData('Salons')).map(Salon.fromJson).toList();

  Future<ApiPage<Salon>> getSalonsPage({
    int page = 1,
    int pageSize = defaultPageSize,
  }) async {
    final result = await _getPagedData(
      'Salons',
      page: page,
      pageSize: pageSize,
    );
    return ApiPage(
      items: result.items.map(Salon.fromJson).toList(),
      totalCount: result.totalCount,
      page: result.page,
      pageSize: result.pageSize,
      totalPages: result.totalPages,
    );
  }

  Future<List<Salon>> getPopularSalons() async {
    final result = await _getPagedData('Salons/popular');
    return result.items.map(Salon.fromJson).toList();
  }

  Future<List<Service>> getServices() async =>
      (await _getAllPagedData('Services')).map(Service.fromJson).toList();

  Future<List<Employee>> getEmployees() async =>
      (await _getAllPagedData('Employees')).map(Employee.fromJson).toList();

  Future<List<Recommendation>> getMyRecommendations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/Recommendations/my'),
      headers: _authHeaders,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _errorMessage(
          response.body,
          fallback: 'Preporuke se trenutno ne mogu učitati.',
        ),
      );
    }
    if (response.body.isEmpty) {
      throw Exception('Preporuke se trenutno ne mogu učitati.');
    }

    final data = jsonDecode(response.body);
    if (data is! List) {
      throw Exception('API je vratio neočekivan odgovor za preporuke.');
    }
    return data
        .map((json) => Recommendation.fromJson(json as Map<String, dynamic>))
        .toList();
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

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _errorMessage(
          response.body,
          fallback: 'Slobodni termini se ne mogu učitati.',
        ),
      );
    }

    if (response.body.isEmpty) {
      throw Exception('Slobodni termini se ne mogu učitati.');
    }

    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getMyAppointments() async {
    if (_token == null || _token!.isEmpty) {
      throw Exception('JWT TOKEN NIJE POSTAVLJEN.');
    }
    return _getAllPagedData('Appointments/my');
  }

  Future<ApiPage<Map<String, dynamic>>> getMyAppointmentsPage({
    int page = 1,
    int pageSize = defaultPageSize,
    String? status,
  }) => _getPagedData(
    'Appointments/my',
    page: page,
    pageSize: pageSize,
    queryParameters: status == null ? const {} : {'status': status},
  );

  Future<List<Map<String, dynamic>>> getPaymentsForAppointment(
    int appointmentId,
  ) async {
    if (_token == null || _token!.isEmpty) {
      throw Exception('JWT TOKEN NIJE POSTAVLJEN.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/Payments/appointment/$appointmentId'),
      headers: {'Authorization': 'Bearer $_token'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _errorMessage(response.body, fallback: 'Uplate se ne mogu učitati.'),
      );
    }

    if (response.body.isEmpty) {
      throw Exception('Uplate se ne mogu učitati.');
    }
    final data = jsonDecode(response.body);
    return (data as List)
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

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _errorMessage(response.body, fallback: 'Termin nije moguće kreirati.'),
      );
    }

    if (response.body.isEmpty) {
      throw Exception('Termin nije moguće kreirati.');
    }

    final data = jsonDecode(response.body);
    return data['id'] as int;
  }

  Future<void> cancelAppointment(int appointmentId, String reason) async {
    if (_token == null || _token!.isEmpty) {
      throw Exception('JWT TOKEN NIJE POSTAVLJEN.');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/Appointments/$appointmentId/cancel'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'reason': reason}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final message = response.body.isEmpty
        ? 'Termin se ne može otkazati.'
        : _errorMessage(response.body, fallback: 'Termin se ne može otkazati.');
    throw Exception(message);
  }

  String _errorMessage(
    String body, {
    String fallback = 'Došlo je do greške. Pokušajte ponovo.',
  }) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> &&
          decoded['message'] is String &&
          (decoded['message'] as String).isNotEmpty) {
        return decoded['message'] as String;
      }
    } on FormatException {
      return fallback;
    }
    return fallback;
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

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(
      _errorMessage(response.body, fallback: 'Promjena lozinke nije uspjela.'),
    );
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/Auth/profile'),
      headers: {'Content-Type': 'application/json', 'Authorization': '******'},
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        response.body.isEmpty
            ? 'Profil nije moguće izmijeniti.'
            : _errorMessage(
                response.body,
                fallback: 'Profil nije moguće izmijeniti.',
              ),
      );
    }
  }

  Future<void> requestPasswordResetCode(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Auth/password-reset/request'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        response.body.isEmpty
            ? 'Kod nije moguće poslati.'
            : _errorMessage(
                response.body,
                fallback: 'Kod nije moguće poslati.',
              ),
      );
    }
  }

  Future<void> resetForgottenPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Auth/password-reset/confirm'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'code': code,
        'newPassword': newPassword,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        response.body.isEmpty
            ? 'Lozinku nije moguće resetovati.'
            : _errorMessage(
                response.body,
                fallback: 'Lozinku nije moguće resetovati.',
              ),
      );
    }
  }

  Future<List<AppNotification>> getMyNotifications() async =>
      (await _getAllPagedData('Notifications/my'))
          .map(AppNotification.fromJson)
          .toList();

  Future<ApiPage<AppNotification>> getMyNotificationsPage({
    int page = 1,
    int pageSize = defaultPageSize,
  }) async {
    final result = await _getPagedData(
      'Notifications/my',
      page: page,
      pageSize: pageSize,
    );
    return ApiPage(
      items: result.items.map(AppNotification.fromJson).toList(),
      totalCount: result.totalCount,
      page: result.page,
      pageSize: result.pageSize,
      totalPages: result.totalPages,
    );
  }

  Future<int> getMyUnreadNotificationCount() async {
    final response = await http.get(
      Uri.parse('$baseUrl/Notifications/my/unread-count'),
      headers: _authHeaders,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _errorMessage(response.body, fallback: 'Notifikacije se ne mogu učitati.'),
      );
    }

    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic> || data['unreadCount'] is! num) {
      throw Exception('API je vratio neočekivan broj nepročitanih notifikacija.');
    }
    return (data['unreadCount'] as num).toInt();
  }

  Future<void> markNotificationAsRead(int id) async {
    final response = await http.put(
      Uri.parse('$baseUrl/Notifications/$id/read'),
      headers: _authHeaders,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(
      response.body.isEmpty
          ? 'Obavijest se ne može označiti kao pročitana.'
          : _errorMessage(
              response.body,
              fallback: 'Obavijest se ne može označiti kao pročitana.',
            ),
    );
  }

  Future<void> deleteNotification(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/Notifications/$id'),
      headers: {'Authorization': 'Bearer $_token'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        response.body.isEmpty
            ? 'Brisanje obavijesti nije uspjelo.'
            : _errorMessage(
                response.body,
                fallback: 'Brisanje obavijesti nije uspjelo.',
              ),
      );
    }
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

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        throw Exception('Registracija nije uspjela. Pokušajte ponovo.');
      }
      final data = jsonDecode(response.body);
      return data;
    }

    throw Exception(
      _errorMessage(response.body, fallback: 'Registracija nije uspjela.'),
    );
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

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        throw Exception('Kreiranje plaćanja nije uspjelo.');
      }
      final data = jsonDecode(response.body);
      return data['id'] as int;
    }

    throw Exception(
      _errorMessage(
        response.body,
        fallback: 'Kreiranje plaćanja nije uspjelo.',
      ),
    );
  }

  Future<Map<String, dynamic>> createPayPalOrder({
    required int paymentId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Payments/paypal/create-order'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({'paymentId': paymentId}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _errorMessage(
          response.body,
          fallback: 'Kreiranje PayPal narudžbe nije uspjelo.',
        ),
      );
    }
    if (response.body.isEmpty) {
      throw Exception('PayPal API nije vratio podatke.');
    }

    {
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data);
    }
  }

  Future<String> capturePayPalOrder({required int paymentId}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Payments/paypal/capture-order'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({'paymentId': paymentId}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _errorMessage(response.body, fallback: 'PayPal plaćanje nije uspjelo.'),
      );
    }

    if (response.body.isEmpty) {
      throw Exception('PayPal plaćanje nije uspjelo.');
    }
    final data = jsonDecode(response.body);
    return data['captureId'] as String;
  }
}
