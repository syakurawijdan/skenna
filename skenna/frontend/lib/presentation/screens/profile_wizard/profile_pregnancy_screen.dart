import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../domain/natrium_classifier.dart';
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
    _statusKehamilan = draft.pregnancyStatus;

    if (_isMale) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(context);
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
      routeUntukKategori(hasil.kategori),
      (route) => false,
      arguments: hasil,
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
    if (_isMale) {
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
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
                  'assets/illustrations/pregnant.png',
                  width: 302,
                  height: 302,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'Status kehamilan',
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
              Center(
                child: SizedBox(
                  width: 344,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _optionCard(
                        selected: _statusKehamilan == 'pregnant',
                        label: 'Saya sedang hamil',
                        onTap: () {
                          setState(() {
                            _statusKehamilan = 'pregnant';
                          });
                        },
                      ),
                      _optionCard(
                        selected: _statusKehamilan == 'breastfeeding',
                        label: 'Saya sedang menyusui',
                        onTap: () {
                          setState(() {
                            _statusKehamilan = 'breastfeeding';
                          });
                        },
                      ),
                      _optionCard(
                        selected: _statusKehamilan == 'none',
                        label: 'Tidak keduanya',
                        onTap: () {
                          setState(() {
                            _statusKehamilan = 'none';
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
                          onPressed: isFormValid ? _submit : null,
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
