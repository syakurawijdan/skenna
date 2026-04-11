import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'presentation/app_shell.dart';
import 'presentation/navigation/app_routes.dart';
import 'presentation/screens/onboarding_1_screen.dart';
import 'presentation/screens/onboarding_2_screen.dart';
import 'presentation/screens/onboarding_3_screen.dart';
import 'presentation/screens/profile_form_screen.dart';
import 'presentation/screens/sodium_limit_choice_screen.dart';
import 'presentation/screens/sodium_limit_safe_screen.dart';
import 'presentation/screens/sodium_limit_unsafe_screen.dart';
import 'presentation/screens/splash_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Skenna Sodium',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        textTheme: GoogleFonts.urbanistTextTheme(),
      ),
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.onboarding1: (_) => const Onboarding1Screen(),
        AppRoutes.onboarding2: (_) => const Onboarding2Screen(),
        AppRoutes.onboarding3: (_) => const Onboarding3Screen(),
        AppRoutes.profileForm: (_) => const ProfileFormScreen(),
        AppRoutes.sodiumChoice: (_) => const SodiumLimitChoiceScreen(),
        AppRoutes.sodiumSafe: (_) => const SodiumLimitSafeScreen(),
        AppRoutes.sodiumUnsafe: (_) => const SodiumLimitUnsafeScreen(),
        AppRoutes.dashboard: (_) => const AppShell(),
      },
    );
  }
}
