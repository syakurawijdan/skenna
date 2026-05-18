import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../navigation/app_routes.dart';
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
    if (_condition == null) {
      return;
    }
    // Defensive: once user is in this step, they are considered hypertensive.
    ProfileWizardStore.instance.draft.hasHypertension = true;
    ProfileWizardStore.instance.draft.hypertensionCondition = _condition!;
    Navigator.pushNamed(context, AppRoutes.profileBloodPressure);
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
                  height: 1.2,
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
    final isFormValid = _condition != null;
    final progress = ProfileWizardStore.instance.progressForStep(
      ProfileWizardStep.hypertensionCondition,
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
                  'Pilih Kondisi',
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
                        selected: _condition == 'history_only',
                        label:
                            'Pernah mengalami hipertensi, saat ini terkontrol',
                        onTap: () {
                          setState(() {
                            _condition = 'history_only';
                          });
                        },
                      ),
                      _radioOption(
                        selected: _condition == 'controlled',
                        label: 'Sedang hipertensi, terkontrol dengan obat',
                        onTap: () {
                          setState(() {
                            _condition = 'controlled';
                          });
                        },
                      ),
                      _radioOption(
                        selected: _condition == 'uncontrolled',
                        label: 'Sedang hipertensi, belum terkontrol',
                        onTap: () {
                          setState(() {
                            _condition = 'uncontrolled';
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32),
              // Button
              Center(
                child: SizedBox(
                  width: 344,
                  child: SizedBox(
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
