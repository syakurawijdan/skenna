import 'package:shared_preferences/shared_preferences.dart';

/// User session manager - handle user_id storage & retrieval
/// Ensures every user action has valid user context
class UserSession {
  static const String _userIdKey = 'user_id';
  late final SharedPreferences _prefs;

  UserSession._();
  static final UserSession _instance = UserSession._();

  factory UserSession() {
    return _instance;
  }

  /// Initialize session (must call on app startup)
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get current user_id, or 0 if not set
  int getUserId() {
    return _prefs.getInt(_userIdKey) ?? 0;
  }

  /// Set user_id (called after demo user creation or login)
  Future<void> setUserId(int userId) async {
    await _prefs.setInt(_userIdKey, userId);
  }

  /// Clear session (on logout)
  Future<void> clear() async {
    await _prefs.remove(_userIdKey);
  }

  /// Check if user session valid
  bool isLoggedIn() {
    return getUserId() > 0;
  }
}
