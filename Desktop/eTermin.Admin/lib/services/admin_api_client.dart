import 'dart:convert';
import 'dart:io';

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

class AdminApiClient {
  AdminApiClient({required this.token, HttpClient? client})
    : _client = client ?? (HttpClient()..connectionTimeout = const Duration(seconds: 15));

  static const _configuredBaseUrl = String.fromEnvironment(
    'ET_API_BASE_URL',
    defaultValue: 'http://localhost:5130/api/',
  );

  final String token;
  final HttpClient _client;
  final Uri _baseUri = Uri.parse(_configuredBaseUrl);

  Uri resolveSalonImageUri(String imageUrl) {
    final imageUri = Uri.tryParse(imageUrl);
    if (imageUri == null) return _baseUri.replace(path: '/');
    if (imageUri.hasScheme) return imageUri;
    return _baseUri.replace(
      path: imageUrl.startsWith('/') ? imageUrl : '/$imageUrl',
      query: null,
      fragment: null,
    );
  }

  Future<List<Map<String, dynamic>>> getList(String path) async {
    final uri = _baseUri
        .resolve(path)
        .replace(queryParameters: {'page': '1', 'pageSize': '100'});
    final result = await _send('GET', uri.toString());
    if (result is List) {
      return result.whereType<Map<String, dynamic>>().toList();
    }
    if (result is! Map<String, dynamic> || result['items'] is! List) {
      throw const ApiException('API je vratio neočekivane podatke.');
    }

    final firstPage = _parsePage(result);
    final items = [...firstPage.items];
    for (var page = 2; page <= firstPage.totalPages; page++) {
      items.addAll((await getPagedList(path, page: page, pageSize: 100)).items);
    }
    return items;
  }

  Future<ApiPage<Map<String, dynamic>>> getPagedList(
    String path, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final uri = _baseUri
        .resolve(path)
        .replace(queryParameters: {'page': '$page', 'pageSize': '$pageSize'});
    final result = await _send('GET', uri.toString());
    if (result is! Map<String, dynamic>) {
      throw const ApiException('API je vratio neočekivane podatke.');
    }
    return _parsePage(result);
  }

  ApiPage<Map<String, dynamic>> _parsePage(Map<String, dynamic> result) {
    if (result['items'] is! List) {
      throw const ApiException('API je vratio neočekivane podatke.');
    }
    return ApiPage(
      items: (result['items'] as List)
          .whereType<Map<String, dynamic>>()
          .toList(),
      totalCount: (result['totalCount'] as num).toInt(),
      page: (result['page'] as num).toInt(),
      pageSize: (result['pageSize'] as num).toInt(),
      totalPages: (result['totalPages'] as num).toInt(),
    );
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

  Future<ApiOperationResult> tryPost(
    String path,
    Map<String, dynamic> body,
  ) =>
      _trySend('POST', path, body: body);

  Future<ApiOperationResult> tryGetMap(String path) => _trySend('GET', path);

  Future<ApiOperationResult> tryPut(
    String path,
    Map<String, dynamic> body,
  ) =>
      _trySend('PUT', path, body: body);

  Future<ApiOperationResult> tryDelete(String path) async {
    return _trySend('DELETE', path);
  }

  Future<ApiOperationResult> _trySend(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _sendResponse(method, path, body: body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiOperationResult.succeeded(
        data: response.body is Map<String, dynamic> ? response.body : null,
      );
    }

    final message = response.body is Map<String, dynamic>
        ? response.body['message']?.toString()
        : null;
    return ApiOperationResult.failed(
      message ?? 'Zahtjev nije uspio (HTTP ${response.statusCode}).',
    );
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

    final response = await request.close().timeout(const Duration(seconds: 30));
    final text = await utf8.decoder
        .bind(response)
        .join()
        .timeout(const Duration(seconds: 30));
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
    final response = await _sendResponse(method, path, body: body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = response.body is Map<String, dynamic>
          ? response.body['message']?.toString()
          : null;
      throw ApiException(
        message ?? 'API greška (HTTP ${response.statusCode}).',
      );
    }
    return response.body;
  }

  Future<_ApiResponse> _sendResponse(
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

    return _ApiResponse(response.statusCode, decoded);
  }

  void dispose() => _client.close(force: true);
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiOperationResult {
  const ApiOperationResult.succeeded({this.data})
    : succeeded = true,
      message = null;

  const ApiOperationResult.failed(this.message)
    : succeeded = false,
      data = null;

  final bool succeeded;
  final String? message;
  final Map<String, dynamic>? data;
}

class _ApiResponse {
  const _ApiResponse(this.statusCode, this.body);

  final int statusCode;
  final dynamic body;
}
