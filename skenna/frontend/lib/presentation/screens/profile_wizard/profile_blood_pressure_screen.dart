import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  void _next() {
    final systolic = int.tryParse(_systolicController.text);
    final diastolic = int.tryParse(_diastolicController.text);
    if (systolic == null || diastolic == null) {
      _showValidation('Isi sistolik dan diastolik dengan angka');
      return;
    }
    if (systolic < 50 || systolic > 300) {
      _showValidation('Sistolik harus di antara 50-300 mmHg');
      return;
    }
    if (diastolic < 30 || diastolic > 200) {
      _showValidation('Diastolik harus di antara 30-200 mmHg');
      return;
    }
    final draft = ProfileWizardStore.instance.draft;
    draft.systolicPressure = systolic;
    draft.diastolicPressure = diastolic;
    Navigator.pushNamed(context, AppRoutes.profilePregnancy);
  }

  void _skip() {
    if (!_canSkipBloodPressureInput) {
      return;
    }
    final draft = ProfileWizardStore.instance.draft;
    // Default normal blood pressure when user has no hypertension history and skips this step.
    draft.systolicPressure = 120;
    draft.diastolicPressure = 80;
    Navigator.pushNamed(context, AppRoutes.profilePregnancy);
  }

  void _showValidation(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  InputDecoration _fieldDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.plusJakartaSans(
        color: const Color(0xFFB0B0B0),
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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

  bool get _isFormValid {
    final systolic = int.tryParse(_systolicController.text);
    final diastolic = int.tryParse(_diastolicController.text);
    return systolic != null &&
        diastolic != null &&
        systolic >= 50 &&
        systolic <= 300 &&
        diastolic >= 30 &&
        diastolic <= 200;
  }

  bool get _canSkipBloodPressureInput {
    return ProfileWizardStore.instance.draft.hasHypertension == false;
  }

  @override
  Widget build(BuildContext context) {
    final isFormValid = _isFormValid;
    final canSkip = _canSkipBloodPressureInput;

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
                            Container(
                              width: 235,
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
                  'assets/illustrations/tensi.png',
                  width: 304,
                  height: 304,
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
                                onChanged: (_) => setState(() {}),
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF2C4A8A),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                                decoration: _fieldDecoration('Isi sistolik'),
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
                                onChanged: (_) => setState(() {}),
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF2C4A8A),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                                decoration: _fieldDecoration('Isi diastolik'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Center(
                child: SizedBox(
                  width: 344,
                  child: Column(
                    children: [
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
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 344,
                        height: 55,
                        child: GestureDetector(
                          onTap: canSkip ? _skip : null,
                          child: Center(
                            child: Text(
                              'Lewati',
                              style: GoogleFonts.plusJakartaSans(
                                color: canSkip
                                    ? const Color(0xFF2C4A8A)
                                    : const Color(0xFFB0B0B0),
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                height: 1,
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
