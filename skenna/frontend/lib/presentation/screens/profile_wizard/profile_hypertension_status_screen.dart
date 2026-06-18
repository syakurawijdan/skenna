import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../domain/natrium_classifier.dart';
import '../../navigation/app_routes.dart';
import 'profile_step_layout.dart';
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
      Navigator.pushNamed(context, AppRoutes.profileHypertensionCondition);
    } else {
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
          routeUntukCategoryKey(hasil.categoryKey),
          (route) => false,
          arguments: {'categoryKey': hasil.categoryKey, 'hasil': hasil},
        );
      }
    }
  }

  Widget _radioOption({
    required bool selected,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? const Color(0xFFDFE4ED) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFBEC7DB),
                width: selected ? 1 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF2C4A8A),
                      width: 2,
                    ),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
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

    return ProfileStepLayout(
      progress: progress,
      illustrationAsset: 'assets/illustrations/tensi.png',
      title: 'Punya hipertensi?',
      content: Column(
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
            TextSpan(text: ' hasil analisis dari Skenna'),
          ],
        ),
      ),
      primaryButton: FilledButton(
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
            fontSize: 19,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
      ),
    );
  }
}
