import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../domain/natrium_classifier.dart';
import '../../navigation/app_routes.dart';
import 'profile_step_layout.dart';
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
  late final FocusNode _systolicFocusNode;
  late final FocusNode _diastolicFocusNode;

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
    _systolicFocusNode = FocusNode();
    _diastolicFocusNode = FocusNode();

    _systolicController.addListener(_onSystolicChanged);
    _diastolicController.addListener(() => setState(() {}));
  }

  void _onSystolicChanged() {
    setState(() {});
    final text = _systolicController.text.trim();
    // Auto-jump kalau udah 3 digit (misal sistolik biasanya 90-200+)
    if (text.length == 3) {
      _diastolicFocusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _systolicFocusNode.dispose();
    _diastolicFocusNode.dispose();
    super.dispose();
  }

  bool get _isMale {
    final gender = ProfileWizardStore.instance.draft.gender
        .trim()
        .toLowerCase();
    return gender == 'laki-laki' || gender == 'laki_laki' || gender == 'male';
  }

  bool _shouldSkipPregnancyQuestion(DateTime birthDate) {
    // SKI 2023 defines wanita usia subur as ages 10-54 for anthropometry.
    final usia = hitungUsiaTahun(birthDate);
    return usia < 10 || usia > 54;
  }

  double? _parseIndoDouble(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    return double.tryParse(text.trim().replaceAll(',', '.'));
  }

  int? _parseIndoInt(String? text) {
    final parsed = _parseIndoDouble(text);
    return parsed?.toInt();
  }

  bool get _isFormValid {
    final systolic = _systolicController.text.trim();
    final diastolic = _diastolicController.text.trim();
    return systolic.isNotEmpty && diastolic.isNotEmpty;
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.plusJakartaSans(
        color: const Color(0xFFB0B0B0),
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      filled: false,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFBEC7DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFBEC7DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2C4A8A)),
      ),
    );
  }

  Future<void> _goNext() async {
    final systolic = _parseIndoInt(_systolicController.text.trim());
    final diastolic = _parseIndoInt(_diastolicController.text.trim());

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
        routeUntukCategoryKey(hasil.categoryKey),
        (route) => false,
        arguments: {'categoryKey': hasil.categoryKey, 'hasil': hasil},
      );
      return;
    }

    final draft = ProfileWizardStore.instance.draft;
    if (_shouldSkipPregnancyQuestion(draft.birthDate!)) {
      final hasil = await klasifikasiNatriumDariDraft(
        birthDate: draft.birthDate!,
        gender: draft.gender,
        hasHypertension: draft.hasHypertension,
        hypertensionCondition: draft.hypertensionCondition,
        systolicPressure: systolic,
        diastolicPressure: diastolic,
        pregnancyStatus: 'tidak_hamil',
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        routeUntukCategoryKey(hasil.categoryKey),
        (route) => false,
        arguments: {'categoryKey': hasil.categoryKey, 'hasil': hasil},
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
        routeUntukCategoryKey(hasil.categoryKey),
        (route) => false,
        arguments: {'categoryKey': hasil.categoryKey, 'hasil': hasil},
      );
      return;
    }

    final draft = ProfileWizardStore.instance.draft;
    if (_shouldSkipPregnancyQuestion(draft.birthDate!)) {
      final hasil = await klasifikasiNatriumDariDraft(
        birthDate: draft.birthDate!,
        gender: draft.gender,
        hasHypertension: draft.hasHypertension,
        hypertensionCondition: draft.hypertensionCondition,
        pregnancyStatus: 'tidak_hamil',
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        routeUntukCategoryKey(hasil.categoryKey),
        (route) => false,
        arguments: {'categoryKey': hasil.categoryKey, 'hasil': hasil},
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

    return ProfileStepLayout(
      showBack: true,
      progress: progress,
      illustrationAsset: 'assets/illustrations/tensi.png',
      title: 'Isi tekanan darah',
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
      content: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Sistolik',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF2C4A8A),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  child: TextField(
                    controller: _systolicController,
                    focusNode: _systolicFocusNode,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    maxLength: 3,
                    buildCounter:
                        (
                          context, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) => null, // sembunyiin counter "0/3"
                    onSubmitted: (_) => _diastolicFocusNode.requestFocus(),
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF2C4A8A),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
              crossAxisAlignment: CrossAxisAlignment.center,
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
                  child: TextField(
                    controller: _diastolicController,
                    focusNode: _diastolicFocusNode,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    maxLength: 3,
                    buildCounter:
                        (
                          context, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) => null,
                    onSubmitted: (_) => _diastolicFocusNode.unfocus(),
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF2C4A8A),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: _inputDecoration('Isi diastolik'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      primaryButton: FilledButton(
        onPressed: _isFormValid ? _goNext : null,
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
      // SESUDAH
      secondaryAction: TextButton(
        onPressed: _skip,
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.all(const Color(0xFFDFE4ED)),
          foregroundColor: WidgetStateProperty.all(const Color(0xFFBEC7DB)),
        ),
        child: Text(
          'Lewati',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF2C4A8A),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
