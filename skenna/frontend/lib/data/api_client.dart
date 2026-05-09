import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const String _apiBaseUrlFromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  String get baseUrl {
    if (_apiBaseUrlFromEnv.isNotEmpty) {
      return _apiBaseUrlFromEnv;
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  Future<Map<String, dynamic>> classifySodium(double sodiumMg) async {
    final uri = Uri.parse('$baseUrl/api/v1/sodium/classify');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'sodium_mg': sodiumMg, 'serving_size_g': 100}),
    );
    return _decodeMap(res);
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
    required int userId,
    required String question,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/chatbot/ask');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'question': question}),
    );
    return _decodeMap(res);
  }

  Future<Map<String, dynamic>> upsertUserProfile({
    required int userId,
    required String fullName,
    required String gender,
    required DateTime birthDate,
    required bool hasHypertension,
    required int systolicPressure,
    required int diastolicPressure,
    required bool isPregnant,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/users/$userId/profile');
    final res = await _client.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'full_name': fullName,
        'gender': gender,
        'birth_date': birthDate.toIso8601String().split('T').first,
        'has_hypertension': hasHypertension,
        'systolic_pressure': systolicPressure,
        'diastolic_pressure': diastolicPressure,
        'is_pregnant': isPregnant,
      }),
    );
    return _decodeMap(res);
  }

  Future<List<dynamic>> getIntakeHistory(int userId) async {
    final uri = Uri.parse('$baseUrl/api/v1/history/intake?user_id=$userId');
    final res = await _client.get(uri);
    final body = _decodeJson(res);
    if (body is Map<String, dynamic> && body['value'] is List<dynamic>) {
      return body['value'] as List<dynamic>;
    }
    if (body is List<dynamic>) {
      return body;
    }
    return <dynamic>[];
  }

  Future<List<dynamic>> getChatHistory(int userId) async {
    final uri = Uri.parse('$baseUrl/api/v1/history/chat?user_id=$userId');
    final res = await _client.get(uri);
    final body = _decodeJson(res);
    if (body is List<dynamic>) {
      return body;
    }
    return <dynamic>[];
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
}
