import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../navigation/app_routes.dart';
import 'profile_wizard_store.dart';

class ProfileBmiScreen extends StatefulWidget {
  const ProfileBmiScreen({super.key});

  @override
  State<ProfileBmiScreen> createState() => _ProfileBmiScreenState();
}

class _ProfileBmiScreenState extends State<ProfileBmiScreen> {
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  double? _bmi;

  @override
  void initState() {
    super.initState();
    final draft = ProfileWizardStore.instance.draft;
    _heightController = TextEditingController(
      text: draft.heightCm?.toStringAsFixed(0) ?? '',
    );
    _weightController = TextEditingController(
      text: draft.weightKg?.toStringAsFixed(0) ?? '',
    );
    _heightController.addListener(_recalculate);
    _weightController.addListener(_recalculate);
    _recalculate();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _recalculate() {
    final height = double.tryParse(_heightController.text.replaceAll(',', '.'));
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    double? bmi;
    if (height != null && weight != null && height > 0 && weight > 0) {
      bmi = weight / ((height / 100) * (height / 100));
    }
    setState(() {
      _bmi = bmi;
    });
  }

  void _next() {
    final height = double.tryParse(_heightController.text.replaceAll(',', '.'));
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    if (height == null ||
        weight == null ||
        height <= 0 ||
        weight <= 0 ||
        _bmi == null) {
      _showValidation('Tinggi dan berat badan wajib valid');
      return;
    }
    if (height < 50 || height > 300) {
      _showValidation('Tinggi badan harus di antara 50-300 cm');
      return;
    }
    if (weight < 20 || weight > 500) {
      _showValidation('Berat badan harus di antara 20-500 kg');
      return;
    }
    final draft = ProfileWizardStore.instance.draft;
    draft.heightCm = height;
    draft.weightKg = weight;
    draft.bmi = _bmi;
    Navigator.pushNamed(context, AppRoutes.profileHypertension);
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

  @override
  Widget build(BuildContext context) {
    final height = double.tryParse(_heightController.text.replaceAll(',', '.'));
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    final isFormValid =
        _bmi != null &&
        height != null &&
        weight != null &&
        height >= 50 &&
        height <= 300 &&
        weight >= 20 &&
        weight <= 500;

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
                              width: 184,
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
                  'assets/illustrations/bmi.png',
                  width: 308,
                  height: 308,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: SizedBox(
                  width: 380,
                  child: Text(
                    'Berapa BMI kamu?',
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
                              'Tinggi badan',
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
                                controller: _heightController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF2C4A8A),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                                decoration: _fieldDecoration(
                                  'Isi tinggi badan',
                                ),
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
                              'Berat badan',
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
                                controller: _weightController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF2C4A8A),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                                decoration: _fieldDecoration('Isi berat badan'),
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
                      Text.rich(
                        TextSpan(
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF2C4A8A),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 1,
                          ),
                          children: [
                            const TextSpan(text: 'Semakin '),
                            TextSpan(
                              text: 'lengkap data',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF2C4A8A),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                            const TextSpan(text: ' yang kamu isi,\n'),
                            const TextSpan(text: 'semakin '),
                            TextSpan(
                              text: 'akurat ',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF2C4A8A),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                            const TextSpan(text: 'hasil analisis dari Skenna'),
                          ],
                        ),
                        textAlign: TextAlign.center,
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
