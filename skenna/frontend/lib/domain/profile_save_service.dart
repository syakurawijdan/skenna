import 'package:logger/logger.dart';

import '../../data/api_client.dart';
import '../../data/user_session.dart';
import '../../presentation/screens/profile_wizard/profile_wizard_store.dart';

/// Service untuk save profile ke backend dengan proper error handling
class ProfileSaveService {
  final ApiClient apiClient = ApiClient();
  final UserSession userSession = UserSession();
  final logger = Logger();

  /// Save wizard data to backend database
  /// Returns map with success status and message
  Future<Map<String, dynamic>> saveProfile() async {
    try {
      final userId = userSession.getUserId();
      if (userId <= 0) {
        return {'success': false, 'message': 'User ID tidak valid'};
      }

      final draft = ProfileWizardStore.instance.draft;

      // Validate required fields
      if (draft.fullName.isEmpty ||
          draft.gender.isEmpty ||
          draft.birthDate == null) {
        return {
          'success': false,
          'message':
              'Data tidak lengkap (nama, gender, atau tanggal lahir kosong)',
        };
      }

      logger.i('Saving profile for user $userId: ${draft.fullName}');

      // Call backend API
      final response = await apiClient.upsertUserProfile(
        userId: userId,
        fullName: draft.fullName,
        gender: draft.gender,
        birthDate: draft.birthDate!,
        hasHypertension: draft.hasHypertension ?? false,
        hypertensionCondition: draft.hypertensionCondition,
        systolicPressure: draft.systolicPressure,
        diastolicPressure: draft.diastolicPressure,
        pregnancyStatus: draft.pregnancyStatus,
      );

      logger.i('Profile saved successfully: $response');
      return {
        'success': true,
        'message': response['message'] ?? 'Profile berhasil disimpan',
      };
    } catch (e, stackTrace) {
      logger.e('Failed to save profile', error: e, stackTrace: stackTrace);
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}
