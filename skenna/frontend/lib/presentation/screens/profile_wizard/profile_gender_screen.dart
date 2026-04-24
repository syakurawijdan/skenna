import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../navigation/app_routes.dart';
import 'profile_wizard_store.dart';

class ProfileGenderScreen extends StatefulWidget {
  const ProfileGenderScreen({super.key});

  @override
  State<ProfileGenderScreen> createState() => _ProfileGenderScreenState();
}

class _ProfileGenderScreenState extends State<ProfileGenderScreen> {
  String? _gender;
  late final String _displayName;

  @override
  void initState() {
    super.initState();
    final draft = ProfileWizardStore.instance.draft;
    _gender = draft.gender.isEmpty ? null : draft.gender;
    final trimmedName = draft.fullName.trim();
    _displayName = trimmedName.isEmpty ? 'Nama User' : trimmedName;
  }

  void _next() {
    if (_gender == null) {
      return;
    }
    final gender = _gender!;
    ProfileWizardStore.instance.draft.gender = gender;
    Navigator.pushNamed(context, AppRoutes.profileBirthDate);
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      hintText: 'Pilih Jenis Kelamin',
      hintStyle: GoogleFonts.plusJakartaSans(
        color: const Color(0xFFB0B0B0),
        fontSize: 13,
        fontWeight: FontWeight.w400,
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
    final isFormValid = _gender != null;

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
                              width: 92,
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
                  'assets/illustrations/gender.png',
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
                    'Halo, $_displayName',
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
                  width: 290,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jenis Kelamin',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF2C4A8A),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _gender,
                        items: const [
                          DropdownMenuItem(
                            value: 'perempuan',
                            child: Text('Perempuan'),
                          ),
                          DropdownMenuItem(
                            value: 'laki-laki',
                            child: Text('Laki-laki'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _gender = value;
                          });
                        },
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: Color(0xFF2C4A8A),
                        ),
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF2C4A8A),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                        decoration: _fieldDecoration(),
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
