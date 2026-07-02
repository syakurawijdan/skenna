import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../navigation/app_routes.dart';
import 'profile_step_layout.dart';
import 'profile_wizard_store.dart';

class ProfileHypertensionConditionScreen extends StatefulWidget {
  const ProfileHypertensionConditionScreen({super.key});

  @override
  State<ProfileHypertensionConditionScreen> createState() =>
      _ProfileHypertensionConditionScreenState();
}

class _ProfileHypertensionConditionScreenState
    extends State<ProfileHypertensionConditionScreen> {
  String? _condition;

  @override
  void initState() {
    super.initState();
    _condition = ProfileWizardStore.instance.draft.hypertensionCondition;
  }

  void _next() {
    if (_condition == null) return;
    ProfileWizardStore.instance.draft.hasHypertension = true;
    ProfileWizardStore.instance.draft.hypertensionCondition = _condition!;
    Navigator.pushNamed(context, AppRoutes.profileBloodPressure);
  }

  Widget _optionCard({
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
    final isFormValid = _condition != null;
    final progress = ProfileWizardStore.instance.progressForStep(
      ProfileWizardStep.hypertensionCondition,
    );

    return ProfileStepLayout(
      progress: progress,
      illustrationAsset: 'assets/illustrations/tensi.png',
      title: 'Pilih Kondisi',
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
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _optionCard(
              selected: _condition == 'history_only',
              label: 'Pernah mengalami hipertensi, saat ini terkontrol',
              // value: 'history_only',
              onTap: () => setState(() => _condition = 'history_only'),
            ),
            _optionCard(
              selected: _condition == 'controlled',
              label: 'Sedang hipertensi, terkontrol dengan obat',
              // value: 'controlled',
              onTap: () => setState(() => _condition = 'controlled'),
            ),
            _optionCard(
              selected: _condition == 'uncontrolled',
              label: 'Sedang hipertensi, belum terkontrol',
              // value: 'uncontrolled',
              onTap: () => setState(() => _condition = 'uncontrolled'),
            ),
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
