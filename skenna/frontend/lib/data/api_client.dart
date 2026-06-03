import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Tambahkan import ini

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const String _apiBaseUrlFromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  // ====================== MANAJEMEN USER ID TERPUSAT ======================
  static const _keyCurrentUserId = 'current_logged_user_id';
  static int? _currentUserIdCache; // Cache di memory untuk akses cepat

  /// Ambil user ID yang sedang login (dari cache atau SharedPreferences)
  static Future<int> get currentUserId async {
    if (_currentUserIdCache != null) return _currentUserIdCache!;

    final prefs = await SharedPreferences.getInstance();
    // JANGAN gunakan fallback ke 1! Gunakan error agar mudah debug
    if (!prefs.containsKey(_keyCurrentUserId)) {
      throw Exception(
        'User ID belum diset! Pastikan kamu login/daftar terlebih dahulu.',
      );
    }

    _currentUserIdCache = prefs.getInt(_keyCurrentUserId)!;
    debugPrint('Ambil current user ID: $_currentUserIdCache');
    return _currentUserIdCache!;
  }

  /// Simpan user ID yang sedang login (ke cache dan SharedPreferences)
  static Future<void> setCurrentUserId(int userId) async {
    _currentUserIdCache = userId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCurrentUserId, userId);
    debugPrint('Simpan current user ID: $userId');
  }

  /// Hapus user ID (untuk logout)
  static Future<void> clearCurrentUserId() async {
    _currentUserIdCache = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentUserId);
    debugPrint('Hapus current user ID');
  }
  // ===========================================================================

  String get baseUrl {
    if (_apiBaseUrlFromEnv.isNotEmpty) {
      return _apiBaseUrlFromEnv;
    }

    if (kIsWeb) return 'http://localhost:8000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://192.168.1.9:8000';
  }

  // ====================== METHOD API (USER ID JADI OPSIONAL) ======================
  // Semua parameter `userId` sekarang opsional, default menggunakan `currentUserId` terpusat

  Future<Map<String, dynamic>> classifySodium(double sodiumMg) async {
    final uri = Uri.parse('$baseUrl/api/v1/sodium/classify');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'sodium_mg': sodiumMg, 'serving_size_g': 100}),
    );
    return _decodeMap(res);
  }

  // Auto-set current user ID setelah buat demo user
  Future<Map<String, dynamic>> createDemoUser() async {
    final uri = Uri.parse('$baseUrl/api/v1/users/demo');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
    );
    if (res.statusCode >= 400) {
      throw Exception(
        'Failed to create demo user: ${res.statusCode} ${res.body}',
      );
    }
    final result = _decodeMap(res);
    // Auto simpan user ID dari response
    if (result['user_id'] != null) {
      await setCurrentUserId(result['user_id'] as int);
    }
    return result;
  }

  Future<Map<String, dynamic>> scanLabel(String imageUrl) async {
    final uri = Uri.parse('$baseUrl/api/v1/cv/scan');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'image_url': imageUrl}),
    );
    return _decodeMap(res);
  }

  Future<Map<String, dynamic>> askChatbot({
    int? userId, // Opsional
    required String question,
  }) async {
    final effectiveUserId = userId ?? await currentUserId;
    final uri = Uri.parse('$baseUrl/api/v1/chatbot/ask');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': effectiveUserId, 'question': question}),
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
      if (systolicPressure != null) 'systolic_pressure': systolicPressure,
      if (diastolicPressure != null) 'diastolic_pressure': diastolicPressure,
      if (pregnancyStatus != null) 'pregnancy_status': pregnancyStatus,
    };

    final res = await _client.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (res.statusCode >= 400) {
      throw Exception('Failed to save profile: ${res.statusCode} ${res.body}');
    }

    return _decodeMap(res);
  }

  Future<List<dynamic>> getIntakeHistory([int? userId]) async {
    final effectiveUserId = userId ?? await currentUserId;
    final uri = Uri.parse(
      '$baseUrl/api/v1/history/intake?user_id=$effectiveUserId',
    );
    for (int i = 0; i < 3; i++) {
      try {
        final res = await _client.get(uri);
        final body = _decodeJson(res);
        if (body is List<dynamic>) return body;
        if (body is Map<String, dynamic> && body['value'] is List<dynamic>) {
          return body['value'] as List<dynamic>;
        }
        return <dynamic>[];
      } catch (e) {
        if (i == 2) rethrow;
        await Future.delayed(Duration(seconds: i + 1));
      }
    }
    return <dynamic>[];
  }

  Future<List<dynamic>> getChatHistory([int? userId]) async {
    final effectiveUserId = userId ?? await currentUserId;
    final uri = Uri.parse(
      '$baseUrl/api/v1/history/chat?user_id=$effectiveUserId',
    );
    final res = await _client.get(uri);
    final body = _decodeJson(res);
    if (body is List<dynamic>) {
      return body;
    }
    return <dynamic>[];
  }

  Future<Map<String, dynamic>> postScanHistory({
    int? userId, // Opsional
    required int sodiumMg,
    required int servings,
    String? productName,
    String? sodiumLevel,
    String? kategori,
    String type = 'single',
    String? productName2,
    int? sodiumMg2,
    String? imagePath2,
    bool isConsumed = false,
    int packageMl = 0,
    int portionsInPackage = 1,
    String satuanTakaran = 'g',
    int packageMl2 = 0,
    int portionsInPackage2 = 1,
    String satuanTakaran2 = 'g',
  }) async {
    final effectiveUserId = userId ?? await currentUserId;
    final uri = Uri.parse('$baseUrl/api/v1/history/intake');
    final body = {
      'user_id': effectiveUserId,
      'food_name': productName ?? 'Produk',
      'sodium_mg': sodiumMg,
      'sodium_level':
          sodiumLevel ??
          (sodiumMg < 140
              ? 'low'
              : sodiumMg < 400
              ? 'medium'
              : 'high'),
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
    };

    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    return _decodeMap(res);
  }

  // Auto-set current user ID setelah register
  Future<Map<String, dynamic>> registerUser({required String fullName}) async {
    final uri = Uri.parse('$baseUrl/api/v1/users/register');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'full_name': fullName}),
    );
    if (res.statusCode >= 400) {
      throw Exception('Failed to register user: ${res.statusCode} ${res.body}');
    }
    final result = _decodeMap(res);
    // Auto simpan user ID dari response
    if (result['user_id'] != null) {
      await setCurrentUserId(result['user_id'] as int);
    }
    return result;
  }

  Future<Map<String, dynamic>> getUserProfile([int? userId]) async {
    final effectiveUserId = userId ?? await currentUserId;
    final uri = Uri.parse('$baseUrl/api/v1/users/$effectiveUserId/profile');
    final res = await _client.get(uri);
    debugPrint('=== getUserProfile status: ${res.statusCode}');
    debugPrint('=== getUserProfile body: ${res.body}');
    return _decodeMap(res);
  }

  dynamic _decodeJson(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('API error ${response.statusCode}: ${response.body}');
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
    int? servings,
  }) async {
    final effectiveUserId = userId ?? await currentUserId;
    debugPrint('API userId: $effectiveUserId');
    final uri = Uri.parse('$baseUrl/api/v1/history/intake/$intakeId');
    debugPrint('PATCH URL: $uri');
    final body = jsonEncode({
      'user_id': effectiveUserId,
      'is_consumed': isConsumed,
      if (servings != null) 'servings': servings,
    });
    debugPrint('body: $body');
    final res = await _client.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    debugPrint('PATCH status: ${res.statusCode}');
    debugPrint('PATCH response: ${res.body}');
    return _decodeMap(res);
  }
}
