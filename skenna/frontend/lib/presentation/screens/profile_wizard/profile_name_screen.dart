import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../navigation/app_routes.dart';
import 'profile_step_layout.dart';
import 'profile_wizard_store.dart';
import '../../../data/api_client.dart';
import '../../../data/user_session.dart';

class ProfileFormScreen extends StatefulWidget {
  const ProfileFormScreen({super.key});

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    ProfileWizardStore.instance.reset();
    _nameController = TextEditingController(
      text: ProfileWizardStore.instance.draft.fullName,
    );
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _next() async {
    final value = _nameController.text.trim();
    if (value.isEmpty) {
      _showValidation('Nama wajib diisi');
      return;
    }
    ProfileWizardStore.instance.draft.fullName = value;

    try {
      final userSession = UserSession();
      final apiClient = ApiClient();

      final userId = userSession.getUserId();
      if (userId <= 0) {
        throw Exception('User ID belum tersedia');
      }

      debugPrint('Menyimpan nama user ke MySQL: $value');
      final response = await apiClient.updateUserFullName(
        userId: userId,
        fullName: value,
      );
      debugPrint('Update nama sukses: $response');
    } catch (e) {
      debugPrint('Gagal menyimpan nama user ke MySQL: $e');
      _showValidation('Gagal terhubung ke server. Coba lagi.');
      return;
    }

    Navigator.pushNamed(context, AppRoutes.profileGender);
  }

  void _showValidation(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      hintText: 'Isi nama panggilan kamu',
      hintStyle: GoogleFonts.plusJakartaSans(
        color: const Color(0xFFB0B0B0),
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      filled: false,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFBEC7DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFBEC7DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2C4A8A)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFormValid = _nameController.text.trim().isNotEmpty;
    final progress = ProfileWizardStore.instance.progressForStep(
      ProfileWizardStep.name,
    );

    return ProfileStepLayout(
      progress: progress,
      illustrationAsset: 'assets/illustrations/namauser.png',
      title: 'Yuk, kenalan',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nama panggilan',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF2C4A8A),
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 55,
            child: TextField(
              controller: _nameController,
              keyboardType: TextInputType.name,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF2C4A8A),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              decoration: _fieldDecoration(),
            ),
          ),
        ],
      ),
      subtitle: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF2C4A8A),
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.3,
          ),
          children: const [
            TextSpan(text: 'Semakin '),
            TextSpan(
              text: 'lengkap data',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: ' yang kamu isi,\nsemakin '),
            TextSpan(
              text: 'akurat',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: ' hasil analisis dari'),
            TextSpan(
              text: ' Skenna',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      primaryButton: FilledButton(
        onPressed: isFormValid ? _next : null,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2C4A8A),
          disabledBackgroundColor: const Color(0xFFD9D9D9),
          elevation: 4,
          shadowColor: const Color(0x40000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Text(
          'Selanjutnya',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
      ),
    );
  }
}
