import 'dart:convert';
import 'dart:io';

class AdminApiClient {
  AdminApiClient({required this.token, HttpClient? client})
    : _client = client ?? HttpClient();

  static const _configuredBaseUrl = String.fromEnvironment(
    'ET_API_BASE_URL',
    defaultValue: 'http://localhost:5130/api/',
  );

  final String token;
  final HttpClient _client;
  final Uri _baseUri = Uri.parse(_configuredBaseUrl);

  Future<List<Map<String, dynamic>>> getList(String path) async {
    final result = await _send('GET', path);
    if (result is! List) {
      throw const ApiException('API je vratio neočekivane podatke.');
    }
    return result.whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> getMap(String path) async {
    final result = await _send('GET', path);
    if (result is! Map<String, dynamic>) {
      throw const ApiException('API je vratio neočekivane podatke.');
    }
    return result;
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final result = await _send('POST', path, body: body);
    return result is Map<String, dynamic> ? result : <String, dynamic>{};
  }

  Future<void> put(String path, Map<String, dynamic> body) async {
    await _send('PUT', path, body: body);
  }

  Future<void> delete(String path) async {
    await _send('DELETE', path);
  }

  Future<Map<String, dynamic>> uploadSalonImage({
    required int salonId,
    required List<int> bytes,
    required String fileName,
    required int sortOrder,
  }) async {
    final boundary = '----eTermin${DateTime.now().microsecondsSinceEpoch}';
    final extension = fileName.split('.').last.toLowerCase();
    final contentType = switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => throw const ApiException('Dozvoljeni su JPG, PNG i WEBP formati.'),
    };
    final safeFileName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final request = await _client.postUrl(
      _baseUri.resolve('Salons/$salonId/images'),
    );
    request.headers
      ..set(HttpHeaders.acceptHeader, ContentType.json.mimeType)
      ..set(HttpHeaders.authorizationHeader, 'Bearer $token')
      ..set(
        HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary',
      );
    request
      ..write('--$boundary\r\n')
      ..write(
        'Content-Disposition: form-data; name="file"; filename="$safeFileName"\r\n',
      )
      ..write('Content-Type: $contentType\r\n\r\n')
      ..add(bytes)
      ..write('\r\n--$boundary\r\n')
      ..write('Content-Disposition: form-data; name="sortOrder"\r\n\r\n')
      ..write('$sortOrder\r\n')
      ..write('--$boundary--\r\n');

    final response = await request.close();
    final text = await utf8.decoder.bind(response).join();
    dynamic decoded;
    if (text.isNotEmpty) {
      try {
        decoded = jsonDecode(text);
      } on FormatException {
        decoded = text;
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString()
          : null;
      throw ApiException(
        message ?? 'API greška (HTTP ${response.statusCode}).',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('API je vratio neočekivan odgovor za sliku.');
    }
    return decoded;
  }

  Future<String> downloadToDownloads(String path, String fileName) async {
    final bytes = await downloadBytes(path);

    final userDirectory =
        Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
    if (userDirectory == null || userDirectory.isEmpty) {
      throw const ApiException('Windows korisnički folder nije pronađen.');
    }
    final downloads = Directory(
      '$userDirectory${Platform.pathSeparator}Downloads',
    );
    final targetDirectory = await downloads.exists()
        ? downloads
        : Directory(
            '$userDirectory${Platform.pathSeparator}Documents${Platform.pathSeparator}eTermin',
          );
    await targetDirectory.create(recursive: true);
    final file = File(
      '${targetDirectory.path}${Platform.pathSeparator}$fileName',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<List<int>> downloadBytes(String path) async {
    final request = await _client.getUrl(_baseUri.resolve(path));
    request.headers
      ..set(HttpHeaders.acceptHeader, '*/*')
      ..set(HttpHeaders.authorizationHeader, 'Bearer $token');
    final response = await request.close();
    final bytes = await response.fold<List<int>>(
      <int>[],
      (buffer, chunk) => buffer..addAll(chunk),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = utf8.decode(bytes, allowMalformed: true);
      String? message;
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          message = decoded['message']?.toString();
        }
      } on FormatException {
        message = body.isEmpty ? null : body;
      }
      throw ApiException(message ?? 'Izvještaj nije moguće preuzeti.');
    }
    return bytes;
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final request = await _client.openUrl(method, _baseUri.resolve(path));
    request.headers
      ..set(HttpHeaders.acceptHeader, ContentType.json.mimeType)
      ..set(HttpHeaders.authorizationHeader, 'Bearer $token');
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }

    final response = await request.close();
    final text = await utf8.decoder.bind(response).join();
    dynamic decoded;
    if (text.isNotEmpty) {
      try {
        decoded = jsonDecode(text);
      } on FormatException {
        decoded = text;
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString()
          : null;
      throw ApiException(
        message ?? 'API greška (HTTP ${response.statusCode}).',
      );
    }
    return decoded;
  }

  void dispose() => _client.close(force: true);
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
