import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static const String _userIdKey = 'user_id';
  static const String _apiCurrentUserIdKey = 'current_logged_user_id';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _hasCompletedOnboardingKey = 'has_completed_onboarding';

  late SharedPreferences _prefs; // ← ganti dari 'late final' ke 'late'
  bool _initialized = false;

  UserSession._();
  static final UserSession _instance = UserSession._();

  factory UserSession() => _instance;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  int getUserId() {
    final userId = _prefs.getInt(_userIdKey);
    final apiUserId = _prefs.getInt(_apiCurrentUserIdKey);
    final resolved = userId ?? apiUserId ?? 0;
    debugPrint(
      'UserSession.getUserId => user_id=$userId, '
      'current_logged_user_id=$apiUserId, resolved=$resolved',
    );
    return resolved;
  }

  Future<void> setUserId(int userId) async {
    await _prefs.setInt(_userIdKey, userId);
    await _prefs.setInt(_apiCurrentUserIdKey, userId);
    debugPrint('UserSession.setUserId => synced user ID: $userId');
  }

  String? getAccessToken() {
    return _prefs.getString(_accessTokenKey);
  }

  Future<void> setAccessToken(String token) async {
    await _prefs.setString(_accessTokenKey, token);
    debugPrint('UserSession.setAccessToken => token stored');
  }

  String? getRefreshToken() {
    return _prefs.getString(_refreshTokenKey);
  }

  Future<void> setRefreshToken(String token) async {
    await _prefs.setString(_refreshTokenKey, token);
    debugPrint('UserSession.setRefreshToken => token stored');
  }

  Future<void> clear() async {
    await _prefs.remove(_userIdKey);
    await _prefs.remove(_apiCurrentUserIdKey);
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
    debugPrint('UserSession.clear => removed stored user IDs');
  }

  bool isLoggedIn() => getUserId() > 0;

  bool hasCompletedOnboarding() {
    return _prefs.getBool(_hasCompletedOnboardingKey) ?? false;
  }

  Future<void> setHasCompletedOnboarding(bool value) async {
    await _prefs.setBool(_hasCompletedOnboardingKey, value);
    debugPrint('UserSession.setHasCompletedOnboarding => $value');
  }
}
