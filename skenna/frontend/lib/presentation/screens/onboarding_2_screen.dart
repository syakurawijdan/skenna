import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../navigation/app_routes.dart';

class Onboarding2Screen extends StatelessWidget {
  const Onboarding2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF2C4A8A);
    const normalBlue = Color(0xFF2C4A8A);
    const lightBlue = Color(0xFFDFE4ED);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 48),
              child: Column(
                children: [
                  Text(
                    'Kenali Kandungan\ndi Balik Label',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
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
                                'assets/illustrations/onboarding2.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Container(
                                  decoration: BoxDecoration(
                                    color: lightBlue,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.science,
                                    color: darkBlue,
                                    size: 72,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 49,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: lightBlue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Container(
                                width: 16,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: normalBlue,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              const SizedBox(width: 7),
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
                              TextSpan(
                                text: 'Natrium ',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              TextSpan(text: 'dalam makanan kemasan\nkerap '),
                              TextSpan(
                                text: 'luput dari perhatian',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: normalBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 4,
                        shadowColor: const Color(0x40000000),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.onboarding3);
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
    );
  }
}
