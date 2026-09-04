import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Tambahkan import ini

import 'user_session.dart';

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message, {this.body});

  final int statusCode;
  final String message;
  final String? body;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const String _apiBaseUrlFromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  // ====================== MANAJEMEN USER ID TERPUSAT ======================
  static const _secureAuthTokenKey = 'auth_token';
  static const _secureRefreshTokenKey = 'refresh_token';
  static const _keyCurrentUserId = 'current_logged_user_id';
  static const _keyUserSessionId = 'user_id';
  static int? _currentUserIdCache; // Cache di memory untuk akses cepat

  /// Ambil user ID yang sedang login (dari cache atau SharedPreferences)
  static Future<int> get currentUserId async {
    if (_currentUserIdCache != null) return _currentUserIdCache!;

    final prefs = await SharedPreferences.getInstance();
    final apiUserId = prefs.getInt(_keyCurrentUserId);
    final sessionUserId = prefs.getInt(_keyUserSessionId);
    final resolvedUserId = apiUserId ?? sessionUserId;
    debugPrint(
      'ApiClient.currentUserId => current_logged_user_id=$apiUserId, '
      'user_id=$sessionUserId, resolved=$resolvedUserId',
    );

    if (resolvedUserId == null || resolvedUserId <= 0) {
      throw Exception(
        'User ID belum diset! Pastikan kamu login/daftar terlebih dahulu.',
      );
    }

    _currentUserIdCache = resolvedUserId;
    await prefs.setInt(_keyCurrentUserId, resolvedUserId);
    await prefs.setInt(_keyUserSessionId, resolvedUserId);
    debugPrint('Ambil current user ID: $_currentUserIdCache');
    return _currentUserIdCache!;
  }

  /// Simpan user ID yang sedang login (ke cache dan SharedPreferences)
  static Future<void> setCurrentUserId(int userId) async {
    _currentUserIdCache = userId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCurrentUserId, userId);
    await prefs.setInt(_keyUserSessionId, userId);
    debugPrint('Simpan current user ID: $userId');
  }

  /// Hapus user ID (untuk logout)
  static Future<void> clearCurrentUserId() async {
    _currentUserIdCache = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentUserId);
    await prefs.remove(_keyUserSessionId);
    await const FlutterSecureStorage().delete(key: _secureAuthTokenKey);
    await const FlutterSecureStorage().delete(key: _secureRefreshTokenKey);
    debugPrint('Hapus current user ID');
  }
  // ===========================================================================

  String get baseUrl {
    final configuredBaseUrl = _apiBaseUrlFromEnv.trim();
    if (configuredBaseUrl.isNotEmpty) {
      return _trimTrailingSlash(configuredBaseUrl);
    }

    if (kIsWeb) return 'http://localhost:8000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://192.168.1.9:8000';
  }

  static String _trimTrailingSlash(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  void _logRequest(String method, Uri uri) {
    print('API BASE URL = $baseUrl');
    print('Request URL = $uri');
    print('Request Method = $method');
  }

  Future<http.Response> _get(Uri uri, {Map<String, String>? headers}) {
    _logRequest('GET', uri);
    return _client.get(uri, headers: headers);
  }

  Future<http.Response> _post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    _logRequest('POST', uri);
    return _client.post(uri, headers: headers, body: body, encoding: encoding);
  }

  Future<http.Response> _put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    _logRequest('PUT', uri);
    return _client.put(uri, headers: headers, body: body, encoding: encoding);
  }

  Future<http.Response> _patch(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    _logRequest('PATCH', uri);
    return _client.patch(uri, headers: headers, body: body, encoding: encoding);
  }

  Future<http.Response> _delete(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    _logRequest('DELETE', uri);
    return _client.delete(
      uri,
      headers: headers,
      body: body,
      encoding: encoding,
    );
  }

  String imageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    if (imagePath.startsWith('http')) return imagePath;
    return '$baseUrl$imagePath';
  }

  // ====================== METHOD API (USER ID JADI OPSIONAL) ======================
  // Semua parameter `userId` sekarang opsional, default menggunakan `currentUserId` terpusat

  Future<Map<String, dynamic>> classifySodium(double sodiumMg) async {
    final uri = Uri.parse('$baseUrl/api/v1/sodium/classify');
    final body = jsonEncode({'sodium_mg': sodiumMg, 'serving_size_g': 100});
    final res = await _sendWithAuthRetry(
      (headers) => _post(uri, headers: headers, body: body),
    );
    return _decodeMap(res);
  }

  // Auto-set current user ID setelah buat demo user
  Future<Map<String, dynamic>> createDemoUser() async {
    final uri = Uri.parse('$baseUrl/api/v1/users/demo');
    final res = await _post(uri, headers: {'Content-Type': 'application/json'});
    if (res.statusCode >= 400) {
      throw Exception(
        'Failed to create demo user: ${res.statusCode} ${res.body}',
      );
    }
    final result = _decodeMap(res);
    // Auto simpan user ID dari response
    final userId = result['user_id'] ?? result['id'];
    if (userId != null) {
      await setCurrentUserId(userId as int);
    }
    return result;
  }

