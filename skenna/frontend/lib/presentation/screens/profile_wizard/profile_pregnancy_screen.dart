import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../domain/natrium_classifier.dart';
import 'profile_step_layout.dart';
import 'profile_wizard_store.dart';

class ProfilePregnancyScreen extends StatefulWidget {
  const ProfilePregnancyScreen({super.key});

  @override
  State<ProfilePregnancyScreen> createState() => _ProfilePregnancyScreenState();
}

class _ProfilePregnancyScreenState extends State<ProfilePregnancyScreen> {
  String? _statusKehamilan;

  @override
  void initState() {
    super.initState();
    final draft = ProfileWizardStore.instance.draft;
    _statusKehamilan = _normalizeUiPregnancyStatus(draft.pregnancyStatus);

    if (_isMale) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } else if (_shouldSkipPregnancyQuestion) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _navigateToResult(statusKehamilan: 'tidak_hamil');
        }
      });
    }
  }

  bool get _isMale {
    final gender = ProfileWizardStore.instance.draft.gender
        .trim()
        .toLowerCase();
    return gender == 'laki-laki' || gender == 'laki_laki' || gender == 'male';
  }

  bool get _shouldSkipPregnancyQuestion {
    final birthDate = ProfileWizardStore.instance.draft.birthDate;
    if (birthDate == null) return false;

    // SKI 2023 defines wanita usia subur as ages 10-54 for anthropometry.
    final usia = hitungUsiaTahun(birthDate);
    return usia < 10 || usia > 54;
  }

  String? _normalizeUiPregnancyStatus(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == 'pregnant' || normalized == 'breastfeeding') {
      return 'pregnant';
    }
    if (normalized == 'none') {
      return 'none';
    }
    return null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _navigateToResult({required String statusKehamilan}) async {
    final draft = ProfileWizardStore.instance.draft;
    draft.pregnancyStatus = statusKehamilan;
    final hasil = await klasifikasiNatriumDariDraft(
      birthDate: draft.birthDate!,
      gender: draft.gender,
      hasHypertension: draft.hasHypertension,
      hypertensionCondition: draft.hypertensionCondition,
      systolicPressure: draft.systolicPressure,
      diastolicPressure: draft.diastolicPressure,
      pregnancyStatus: statusKehamilan,
    );
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      routeUntukCategoryKey(hasil.categoryKey),
      (route) => false,
      arguments: {'categoryKey': hasil.categoryKey, 'hasil': hasil},
    );
  }

  Future<void> _submit() async {
    if (_statusKehamilan == null) {
      _showMessage('Pilih status kehamilan');
      return;
    }
    await _navigateToResult(statusKehamilan: _statusKehamilan!);
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
    if (_isMale || _shouldSkipPregnancyQuestion) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const SafeArea(
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFF2C4A8A)),
          ),
        ),
      );
    }

    final isFormValid = _statusKehamilan != null;
    final progress = ProfileWizardStore.instance.progressForStep(
      ProfileWizardStep.pregnancy,
    );

    return ProfileStepLayout(
      progress: progress,
      illustrationAsset: 'assets/illustrations/pregnant.png',
      title: 'Sedang hamil atau menyusui?',
      content: Column(
        children: [
          const SizedBox(height: 16),
          _optionCard(
            selected: _statusKehamilan == 'pregnant',
            label: 'Hamil atau Menyusui',
            onTap: () {
              setState(() {
                _statusKehamilan = 'pregnant';
              });
            },
          ),
          _optionCard(
            selected: _statusKehamilan == 'none',
            label: 'Tidak Keduanya',
            onTap: () {
              setState(() {
                _statusKehamilan = 'none';
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
            TextSpan(text: ' hasil analisis dari'),
            TextSpan(
              text: ' Skenna',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      primaryButton: FilledButton(
        onPressed: isFormValid ? _submit : null,
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
