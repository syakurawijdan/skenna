import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:device_preview/device_preview.dart';
import 'package:google_fonts/google_fonts.dart';

import 'data/api_client.dart';
import 'domain/app_init_service.dart';
import 'domain/natrium_classifier.dart';
import 'presentation/app_shell.dart';
import 'presentation/navigation/app_routes.dart';
import 'presentation/screens/chatbot_screen.dart';
import 'presentation/screens/onboarding_1_screen.dart';
import 'presentation/screens/onboarding_2_screen.dart';
import 'presentation/screens/onboarding_3_screen.dart';
import 'presentation/screens/profile_wizard/profile_name_screen.dart';
import 'presentation/screens/profile_wizard/profile_birth_date_screen.dart';
import 'presentation/screens/profile_wizard/profile_blood_pressure_screen.dart';
import 'presentation/screens/profile_wizard/profile_gender_screen.dart';
import 'presentation/screens/profile_wizard/profile_hypertension_condition_screen.dart';
import 'presentation/screens/profile_wizard/profile_hypertension_status_screen.dart';
import 'presentation/screens/profile_wizard/profile_pregnancy_screen.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/sodium_limit_pregnant_screen.dart';
import 'presentation/screens/sodium_limit_safe_screen.dart';
import 'presentation/screens/sodium_limit_unsafe_screen.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const MainApp(),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = AppInitService().init();
  }

  static final Map<String, WidgetBuilder> _routes = {
    AppRoutes.splash: (_) => const SplashScreen(),
    AppRoutes.onboarding1: (_) => const Onboarding1Screen(),
    AppRoutes.onboarding2: (_) => const Onboarding2Screen(),
    AppRoutes.onboarding3: (_) => const Onboarding3Screen(),
    AppRoutes.profileForm: (_) => const ProfileFormScreen(),
    AppRoutes.profileGender: (_) => const ProfileGenderScreen(),
    AppRoutes.profileBirthDate: (_) => const ProfileBirthDateScreen(),
    AppRoutes.profileHypertensionStatus: (_) =>
        const ProfileHypertensionStatusScreen(),
    AppRoutes.profileHypertensionCondition: (_) =>
        const ProfileHypertensionConditionScreen(),
    AppRoutes.profileBloodPressure: (_) => const ProfileBloodPressureScreen(),
    AppRoutes.profilePregnancy: (_) => const ProfilePregnancyScreen(),
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

  static Route<dynamic> _notFoundRoute(RouteSettings settings) {
    return _buildAnimatedRoute(
      settings,
      (_) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.route_outlined,
                    size: 56,
                    color: Color(0xFF2C4A8A),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Halaman tidak ditemukan',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2C4A8A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Route ${(settings.name ?? '').isEmpty ? 'unknown' : settings.name} belum terdaftar di router aplikasi.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: const Color(0xFF5E6B84),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 220,
                    height: 48,
                    child: Builder(
                      builder: (context) {
                        return FilledButton(
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.splash,
                              (route) => false,
                            );
                          },
                          child: const Text('Kembali ke Awal'),
                        );
                      },
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

    if (settings.name == AppRoutes.sodiumSafe ||
        settings.name == AppRoutes.sodiumUnsafe ||
        settings.name == AppRoutes.sodiumPregnant) {
      final hasil = settings.arguments as HasilKlasifikasi?;
      if (hasil == null) {
        return _buildAnimatedRoute(
          settings,
          (_) => const Scaffold(
            body: Center(child: Text('Hasil klasifikasi tidak tersedia')),
          ),
        );
      }

      if (settings.name == AppRoutes.sodiumSafe) {
        return _buildAnimatedRoute(
          settings,
          (_) => SodiumLimitSafeScreen(hasil: hasil),
        );
      }
      if (settings.name == AppRoutes.sodiumUnsafe) {
        return _buildAnimatedRoute(
          settings,
          (_) => SodiumLimitUnsafeScreen(hasil: hasil),
        );
      }
      return _buildAnimatedRoute(
        settings,
        (_) => SodiumLimitPregnantScreen(hasil: hasil),
      );
    }

    final builder = _routes[settings.name];
    if (builder == null) {
      return _notFoundRoute(settings);
    }
    return _buildAnimatedRoute(settings, builder);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
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
          onUnknownRoute: _notFoundRoute,
        );
      },
    );
  }
}
