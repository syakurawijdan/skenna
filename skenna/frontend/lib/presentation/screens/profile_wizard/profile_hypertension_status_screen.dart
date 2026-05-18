import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../domain/natrium_classifier.dart';
import '../../navigation/app_routes.dart';
import 'profile_wizard_store.dart';

class ProfileHypertensionStatusScreen extends StatefulWidget {
  const ProfileHypertensionStatusScreen({super.key});

  @override
  State<ProfileHypertensionStatusScreen> createState() =>
      _ProfileHypertensionStatusScreenState();
}

class _ProfileHypertensionStatusScreenState
    extends State<ProfileHypertensionStatusScreen> {
  bool? _hasHypertension;

  @override
  void initState() {
    super.initState();
    _hasHypertension = ProfileWizardStore.instance.draft.hasHypertension;
  }

  Future<void> _next() async {
    if (_hasHypertension == null) {
      return;
    }
    ProfileWizardStore.instance.draft.hasHypertension = _hasHypertension!;

    if (_hasHypertension!) {
      // If has hypertension, go to hypertension condition screen
      Navigator.pushNamed(context, AppRoutes.profileHypertensionCondition);
    } else {
      // If no hypertension, skip to pregnancy screen (or dashboard if male)
      final draft = ProfileWizardStore.instance.draft;
      final gender = draft.gender.trim().toLowerCase();
      if (gender == 'perempuan' || gender == 'female') {
        Navigator.pushNamed(context, AppRoutes.profilePregnancy);
      } else {
        final hasil = await klasifikasiNatriumDariDraft(
          birthDate: draft.birthDate!,
          gender: draft.gender,
          hasHypertension: false,
          systolicPressure: draft.systolicPressure,
          diastolicPressure: draft.diastolicPressure,
        );
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          routeUntukKategori(hasil.kategori),
          (route) => false,
          arguments: hasil,
        );
      }
    }
  }

  Widget _radioOption({
    required bool selected,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFDFE4ED) : Colors.white,
          border: Border.all(color: const Color(0xFFBEC7DB), width: 1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
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
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF2C4A8A),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFormValid = _hasHypertension != null;
    final progress = ProfileWizardStore.instance.progressForStep(
      ProfileWizardStep.hypertensionStatus,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 72),
          child: Column(
            children: [
              const SizedBox(height: 64),
              // Progress bar
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
              // Illustration
              Center(
                child: Image.asset(
                  'assets/illustrations/tensi.png',
                  width: 302,
                  height: 302,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 32),
              // Title
              Center(
                child: Text(
                  'Punya hipertensi?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    color: const Color(0xFF2C4A8A),
                    fontSize: 31,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Options
              Center(
                child: SizedBox(
                  width: 344,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _radioOption(
                        selected: _hasHypertension == true,
                        label: 'Ya, saya punya riwayat hipertensi',
                        onTap: () {
                          setState(() {
                            _hasHypertension = true;
                          });
                        },
                      ),
                      _radioOption(
                        selected: _hasHypertension == false,
                        label: 'Tidak, saya tidak punya riwayat hipertensi',
                        onTap: () {
                          setState(() {
                            _hasHypertension = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32),
              // Helper text and button
              Center(
                child: SizedBox(
                  width: 344,
                  child: Column(
                    children: [
                      Text(
                        'Semakin lengkap data yang kamu isi, semakin akurat hasil analisis dari Skenna',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF2C4A8A),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: isFormValid ? _next : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFormValid
                                ? const Color(0xFF2C4A8A)
                                : const Color(0xFFBEC7DB),
                            disabledBackgroundColor: const Color(0xFFBEC7DB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            'Selanjutnya',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 58),
            ],
          ),
        ),
      ),
    );
  }
}
