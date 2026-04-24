import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_shell.dart';

class SodiumLimitUnsafeScreen extends StatelessWidget {
  const SodiumLimitUnsafeScreen({super.key});

  static const _blue = Color(0xFF2C4A8A);
  static const _background = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 26),
                      Center(
                        child: SizedBox(
                          width: 380,
                          child: Text(
                            'Lebih Ketat\nBatas Natrium Harian',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 31,
                              fontWeight: FontWeight.w700,
                              color: _blue,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 72),
                      SizedBox(
                        width: constraints.maxWidth,
                        height: 251,
                        child: Image.asset(
                          'assets/illustrations/batasketat.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: SizedBox(
                          width: 344,
                          child: Column(
                            children: [
                              Text(
                                '1.500 mg',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 50,
                                  fontWeight: FontWeight.w700,
                                  color: _blue,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 16),
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: GoogleFonts.plusJakartaSans(
                                    color: _blue,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    height: 1,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Batas ini '),
                                    TextSpan(
                                      text: 'lebih rendah',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: _blue,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        height: 1,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: ' untuk membantu\nmengontrol ',
                                    ),
                                    TextSpan(
                                      text: 'tekanan darahmu',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: _blue,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        height: 1,
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
                                  onPressed: () {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) => const AppShell(),
                                      ),
                                      (route) => false,
                                    );
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _blue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    elevation: 4,
                                    shadowColor: const Color(0x40000000),
                                  ),
                                  child: Text(
                                    'Mulai',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: GoogleFonts.plusJakartaSans(
                                    color: _blue,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    height: 1,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text:
                                          'Perhitungan ini mengacu pada standar ',
                                    ),
                                    TextSpan(
                                      text: 'DRI & WHO',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: _blue,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        height: 1,
                                      ),
                                    ),
                                    const TextSpan(text: ',\nberdasarkan '),
                                    TextSpan(
                                      text: 'data',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: _blue,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        height: 1,
                                      ),
                                    ),
                                    const TextSpan(text: ' yang kamu '),
                                    TextSpan(
                                      text: 'isi sebelumnya',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: _blue,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        height: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 77),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