//fungsi yang menerima setelah di scan
  Future<Map<String, dynamic>> scanLabel(String imagePath) async {
    debugPrint('=== BASE URL: $baseUrl');
    debugPrint('=== ENV URL: $_apiBaseUrlFromEnv');
    final effectiveUserId = await currentUserId;
    final uri = Uri.parse('$baseUrl/api/v1/cv/scan');

    final imageFile = File(imagePath);
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    final body = jsonEncode({
      'image_base64': base64Image,
      'user_id': effectiveUserId,
    });

    final res = await _sendWithAuthRetry(
      (headers) => _post(uri, headers: headers, body: body),
    );
    return _decodeMap(res);
  }

  Future<Map<String, dynamic>> askChatbot({
    int? userId, // Opsional
    required String question,
    int? educationPart,
    String? productName,
    String? kategori,
    double? sodiumPerPortionMg,
    int? scanId,
  }) async {
    final effectiveUserId = userId ?? await currentUserId;
    final uri = Uri.parse('$baseUrl/api/v1/chatbot/ask');
    final body = <String, dynamic>{
      'user_id': effectiveUserId,
      'question': question,
      if (educationPart != null) 'education_part': educationPart,
      if (productName != null && productName.trim().isNotEmpty)
        'product_name': productName,
      if (kategori != null && kategori.trim().isNotEmpty) 'kategori': kategori,
      if (sodiumPerPortionMg != null) 'sodium_mg': sodiumPerPortionMg.round(),
      if (scanId != null) 'scan_id': scanId,
    };
    final encodedBody = jsonEncode(body);
    final res = await _sendWithAuthRetry(
      (headers) => _post(uri, headers: headers, body: encodedBody),
    ).timeout(const Duration(seconds: 50));
    return _decodeMap(res);
  }

  Future<Map<String, dynamic>> getRekomendasiProduk({
    required String kategori,
    required int sodiumMg,
    int? userId,
    String? productName,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/rekomendasi-produk');
    final res = await _post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'kategori': kategori,
        'sodium_mg': sodiumMg,
        'user_id': userId,
        if (productName != null) 'product_name': productName,
      }),
    );
    return _decodeMap(res);
  }

  Future<Map<String, dynamic>> upsertUserProfile({
    int? userId, // Opsional
    required String fullName,
    required String gender,
    required DateTime birthDate,
    required bool hasHypertension,
    String? hypertensionCondition,
    int? systolicPressure,
    int? diastolicPressure,
    String? pregnancyStatus,
  }) async {
    final effectiveUserId = userId ?? await currentUserId;
    final uri = Uri.parse('$baseUrl/api/v1/users/$effectiveUserId/profile');

    final body = {
      'full_name': fullName,
      'gender': gender,
      'birth_date': birthDate.toIso8601String().split('T').first,
      'has_hypertension': hasHypertension,
      if (hypertensionCondition != null)
        'hypertension_condition': hypertensionCondition,
      'systolic_pressure': systolicPressure,
      'diastolic_pressure': diastolicPressure,
      if (pregnancyStatus != null) 'pregnancy_status': pregnancyStatus,
    };

    final res = await _put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (res.statusCode >= 400) {
      throw Exception('Failed to save profile: ${res.statusCode} ${res.body}');
    }

    return _decodeMap(res);
  }

  Future<Map<String, dynamic>> updateUserFullName({
    int? userId,
    required String fullName,
  }) async {
    final effectiveUserId = userId ?? await currentUserId;
    final uri = Uri.parse('$baseUrl/api/v1/users/$effectiveUserId/full-name');

    final res = await _put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'full_name': fullName}),
    );

    return _decodeMap(res);
  }

  Future<List<dynamic>> getIntakeHistory([int? userId]) async {
    final effectiveUserId = userId ?? await currentUserId;
    final uri = Uri.parse(
      '$baseUrl/api/v1/history/intake?user_id=$effectiveUserId',
    );
    final res = await _sendWithAuthRetry(
      (headers) => _get(uri, headers: headers),
    );
    final body = _decodeJson(res);
    if (body is List<dynamic>) return body;
    if (body is Map<String, dynamic> && body['value'] is List<dynamic>)
      return body['value'] as List<dynamic>;
    return <dynamic>[];
  }

  Future<List<dynamic>> getConsumedToday([int? userId]) async {
    final effectiveUserId = userId ?? await currentUserId;
    final uri = Uri.parse(
      '$baseUrl/api/v1/history/consumed-today?user_id=$effectiveUserId',
    );
    final res = await _sendWithAuthRetry(
      (headers) => _get(uri, headers: headers),
    );
    final body = _decodeJson(res);
    if (body is List<dynamic>) return body;
    return <dynamic>[];
  }

  Future<List<dynamic>> getScanHistory([int? userId]) async {
    final effectiveUserId = userId ?? await currentUserId;
    final uri = Uri.parse(
      '$baseUrl/api/v1/history/scans?user_id=$effectiveUserId',
    );
    final res = await _sendWithAuthRetry(
      (headers) => _get(uri, headers: headers),
    );
    final body = _decodeJson(res);
    if (body is List<dynamic>) return body;
    if (body is Map<String, dynamic> && body['value'] is List<dynamic>)
      return body['value'] as List<dynamic>;
    return <dynamic>[];
  }

  Future<Map<String, dynamic>> getDashboardStats([int? userId]) async {
    final effectiveUserId = userId ?? await currentUserId;
    final uri = Uri.parse(
      '$baseUrl/api/v1/history/dashboard?user_id=$effectiveUserId',
    );
    final res = await _sendWithAuthRetry(
      (headers) => _get(uri, headers: headers),
    );
    return _decodeMap(res);
  }

  Future<List<dynamic>> getChatHistory([int? userId]) async {
    final effectiveUserId = userId ?? await currentUserId;
    final uri = Uri.parse(
      '$baseUrl/api/v1/chat/history?user_id=$effectiveUserId',
    );
    final res = await _sendWithAuthRetry(
      (headers) => _get(uri, headers: headers),
    );
    final body = _decodeJson(res);
    if (body is List<dynamic>) {
      return body;
    }
    return <dynamic>[];
  }

  Future<Map<String, dynamic>> postScanHistory({
    int? userId, // Opsional
    required int sodiumMg,
    required double servings,
    String? productName,
    String? sodiumLevel,
    String? kategori,
    String type = 'single',
    String? productName2,
    int? sodiumMg2,
    String? imagePath2,
    bool isConsumed = false,
    double packageMl = 0.0,
    double portionsInPackage = 1.0,
    String satuanTakaran = 'g',
    double packageMl2 = 0.0,
    double portionsInPackage2 = 1.0,
    String satuanTakaran2 = 'g',
    String? imagePath,
    int? scanId,
    String? rekomendasiJson,
  }) async {
    final effectiveUserId = userId ?? await currentUserId;
    final uri = Uri.parse('$baseUrl/api/v1/history/intake');
    final body = {
      'user_id': effectiveUserId,
      'food_name': productName ?? 'Produk',
      'sodium_mg': sodiumMg,
      'sodium_level':
          sodiumLevel ??
          'medium', // conservative default; callers should supply a personalized value
      'servings': servings,
      'product_name': productName ?? 'Produk',
      'kategori': kategori,
      'type': type,
      if (productName2 != null) 'product_name2': productName2,
      if (sodiumMg2 != null) 'sodium_mg2': sodiumMg2,
      'is_consumed': isConsumed,
      'package_ml': packageMl,
      'portions_in_package': portionsInPackage,
      'satuan_takaran': satuanTakaran,
      'package_ml2': packageMl2,
      'portions_in_package2': portionsInPackage2,
      'satuan_takaran2': satuanTakaran2,
      if (imagePath != null) 'image_path': imagePath,
      if (imagePath2 != null) 'image_path2': imagePath2,
      if (scanId != null) 'scan_id': scanId,
      if (rekomendasiJson != null) 'rekomendasi_json': rekomendasiJson,
    };

    final res = await _post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    return _decodeMap(res);
  }

  // Auto-set current user ID setelah register
  Future<Map<String, dynamic>> registerUser({
    String fullName = '',
    required String email,
    required String password,
  }) async {
    debugPrint('=== REGISTER BASE URL: $baseUrl'); // tambah ini
    debugPrint('=== REGISTER ENV URL: $_apiBaseUrlFromEnv');
    final uri = Uri.parse('$baseUrl/api/v1/auth/register');
    final res = await _post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'full_name': fullName,
        'email': email,
        'password': password,
      }),
    );
    debugPrint('=== REGISTER BASE URL: $baseUrl');
    debugPrint('=== REGISTER ENV URL: $_apiBaseUrlFromEnv');
    final result = _decodeMap(res);
    debugPrint('=== REGISTER RESPONSE: $result');
    // Auto simpan user ID dari response
    final userId = result['user_id'] ?? result['id'];
    if (userId != null) {
      final parsedUserId = userId is num
          ? userId.toInt()
          : int.tryParse(userId.toString());
      if (parsedUserId != null && parsedUserId > 0) {
        await setCurrentUserId(parsedUserId);
        await UserSession().setUserId(parsedUserId);
      }
    }
    return result;
  }

  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/auth/login');
    final res = await _post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final result = _decodeMap(res);
    final token = result['access_token'] as String?;
    final refreshToken = result['refresh_token'] as String?;
    final userId = result['user_id'];
    final parsedUserId = userId is num
        ? userId.toInt()
        : int.tryParse(userId?.toString() ?? '');

    if (parsedUserId != null && parsedUserId > 0) {
      await setCurrentUserId(parsedUserId);
      await UserSession().setUserId(parsedUserId);
    }
    if (token != null && token.isNotEmpty) {
      await UserSession().setAccessToken(token);
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await UserSession().setRefreshToken(refreshToken);
    }

    return result;
  }

  Future<void> sendOtp({
    required String email,
    String purpose = 'register',
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/auth/send-otp');
    final res = await _post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'purpose': purpose}),
    );
    _decodeJson(res);
  }

  Future<void> verifyOtp({required String email, required String otp}) async {
    final uri = Uri.parse('$baseUrl/api/v1/auth/verify-otp');
    final res = await _post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    _decodeJson(res);
  }

  Future<Map<String, dynamic>> getUserProfile([int? userId]) async {
    final effectiveUserId = userId ?? await currentUserId;
    final uri = Uri.parse('$baseUrl/api/v1/users/$effectiveUserId/profile');
    final res = await _sendWithAuthRetry(
      (headers) => _get(uri, headers: headers),
    );
    debugPrint('=== getUserProfile status: ${res.statusCode}');
    debugPrint('=== getUserProfile body: ${res.body}'); // ← sudah ada
    return _decodeMap(res);
  }

  Future<Map<String, dynamic>> getUserAccount([int? userId]) async {
    final effectiveUserId = userId ?? await currentUserId;
    final uri = Uri.parse('$baseUrl/api/v1/users/$effectiveUserId');
    final res = await _get(uri);
    return _decodeMap(res);
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final effectiveUserId = UserSession().getUserId();
    if (effectiveUserId <= 0) {
      throw const ApiException(401, 'Sesi berakhir, silakan login ulang.');
    }
    final uri = Uri.parse(
      '$baseUrl/api/v1/users/$effectiveUserId/change-password',
    );
    final body = jsonEncode({
      'old_password': oldPassword,
      'new_password': newPassword,
    });
    final res = await _sendWithAuthRetry(
      (headers) => _post(uri, headers: headers, body: body),
    );
    if (res.statusCode >= 400) {
      final body = jsonDecode(res.body);
      final message = body['detail']?.toString() ?? 'Gagal mengganti password';
      throw ApiException(res.statusCode, message);
    }
  }

  Future<void> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/auth/reset-password');
    final res = await _post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'new_password': newPassword}),
    );
    if (res.statusCode != HttpStatus.ok) {
      String message = 'Gagal mengganti password';
      try {
        final body = jsonDecode(res.body);
        if (body is Map<String, dynamic> && body['detail'] != null) {
          message = body['detail'].toString();
        }
      } catch (e) {
        print('resetPassword response JSON parse error = $e');
        // Keep default message when the body is not JSON.
      }
      throw ApiException(res.statusCode, message, body: res.body);
    }
  }

  dynamic _decodeJson(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'API error ${response.statusCode}';
      try {
        final body = response.body.isEmpty ? null : jsonDecode(response.body);
        if (body is Map<String, dynamic> && body['detail'] != null) {
          message = body['detail'].toString();
        }
      } catch (e) {
        print('API error response JSON parse error = $e');
        // Keep default API error message when the body is not JSON.
      }
      throw ApiException(response.statusCode, message, body: response.body);
    }
    return jsonDecode(response.body);
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    final json = _decodeJson(response);
    if (json is Map<String, dynamic>) {
      return json;
    }
    throw const FormatException('Unexpected API response format');
  }

  Future<Map<String, dynamic>> updateIntakeConsumed({
    required int intakeId,
    int? userId,
    required bool isConsumed,
    double? servings,
    String? productName,
    int? sodiumMg,
    String? productName2,
    int? sodiumMg2,
    String? imagePath,
    String? imagePath2,
    String? type,
  }) async {
    final effectiveUserId = userId ?? await currentUserId;
    debugPrint('API userId: $effectiveUserId');
    final uri = Uri.parse('$baseUrl/api/v1/history/intake/$intakeId');
    debugPrint('PATCH URL: $uri');
    final body = jsonEncode({
      'user_id': effectiveUserId,
      'is_consumed': isConsumed,
      if (servings != null) 'servings': servings,
      if (productName != null) 'food_name': productName,
      if (sodiumMg != null) 'sodium_mg': sodiumMg,
      if (productName2 != null) 'product_name2': productName2,
      if (sodiumMg2 != null) 'sodium_mg2': sodiumMg2,
      if (imagePath != null) 'image_path': imagePath,
      if (imagePath2 != null) 'image_path2': imagePath2,
      if (type != null) 'type': type,
    });
    debugPrint('body: $body');
    final res = await _patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    debugPrint('PATCH status: ${res.statusCode}');
    debugPrint('PATCH response: ${res.body}');
    return _decodeMap(res);
  }

  Future<Map<String, dynamic>> updateIntake({
    required int intakeId,
    int? userId,
    required String foodName,
    String? kategori,
    required double sodiumMg,
    required String sodiumLevel,
    required double servings,
    required double packageMl,
    required double portionsInPackage,
    required String satuanTakaran,
  }) async {
    final effectiveUserId = userId ?? await currentUserId;
    final uri = Uri.parse('$baseUrl/api/v1/history/intake/$intakeId');
    final res = await _put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': effectiveUserId,
        'food_name': foodName,
        'kategori': kategori,
        'sodium_mg': sodiumMg,
        'sodium_level': sodiumLevel,
        'servings': servings,
        'package_ml': packageMl,
        'portions_in_package': portionsInPackage,
        'satuan_takaran': satuanTakaran,
      }),
    );
    return _decodeMap(res);
  }

  Future<Map<String, dynamic>> deleteIntake({
    required int intakeId,
    int? userId,
  }) async {
    final effectiveUserId = userId ?? await currentUserId;
    final uri = Uri.parse(
      '$baseUrl/api/v1/history/intake/$intakeId?user_id=$effectiveUserId',
    );
    final res = await _delete(uri);
    return _decodeMap(res);
  }

  Future<Map<String, dynamic>> updateScan({
    required int scanId,
    required String namaProduk,
    required String kategori,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/cv/scan/$scanId');
    final res = await _patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nama_produk': namaProduk, 'kategori': kategori}),
    );
    return _decodeMap(res);
  }

  Future<void> logout() async {
    final refreshToken = UserSession().getRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        final uri = Uri.parse('$baseUrl/api/v1/auth/logout');
        await _post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh_token': refreshToken}),
        );
      } catch (e) {
        print('Logout request failed = $e');
        // Local logout should still succeed when the network is unavailable.
      }
    }
    await clearLocalSession();
  }

  Future<http.Response> _sendWithAuthRetry(
    Future<http.Response> Function(Map<String, String> headers) send,
  ) async {
    final response = await send(await _authHeaders());
    if (response.statusCode != HttpStatus.unauthorized) {
      return response;
    }

    final refreshed = await _tryRefreshToken();
    if (!refreshed) {
      await clearLocalSession();
      throw const ApiException(401, 'Sesi berakhir, silakan login ulang.');
    }

    final retryResponse = await send(await _authHeaders());
    if (retryResponse.statusCode == HttpStatus.unauthorized) {
      await clearLocalSession();
    }
    return retryResponse;
  }

  Future<bool> _tryRefreshToken() async {
    final refreshToken = UserSession().getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final uri = Uri.parse('$baseUrl/api/v1/auth/refresh');
      final res = await _post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );
      if (res.statusCode != HttpStatus.ok) return false;
      final body = jsonDecode(res.body);
      if (body is! Map<String, dynamic>) return false;
      final newAccessToken = body['access_token'] as String?;
      if (newAccessToken == null || newAccessToken.isEmpty) return false;
      await UserSession().setAccessToken(newAccessToken);
      return true;
    } catch (e) {
      print('Refresh token request failed = $e');
      return false;
    }
  }

  static Future<void> clearLocalSession() async {
    await clearCurrentUserId();
    await UserSession().clear();
  }

  Future<Map<String, String>> _authHeaders() async {
    var token = UserSession().getAccessToken();
    if (token == null || token.isEmpty) {
      token = await const FlutterSecureStorage().read(key: _secureAuthTokenKey);
      if (token != null && token.isNotEmpty) {
        await UserSession().setAccessToken(token);
      }
    }
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }
}
