import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../navigation/app_routes.dart';

class Onboarding1Screen extends StatelessWidget {
  const Onboarding1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF2C4A8A);
    const normalBlue = Color(0xFF2C4A8A);
    const lightBlue = Color(0xFFDFE4ED);
    final mediaQuery = MediaQuery.of(context);

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 48, 16, 48),
                child: Column(
                  children: [
                    Text(
                      'Hipertensi Bisa\nDatang Tanpa Gejala',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: darkBlue,
                        fontSize: 31,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: Center(
                              child: SizedBox(
                                width: double.infinity,
                                child: Image.asset(
                                  'assets/illustrations/onboarding_doctor.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Container(
                                    decoration: BoxDecoration(
                                      color: lightBlue,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.health_and_safety,
                                      color: darkBlue,
                                      size: 72,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 17,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: normalBlue,
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: lightBlue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: lightBlue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: GoogleFonts.plusJakartaSans(
                                color: darkBlue,
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                                height: 1,
                              ),
                              children: const [
                                TextSpan(text: 'Sering tak disadari, '),
                                TextSpan(
                                  text: 'natrium\nberlebih',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                TextSpan(text: ' bisa picu '),
                                TextSpan(
                                  text: 'hipertensi.',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 116),
                    Container(
                      width: 344,
                      height: 55,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x40000000),
                            offset: Offset(2, 4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: normalBlue,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.onboarding2);
                        },
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
          ),
        ),
      ),
    );
  }
}
