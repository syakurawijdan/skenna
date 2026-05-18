import 'package:logger/logger.dart';

import '../../data/api_client.dart';
import '../../data/user_session.dart';

/// Service untuk initialize app pada startup
/// - Initialize session storage
/// - Create/get demo user
/// - Store user_id
class AppInitService {
  final ApiClient apiClient = ApiClient();
  final UserSession userSession = UserSession();
  final logger = Logger();

  /// Initialize app - must call on app startup
  Future<void> init() async {
    try {
      logger.i('Initializing app...');

      // Init session storage
      await userSession.init();
      logger.i('User session initialized');

      // Check if user already exists
      int? savedUserId = userSession.isLoggedIn()
          ? userSession.getUserId()
          : null;

      if (savedUserId != null && savedUserId > 0) {
        logger.i('User already logged in: $savedUserId');
        return;
      }

      // Create demo user
      logger.i('Creating demo user...');
      final response = await apiClient.createDemoUser();

      if (response['id'] != null) {
        final userId = response['id'] as int;
        await userSession.setUserId(userId);
        logger.i('Demo user created and session stored: $userId');
      } else {
        logger.w('Failed to get user_id from demo user response: $response');
      }
    } catch (e, stackTrace) {
      logger.e('Failed to initialize app', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
