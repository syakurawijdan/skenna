import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/api_client.dart';
import '../../navigation/app_routes.dart';
import 'profile_wizard_store.dart';

class ProfilePregnancyScreen extends StatefulWidget {
  const ProfilePregnancyScreen({super.key});

  @override
  State<ProfilePregnancyScreen> createState() => _ProfilePregnancyScreenState();
}

class _ProfilePregnancyScreenState extends State<ProfilePregnancyScreen> {
  final ApiClient _apiClient = ApiClient();
  bool? _isPregnant;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final draft = ProfileWizardStore.instance.draft;
    _isPregnant = draft.isPregnant;

    // Jika laki-laki, langsung submit dan ke sodium screen
    final gender = draft.gender.toLowerCase();
    if (gender == 'laki-laki' || gender == 'male') {
      _submitProfile(isPregnant: false);
    }
  }

  Future<void> _submitProfile({required bool isPregnant}) async {
    final draft = ProfileWizardStore.instance.draft;

    if (draft.birthDate == null ||
        draft.gender.isEmpty ||
        draft.hasHypertension == null ||
        draft.systolicPressure == null ||
        draft.diastolicPressure == null) {
      _showMessage('Data belum lengkap, kembali ke langkah sebelumnya.');
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      draft.isPregnant = isPregnant;
      await _apiClient.upsertUserProfile(
        userId: 1,
        fullName: draft.fullName,
        gender: draft.gender,
        birthDate: draft.birthDate!,
        hasHypertension: draft.hasHypertension!,
        systolicPressure: draft.systolicPressure!,
        diastolicPressure: draft.diastolicPressure!,
        isPregnant: isPregnant,
      );

      if (!mounted) {
        return;
      }
      final nextRoute = _resolveSodiumRoute(draft);
      Navigator.pushNamed(context, nextRoute);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('Gagal menyimpan data profil: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_isPregnant == null) {
      _showMessage('Pilih apakah sedang hamil atau tidak');
      return;
    }

    await _submitProfile(isPregnant: _isPregnant!);
  }

  String _resolveSodiumRoute(ProfileWizardDraft draft) {
    if (draft.isPregnant == true) {
      return AppRoutes.sodiumPregnant;
    }

    final systolic = draft.systolicPressure ?? 0;
    final diastolic = draft.diastolicPressure ?? 0;

    final hasHypertensionRisk =
        draft.hasHypertension == true || systolic >= 130 || diastolic >= 80;

    if (hasHypertensionRisk) {
      return AppRoutes.sodiumUnsafe;
    }
    return AppRoutes.sodiumSafe;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Widget _radioOption({
    required bool selected,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isSubmitting ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF2C4A8A), width: 2),
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2C4A8A),
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF2C4A8A),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gender = ProfileWizardStore.instance.draft.gender;
    final isFemale =
        gender.toLowerCase() == 'perempuan' || gender.toLowerCase() == 'female';
    final isFormValid =
        !_isSubmitting && (isFemale ? _isPregnant != null : false);

    // Untuk laki-laki, tampilkan loading screen saat proses submit
    if (!isFemale) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const SafeArea(
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFF2C4A8A)),
          ),
        ),
      );
    }

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
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.pop(context),
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
                            Container(
                              width: 276,
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C4A8A),
                                borderRadius: BorderRadius.circular(100),
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
                  'assets/illustrations/pregnant.png',
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
                    'Sedang hamil?',
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
              SizedBox(
                width: 263,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 159,
                      child: _radioOption(
                        selected: _isPregnant == true,
                        label: 'Ya, saya hamil',
                        onTap: () => setState(() => _isPregnant = true),
                      ),
                    ),
                    SizedBox(
                      width: 88,
                      child: _radioOption(
                        selected: _isPregnant == false,
                        label: 'Tidak',
                        onTap: () => setState(() => _isPregnant = false),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
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
                          onPressed: isFormValid ? _submit : null,
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
                            _isSubmitting ? 'Menyimpan...' : 'Selanjutnya',
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
