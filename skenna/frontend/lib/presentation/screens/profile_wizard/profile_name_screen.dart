import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../navigation/app_routes.dart';
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
    UserSession().clear();
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

      debugPrint('Mendaftarkan user baru ke MySQL: $value');

      // PENTING: Langsung tembak register tanpa mengecek isLoggedIn()
      // agar MySQL selalu melahirkan ID baru (seperti ID 14, 15, dst)
      final response = await apiClient.registerUser(fullName: value);
      debugPrint('Register response sukses: $response');

      // Ambil ID baru dari MySQL dan timpa (overwrite) id lama di SharedPreferences
      final int newUserId = response['id'] as int;
      await userSession.setUserId(newUserId);

      debugPrint(
        'UserSession berhasil diperbarui dengan ID Baru: ${userSession.getUserId()}',
      );
    } catch (e) {
      debugPrint('Gagal registrasi user ke MySQL: $e');
      // Tambahkan snackbar error agar kamu tahu jika API Register gagal/mati
      _showValidation('Gagal terhubung ke server. Coba lagi.');
      return; // Hentikan navigasi jika register gagal
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
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFBEC7DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFBEC7DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 72),
          child: Column(
            children: [
              const SizedBox(height: 64),
              Center(
                child: SizedBox(
                  width: 327,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 35,
                        height: 35,
                        child: IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFDFE4ED),
                            padding: const EdgeInsets.all(8),
                          ),
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFF2C4A8A),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 276,
                        height: 8,
                        child: Stack(
                          children: [
                            Container(
                              width: 276,
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6E6E6),
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: progress,
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2C4A8A),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Image.asset(
                  'assets/illustrations/namauser.png',
                  width: 302,
                  height: 302,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: SizedBox(
                  width: 380,
                  child: Text(
                    'Yuk, kenalan',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFF2C4A8A),
                      fontSize: 31,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: SizedBox(
                  width: 290,
                  child: Column(
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
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 55,
                        child: TextField(
                          controller: _nameController,
                          keyboardType: TextInputType.name,
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF2C4A8A),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: _fieldDecoration(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32),
              Center(
                child: SizedBox(
                  width: 344,
                  child: Column(
                    children: [
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF2C4A8A),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 1,
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
                            TextSpan(text: ' hasil analisis dari Skenna'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: 344,
                        height: 55,
                        child: FilledButton(
                          onPressed: isFormValid ? _next : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2C4A8A),
                            disabledBackgroundColor: const Color(0xFFB0B0B0),
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
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
