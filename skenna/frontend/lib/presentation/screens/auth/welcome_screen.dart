import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/api_client.dart';
import '../../../data/user_session.dart';
import '../../navigation/app_routes.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    UserSession().clear();
    ApiClient.clearCurrentUserId();
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2C4A8A);
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Ayo, Pantau Natrium Harianmu Sekarang!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            color: blue,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/illustrations/welcome_pertama.png',
                                height: (mediaQuery.size.height * 0.35)
                                    .clamp(190.0, 280.0)
                                    .toDouble(),
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 28),
                              Text.rich(
                                TextSpan(
                                  text: 'Pantau ',
                                  children: const [
                                    TextSpan(
                                      text: 'konsumsi natrium harianmu',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextSpan(text: ' dengan mudah melalui '),
                                    TextSpan(
                                      text: 'SKENNA',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  color: blue,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.registerEmail),
                      style: FilledButton.styleFrom(
                        backgroundColor: blue,
                        elevation: 4,
                        shadowColor: const Color(0x40000000),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        'Daftar',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.login),
                      style: ButtonStyle(
                        overlayColor: WidgetStateProperty.all(
                          const Color(0xFFDFE4ED),
                        ),
                        foregroundColor: WidgetStateProperty.all(
                          const Color(0xFFBEC7DB),
                        ),
                      ),
                      child: Text(
                        'Masuk',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF2C4A8A),
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
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
