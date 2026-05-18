import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../domain/natrium_classifier.dart';
import '../../navigation/app_routes.dart';
import 'profile_wizard_store.dart';

class ProfileBloodPressureScreen extends StatefulWidget {
  const ProfileBloodPressureScreen({super.key});

  @override
  State<ProfileBloodPressureScreen> createState() =>
      _ProfileBloodPressureScreenState();
}

class _ProfileBloodPressureScreenState
    extends State<ProfileBloodPressureScreen> {
  late final TextEditingController _systolicController;
  late final TextEditingController _diastolicController;

  @override
  void initState() {
    super.initState();
    final draft = ProfileWizardStore.instance.draft;
    _systolicController = TextEditingController(
      text: draft.systolicPressure?.toString() ?? '',
    );
    _diastolicController = TextEditingController(
      text: draft.diastolicPressure?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    super.dispose();
  }

  bool get _isMale {
    final gender = ProfileWizardStore.instance.draft.gender
        .trim()
        .toLowerCase();
    return gender == 'laki-laki' || gender == 'laki_laki' || gender == 'male';
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.plusJakartaSans(
        color: const Color(0xFFB0B0B0),
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

  Future<void> _goNext() async {
    final systolic = int.tryParse(_systolicController.text.trim());
    final diastolic = int.tryParse(_diastolicController.text.trim());

    ProfileWizardStore.instance.draft.systolicPressure = systolic;
    ProfileWizardStore.instance.draft.diastolicPressure = diastolic;

    if (_isMale) {
      final draft = ProfileWizardStore.instance.draft;
      final hasil = await klasifikasiNatriumDariDraft(
        birthDate: draft.birthDate!,
        gender: draft.gender,
        hasHypertension: draft.hasHypertension,
        hypertensionCondition: draft.hypertensionCondition,
        systolicPressure: systolic,
        diastolicPressure: diastolic,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        routeUntukKategori(hasil.kategori),
        (route) => false,
        arguments: hasil,
      );
      return;
    }

    Navigator.pushNamed(context, AppRoutes.profilePregnancy);
  }

  Future<void> _skip() async {
    ProfileWizardStore.instance.draft.systolicPressure = null;
    ProfileWizardStore.instance.draft.diastolicPressure = null;

    if (_isMale) {
      final draft = ProfileWizardStore.instance.draft;
      final hasil = await klasifikasiNatriumDariDraft(
        birthDate: draft.birthDate!,
        gender: draft.gender,
        hasHypertension: draft.hasHypertension,
        hypertensionCondition: draft.hypertensionCondition,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        routeUntukKategori(hasil.kategori),
        (route) => false,
        arguments: hasil,
      );
      return;
    }

    Navigator.pushNamed(context, AppRoutes.profilePregnancy);
  }

  @override
  Widget build(BuildContext context) {
    final progress = ProfileWizardStore.instance.progressForStep(
      ProfileWizardStep.bloodPressure,
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
                  'assets/illustrations/tensi.png',
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
                    'Isi tekanan darah',
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
                  width: 315,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sistolik',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF2C4A8A),
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 55,
                              child: TextField(
                                controller: _systolicController,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF2C4A8A),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                                decoration: _inputDecoration('Isi sistolik'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Diastolik',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF2C4A8A),
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 55,
                              child: TextField(
                                controller: _diastolicController,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF2C4A8A),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                                decoration: _inputDecoration('Isi diastolik'),
                              ),
                            ),
                          ],
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
                      SizedBox(
                        width: 344,
                        height: 55,
                        child: FilledButton(
                          onPressed: _goNext,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2C4A8A),
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
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 344,
                        height: 55,
                        child: GestureDetector(
                          onTap: _skip,
                          child: Center(
                            child: Text(
                              'Lewati',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF2C4A8A),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
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
