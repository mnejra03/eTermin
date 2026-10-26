import 'dart:convert';
import 'dart:io';

import '../models/dashboard_statistics.dart';

class DashboardService {
  DashboardService({HttpClient? client}) : _client = client ?? HttpClient();

  static const _configuredBaseUrl = String.fromEnvironment(
    'ET_API_BASE_URL',
    defaultValue: 'http://localhost:5130/api/',
  );

  final HttpClient _client;
  final Uri _baseUri = Uri.parse(_configuredBaseUrl);

  Future<DashboardStatistics> fetchToday(String token) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return _fetchForPeriod(token, today, tomorrow);
  }

  Future<DashboardStatistics> fetchRecentWeek(String token) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _fetchForPeriod(
      token,
      today.subtract(const Duration(days: 6)),
      today.add(const Duration(days: 1)),
    );
  }

  Future<DashboardStatistics> _fetchForPeriod(
    String token,
    DateTime from,
    DateTime to,
  ) async {
    final endpoint = _baseUri
        .resolve('Statistics/dashboard')
        .replace(queryParameters: {'from': _date(from), 'to': _date(to)});

    final request = await _client.getUrl(endpoint);
    request.headers
      ..set(HttpHeaders.acceptHeader, ContentType.json.mimeType)
      ..set(HttpHeaders.authorizationHeader, 'Bearer $token');

    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();
    final decoded = body.isEmpty ? null : jsonDecode(body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString()
          : null;
      throw DashboardException(
        message ??
            'Učitavanje statistike nije uspjelo (HTTP ${response.statusCode}).',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const DashboardException('API je vratio neočekivan odgovor.');
    }
    return DashboardStatistics.fromJson(decoded);
  }

  Future<List<Map<String, dynamic>>> fetchTodayAppointments(
    String token,
  ) async {
    final endpoint = _baseUri.resolve('Appointments/dashboard');
    final request = await _client.getUrl(endpoint);
    request.headers
      ..set(HttpHeaders.acceptHeader, ContentType.json.mimeType)
      ..set(HttpHeaders.authorizationHeader, 'Bearer $token');
    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();
    final decoded = body.isEmpty ? null : jsonDecode(body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw DashboardException(
        'Učitavanje današnjih termina nije uspjelo (HTTP ${response.statusCode}).',
      );
    }
    if (decoded is! List) {
      throw const DashboardException('API je vratio neočekivan odgovor.');
    }
    return decoded.whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> fetchAvailableSlots(String token) async {
    final endpoint = _baseUri.resolve('Appointments/dashboard-available-slots');
    final request = await _client.getUrl(endpoint);
    request.headers
      ..set(HttpHeaders.acceptHeader, ContentType.json.mimeType)
      ..set(HttpHeaders.authorizationHeader, 'Bearer $token');
    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();
    final decoded = body.isEmpty ? null : jsonDecode(body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw DashboardException(
        'Učitavanje slobodnih slotova nije uspjelo (HTTP ${response.statusCode}).',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const DashboardException('API je vratio neočekivan odgovor.');
    }
    return decoded;
  }

  String _date(DateTime date) => date.toIso8601String().substring(0, 10);

  void dispose() => _client.close(force: true);
}

class DashboardException implements Exception {
  const DashboardException(this.message);

  final String message;

  @override
  String toString() => message;
}
