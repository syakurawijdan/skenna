import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skenna/data/user_session.dart';

import '../navigation/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('SplashScreen loaded'); // ← tambah ini
    Timer(const Duration(seconds: 2), () async {
      if (!mounted) return;
      debugPrint('Timer fired'); // ← tambah ini

      final userId = UserSession().getUserId();
      debugPrint('userId: $userId'); // ← tambah ini

      if (userId > 0) {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.onboarding1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C4A8A),
      body: SizedBox.expand(
        child: Align(
          alignment: const Alignment(0, -0.09),
          child: SizedBox(
            width: 185,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Sken',
                        style: GoogleFonts.poppins(
                          fontSize: 45,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.125,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text: '.Na',
                        style: GoogleFonts.poppins(
                          fontSize: 45,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.125,
                          color: const Color(0xFFBEC7DB),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track Your Sodium',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
