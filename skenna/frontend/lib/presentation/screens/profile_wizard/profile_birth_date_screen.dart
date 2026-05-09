import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../navigation/app_routes.dart';
import 'profile_wizard_store.dart';

class ProfileBirthDateScreen extends StatefulWidget {
  const ProfileBirthDateScreen({super.key});

  @override
  State<ProfileBirthDateScreen> createState() => _ProfileBirthDateScreenState();
}

class _ProfileBirthDateScreenState extends State<ProfileBirthDateScreen> {
  int? _day;
  int? _month;
  int? _year;

  @override
  void initState() {
    super.initState();
    final saved = ProfileWizardStore.instance.draft.birthDate;
    _year = saved?.year;
    _month = saved?.month;
    _day = saved?.day;
  }

  List<int> get _yearItems {
    final currentYear = DateTime.now().year;
    return List<int>.generate(100, (index) => currentYear - index);
  }

  int _daysInMonth(int year, int month) {
    final firstOfNextMonth = month == 12
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
    return firstOfNextMonth.subtract(const Duration(days: 1)).day;
  }

  void _next() {
    if (_year == null || _month == null || _day == null) {
      return;
    }
    final year = _year!;
    final month = _month!;
    final day = _day!;
    ProfileWizardStore.instance.draft.birthDate = DateTime(year, month, day);
    Navigator.pushNamed(context, AppRoutes.profileHypertension);
  }

  InputDecoration _dateFieldDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.plusJakartaSans(
        color: const Color(0xFF2C4A8A),
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
    final selectedYear = _year;
    final selectedMonth = _month;
    final maxDay = (selectedYear != null && selectedMonth != null)
        ? _daysInMonth(selectedYear, selectedMonth)
        : 31;
    if (_day != null && _day! > maxDay) {
      _day = maxDay;
    }
    final isFormValid = _year != null && _month != null && _day != null;

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
                              width: 138,
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
                  'assets/illustrations/birthday.png',
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
                    'Tanggal lahir kamu',
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
                  width: 317,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 91,
                        child: DropdownButtonFormField<int>(
                          value: _day,
                          isExpanded: true,
                          items:
                              List<int>.generate(maxDay, (index) => index + 1)
                                  .map(
                                    (value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(
                                        value.toString().padLeft(2, '0'),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              _day = value;
                            });
                          },
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF2C4A8A),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Color(0xFF2C4A8A),
                            size: 18,
                          ),
                          decoration: _dateFieldDecoration('DD'),
                        ),
                      ),
                      const SizedBox(width: 22),
                      SizedBox(
                        width: 91,
                        child: DropdownButtonFormField<int>(
                          value: _month,
                          isExpanded: true,
                          items: List<int>.generate(12, (index) => index + 1)
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value.toString().padLeft(2, '0')),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              _month = value;
                            });
                          },
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF2C4A8A),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Color(0xFF2C4A8A),
                            size: 18,
                          ),
                          decoration: _dateFieldDecoration('MM'),
                        ),
                      ),
                      const SizedBox(width: 22),
                      SizedBox(
                        width: 91,
                        child: DropdownButtonFormField<int>(
                          value: _year,
                          isExpanded: true,
                          items: _yearItems
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value.toString()),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              _year = value;
                            });
                          },
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF2C4A8A),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Color(0xFF2C4A8A),
                            size: 18,
                          ),
                          decoration: _dateFieldDecoration('YYYY'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: SizedBox(
                  width: 344,
                  child: Text(
                    'Format tanggal: DD/MM/YYYY',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFFB0B0B0),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Center(
                child: SizedBox(
                  width: 344,
                  child: Text.rich(
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
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: SizedBox(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
