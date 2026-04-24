import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:device_preview/device_preview.dart';
import 'package:google_fonts/google_fonts.dart';

import 'data/api_client.dart';
import 'presentation/app_shell.dart';
import 'presentation/navigation/app_routes.dart';
import 'presentation/screens/chatbot_screen.dart';
import 'presentation/screens/onboarding_1_screen.dart';
import 'presentation/screens/onboarding_2_screen.dart';
import 'presentation/screens/onboarding_3_screen.dart';
import 'presentation/screens/profile_form_screen.dart';
import 'presentation/screens/sodium_limit_pregnant_screen.dart';
import 'presentation/screens/sodium_limit_safe_screen.dart';
import 'presentation/screens/sodium_limit_unsafe_screen.dart';
import 'presentation/screens/splash_screen.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  static final Map<String, WidgetBuilder> _routes = {
    AppRoutes.splash: (_) => const SplashScreen(),
    AppRoutes.onboarding1: (_) => const Onboarding1Screen(),
    AppRoutes.onboarding2: (_) => const Onboarding2Screen(),
    AppRoutes.onboarding3: (_) => const Onboarding3Screen(),
    AppRoutes.profileForm: (_) => const ProfileFormScreen(),
    AppRoutes.profileGender: (_) => const ProfileGenderScreen(),
    AppRoutes.profileBirthDate: (_) => const ProfileBirthDateScreen(),
    AppRoutes.profileBmi: (_) => const ProfileBmiScreen(),
    AppRoutes.profileHypertension: (_) => const ProfileHypertensionScreen(),
    AppRoutes.profileBloodPressure: (_) => const ProfileBloodPressureScreen(),
    AppRoutes.profilePregnancy: (_) => const ProfilePregnancyScreen(),
    AppRoutes.sodiumSafe: (_) => const SodiumLimitSafeScreen(),
    AppRoutes.sodiumUnsafe: (_) => const SodiumLimitUnsafeScreen(),
    AppRoutes.sodiumPregnant: (_) => const SodiumLimitPregnantScreen(),
    AppRoutes.dashboard: (_) => const AppShell(),
  };

  static Route<dynamic> _buildAnimatedRoute(
    RouteSettings settings,
    WidgetBuilder builder,
  ) {
    return PageRouteBuilder(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, animation, secondaryAnimation) {
        return builder(context);
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubicEmphasized,
          reverseCurve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1).animate(curve),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.035, 0),
              end: Offset.zero,
            ).animate(curve),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.985, end: 1).animate(curve),
              child: child,
            ),
          ),
        );
      },
    );
  }

  static Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    if (settings.name == AppRoutes.chatbot) {
      final initialQuestion = settings.arguments as String?;
      return _buildAnimatedRoute(
        settings,
        (_) => ChatbotScreen(
          apiClient: ApiClient(),
          initialQuestion: initialQuestion,
        ),
      );
    }

    final builder = _routes[settings.name];
    if (builder == null) {
      return _buildAnimatedRoute(
        settings,
        (_) => const Scaffold(body: Center(child: Text('Route not found'))),
      );
    }
    return _buildAnimatedRoute(settings, builder);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      title: 'Skenna Sodium',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        textTheme: GoogleFonts.urbanistTextTheme(),
      ),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: _onGenerateRoute,
    );
  }
}
