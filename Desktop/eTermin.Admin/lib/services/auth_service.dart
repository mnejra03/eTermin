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

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final request = await _client.postUrl(_baseUri.resolve('Auth/login'));
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({'email': email, 'password': password}));

    final response = await request.close();
    final responseBody = await utf8.decoder.bind(response).join();
    Object? decoded;
    if (responseBody.isNotEmpty) {
      try {
        decoded = jsonDecode(responseBody);
      } on FormatException {
        return const AuthResult.failure(
          'Server je vratio neispravan odgovor za prijavu.',
        );
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString()
          : null;
      return AuthResult.failure(message ?? 'Email ili lozinka nisu ispravni.');
    }

    if (decoded is! Map<String, dynamic>) {
      return const AuthResult.failure('Server je vratio neočekivan odgovor.');
    }

    if ((decoded['role']?.toString() ?? '').toLowerCase() != 'admin') {
      return const AuthResult.failure(
        'Ova aplikacija je namijenjena administratorskim računima.',
      );
    }

    final session = AdminSession.fromJson(decoded);
    if (session.token.isEmpty) {
      return const AuthResult.failure('Server nije vratio token za prijavu.');
    }
    return AuthResult.success(session);
  }

  void dispose() => _client.close(force: true);
}

class AuthResult {
  const AuthResult.success(AdminSession session)
    : session = session,
      message = null;

  const AuthResult.failure(this.message) : session = null;

  final AdminSession? session;
  final String? message;

  bool get succeeded => session != null;
}
