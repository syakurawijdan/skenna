import 'package:logger/logger.dart';

import '../../data/user_session.dart';

class AppInitService {
  final UserSession userSession = UserSession();
  final logger = Logger();

  Future<void> init() async {
    try {
      await userSession.init();
      logger.i('Session initialized, userId: ${userSession.getUserId()}');
    } catch (e) {
      logger.w('Init failed: $e');
    }
  }
}
