import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/natrium_classifier.dart';
import '../app_shell.dart';

class SodiumLimitUnsafeScreen extends StatelessWidget {
  const SodiumLimitUnsafeScreen({super.key, required this.hasil});

  final HasilKlasifikasi hasil;

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
                child: Column(
                  children: [
                    const SizedBox(height: 76),
                    Center(
                      child: SizedBox(
                        width: 304,
                        child: Text(
                          'Lebih Ketat\nBatas Natrium Harian',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 35,
                            height: 1.05,
                            fontWeight: FontWeight.w800,
                            color: _blue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: constraints.maxWidth,
                      height: 250,
                      child: Image.asset(
                        'assets/illustrations/batasketat.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: Text(
                        '${formatNatriumMg(hasil.batasNatrium)} mg',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 54,
                          fontWeight: FontWeight.w800,
                          color: _blue,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: SizedBox(
                        width: 302,
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.plusJakartaSans(
                              color: _blue,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.25,
                            ),
                            children: [
                              const TextSpan(text: 'Batas ini '),
                              TextSpan(
                                text: 'lebih rendah',
                                style: GoogleFonts.plusJakartaSans(
                                  color: _blue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                ),
                              ),
                              const TextSpan(
                                text:
                                    ' untuk membantu\nmengontrol tekanan darahmu.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F4E5),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        'Kebutuhan natrium harian Anda adalah 1200 mg.',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF77B06D),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: SizedBox(
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
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: SizedBox(
                        width: 320,
                        child: Text(
                          'Perhitungan ini mengacu pada standar AKG, WHO, dan\nAHA, berdasarkan data yang kamu isi sebelumnya',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFFB7B7B7),
                            fontSize: 12,
                            height: 1.25,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
