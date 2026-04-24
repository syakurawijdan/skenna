import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../navigation/app_routes.dart';
import 'profile_wizard_store.dart';

class ProfileHypertensionScreen extends StatefulWidget {
  const ProfileHypertensionScreen({super.key});

  @override
  State<ProfileHypertensionScreen> createState() =>
      _ProfileHypertensionScreenState();
}

class _ProfileHypertensionScreenState extends State<ProfileHypertensionScreen> {
  bool? _hasHypertension;

  @override
  void initState() {
    super.initState();
    _hasHypertension = ProfileWizardStore.instance.draft.hasHypertension;
  }

  void _next() {
    if (_hasHypertension == null) {
      return;
    }
    ProfileWizardStore.instance.draft.hasHypertension = _hasHypertension;
    Navigator.pushNamed(context, AppRoutes.profileBloodPressure);
  }

  Widget _radioOption({
    required bool selected,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
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
                fontSize: 32 / 2,
                fontWeight: FontWeight.w400,
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
                              width: 230,
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
                        selected: _hasHypertension == true,
                        label: 'Ya, saya punya',
                        onTap: () => setState(() => _hasHypertension = true),
                      ),
                    ),
                    SizedBox(
                      width: 88,
                      child: _radioOption(
                        selected: _hasHypertension == false,
                        label: 'Tidak',
                        onTap: () => setState(() => _hasHypertension = false),
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
