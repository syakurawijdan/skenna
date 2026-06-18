import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../domain/natrium_classifier.dart';
import '../../navigation/app_routes.dart';
import 'profile_step_layout.dart';
import 'profile_wizard_store.dart';

class ProfileBirthDateScreen extends StatefulWidget {
  const ProfileBirthDateScreen({super.key});

  @override
  State<ProfileBirthDateScreen> createState() => _ProfileBirthDateScreenState();
}

class _ProfileBirthDateScreenState extends State<ProfileBirthDateScreen> {
  late TextEditingController _dayCtrl;
  late TextEditingController _monthCtrl;
  late TextEditingController _yearCtrl;

  late FocusNode _dayFocus;
  late FocusNode _monthFocus;
  late FocusNode _yearFocus;

  @override
  void initState() {
    super.initState();
    _dayFocus = FocusNode();
    _monthFocus = FocusNode();
    _yearFocus = FocusNode();

    final saved = ProfileWizardStore.instance.draft.birthDate;
    _dayCtrl = TextEditingController(
      text: saved != null ? saved.day.toString().padLeft(2, '0') : '',
    );
    _monthCtrl = TextEditingController(
      text: saved != null ? saved.month.toString().padLeft(2, '0') : '',
    );
    _yearCtrl = TextEditingController(
      text: saved != null ? saved.year.toString() : '',
    );

    _dayCtrl.addListener(() => setState(() {}));
    _monthCtrl.addListener(() => setState(() {}));
    _yearCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _dayCtrl.dispose();
    _dayFocus.dispose();
    _monthCtrl.dispose();
    _monthFocus.dispose();
    _yearCtrl.dispose();
    _yearFocus.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    final day = int.tryParse(_dayCtrl.text.trim());
    final month = int.tryParse(_monthCtrl.text.trim());
    final year = int.tryParse(_yearCtrl.text.trim());
    if (day == null || month == null || year == null) return false;
    if (_yearCtrl.text.trim().length != 4) return false;
    if (month < 1 || month > 12) return false;
    if (year < 1940 || year > DateTime.now().year) return false;
    if (day < 1 || day > _maxDay(month, year)) return false;
    return true;
  }

  int _maxDay(int m, int y) {
    if ([1, 3, 5, 7, 8, 10, 12].contains(m)) return 31;
    if ([4, 6, 9, 11].contains(m)) return 30;
    return ((y % 4 == 0 && y % 100 != 0) || y % 400 == 0) ? 29 : 28;
  }

  String? _dayError() {
    final day = int.tryParse(_dayCtrl.text.trim());
    final month = int.tryParse(_monthCtrl.text.trim());
    final year = int.tryParse(_yearCtrl.text.trim());
    if (day == null || _dayCtrl.text.isEmpty) return null;
    if (day < 1 || day > 31) return 'Tanggal tidak valid';
    if (month != null) {
      final y = (year != null && _yearCtrl.text.trim().length == 4)
          ? year
          : 2001;
      if (day > _maxDay(month, y)) {
        return 'Maks. ${_maxDay(month, y)} hari';
      }
    }
    return null;
  }

  String? _monthError() {
    final month = int.tryParse(_monthCtrl.text.trim());
    if (month == null || _monthCtrl.text.isEmpty) return null;
    if (month < 1 || month > 12) return 'Bulan tidak valid';
    return null;
  }

  InputDecoration _inputDecoration(String hintText, {String? errorText}) {
    return InputDecoration(
      hintText: hintText,
      errorText: errorText,
      hintTextDirection: TextDirection.ltr,
      hintStyle: GoogleFonts.plusJakartaSans(
        color: const Color(0xFFB0B0B0),
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      filled: false,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE53935)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE53935)),
      ),
      errorStyle: GoogleFonts.plusJakartaSans(
        color: const Color(0xFFE53935),
        fontSize: 9,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Future<void> _next() async {
    if (!_isFormValid) return;
    final day = int.parse(_dayCtrl.text.trim());
    final month = int.parse(_monthCtrl.text.trim());
    final year = int.parse(_yearCtrl.text.trim());
    final birthDate = DateTime(year, month, day);
    ProfileWizardStore.instance.draft.birthDate = birthDate;

    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }

    if (age < 18) {
      final hasil = await klasifikasiNatriumDariDraft(
        birthDate: birthDate,
        gender: ProfileWizardStore.instance.draft.gender,
        hasHypertension: false,
      );
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        routeUntukCategoryKey(hasil.categoryKey),
        (route) => false,
        arguments: {'categoryKey': hasil.categoryKey, 'hasil': hasil},
      );
    } else {
      FocusScope.of(context).unfocus();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      Navigator.pushNamed(context, AppRoutes.profileHypertensionStatus);
    }
  }

  Widget _field({
    required String label,
    required TextEditingController ctrl,
    required FocusNode focusNode,
    required String hint,
    required int maxLen,
    FocusNode? nextFocus,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF2C4A8A),
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          maxLength: maxLen,
          expands: false,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (v) {
            if (v.length == maxLen && nextFocus != null) {
              nextFocus.requestFocus();
            }
          },
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF2C4A8A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          decoration: _inputDecoration(
            hint,
            errorText: errorText,
          ).copyWith(counterText: ''),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = ProfileWizardStore.instance.progressForStep(
      ProfileWizardStep.birthDate,
    );

    return ProfileStepLayout(
      progress: progress,
      illustrationAsset: 'assets/illustrations/birthday.png',
      title: 'Tanggal lahir kamu',
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: _field(
              label: 'Hari',
              ctrl: _dayCtrl,
              focusNode: _dayFocus,
              hint: 'DD',
              maxLen: 2,
              nextFocus: _monthFocus,
              errorText: _dayError(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _field(
              label: 'Bulan',
              ctrl: _monthCtrl,
              focusNode: _monthFocus,
              hint: 'MM',
              maxLen: 2,
              nextFocus: _yearFocus,
              errorText: _monthError(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: _field(
              label: 'Tahun',
              ctrl: _yearCtrl,
              focusNode: _yearFocus,
              hint: 'YYYY',
              maxLen: 4,
            ),
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
        onPressed: _isFormValid ? _next : null,
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
