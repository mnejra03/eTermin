import 'dart:convert';
import 'dart:io';

import '../models/admin_session.dart';

class AuthService {
  AuthService({HttpClient? client}) : _client = client ?? HttpClient();

  static const _configuredBaseUrl = String.fromEnvironment(
    'ET_API_BASE_URL',
    defaultValue: 'http://localhost:5130/api/',
  );

  final HttpClient _client;
  final Uri _baseUri = Uri.parse(_configuredBaseUrl);

  Future<AdminSession> login({
    required String email,
    required String password,
  }) async {
    final request = await _client.postUrl(_baseUri.resolve('Auth/login'));
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({'email': email, 'password': password}));

    final response = await request.close();
    final responseBody = await utf8.decoder.bind(response).join();
    final decoded = responseBody.isEmpty ? null : jsonDecode(responseBody);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString()
          : null;
      throw AuthException(message ?? 'Prijava nije uspjela.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw AuthException('Server je vratio neočekivan odgovor.');
    }

    if ((decoded['role']?.toString() ?? '').toLowerCase() != 'admin') {
      throw AuthException('Ova aplikacija je namijenjena administratorima.');
    }

    final session = AdminSession.fromJson(decoded);
    if (session.token.isEmpty) {
      throw AuthException('Server nije vratio token za prijavu.');
    }
    return session;
  }

  void dispose() => _client.close(force: true);
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
