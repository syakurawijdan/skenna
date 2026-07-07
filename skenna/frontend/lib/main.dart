import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skenna/data/user_session.dart';

import 'data/api_client.dart';
import 'domain/app_init_service.dart';
import 'domain/natrium_classifier.dart';
import 'presentation/app_shell.dart';
import 'presentation/navigation/app_routes.dart';
import 'presentation/screens/chatbot_screen.dart';
import 'presentation/screens/onboarding_1_screen.dart';
import 'presentation/screens/onboarding_2_screen.dart';
import 'presentation/screens/onboarding_3_screen.dart';
import 'presentation/screens/change_password_screen.dart';
import 'presentation/screens/change_password_from_profile_screen.dart';
import 'presentation/screens/edit_profile_screen.dart';
import 'presentation/screens/consumed_today_screen.dart';
import 'presentation/screens/auth/email_screen.dart';
import 'presentation/screens/auth/forgot_email_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/otp_verification_screen.dart';
import 'presentation/screens/auth/password_screen.dart';
import 'presentation/screens/auth/welcome_screen.dart';
import 'presentation/screens/profile_wizard/profile_name_screen.dart';
import 'presentation/screens/profile_wizard/profile_birth_date_screen.dart';
import 'presentation/screens/profile_wizard/profile_blood_pressure_screen.dart';
import 'presentation/screens/profile_wizard/profile_gender_screen.dart';
import 'presentation/screens/profile_wizard/profile_hypertension_condition_screen.dart';
import 'presentation/screens/profile_wizard/profile_hypertension_status_screen.dart';
import 'presentation/screens/profile_wizard/profile_pregnancy_screen.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/sodium_result_screen.dart';
import 'presentation/screens/hasil_scan_aman_screen.dart';
import 'presentation/screens/hasil_perbandingan_produk.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await UserSession().init();
  await AppInitService().init();
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  static String _sodiumLevelLabel(KategoriNatrium kategori) {
    switch (kategori) {
      case KategoriNatrium.hijau:
        return 'low';
      case KategoriNatrium.kuning:
        return 'medium';
      case KategoriNatrium.merah:
        return 'high';
    }
  }

  static final Map<String, WidgetBuilder> _routes = {
    '/': (_) => const SplashScreen(),
    AppRoutes.splash: (_) => const SplashScreen(),
    AppRoutes.welcome: (_) => const WelcomeScreen(),
    AppRoutes.registerEmail: (_) => const EmailScreen(),
    AppRoutes.forgotPassword: (_) => const ForgotEmailScreen(),
    AppRoutes.login: (_) => const LoginScreen(),
    AppRoutes.onboarding1: (_) => const Onboarding1Screen(),
    AppRoutes.onboarding2: (_) => const Onboarding2Screen(),
    AppRoutes.onboarding3: (_) => const Onboarding3Screen(),
    AppRoutes.profileForm: (_) => const ProfileFormScreen(),
    AppRoutes.profileGender: (_) => const ProfileGenderScreen(),
    AppRoutes.profileBirthDate: (_) => const ProfileBirthDateScreen(),
    AppRoutes.profileHypertensionStatus: (_) =>
        const ProfileHypertensionStatusScreen(),
    AppRoutes.profileBloodPressure: (_) => const ProfileBloodPressureScreen(),
    AppRoutes.profilePregnancy: (_) => const ProfilePregnancyScreen(),
    AppRoutes.dashboard: (_) => const AppShell(),
    AppRoutes.history: (_) => const AppShell(initialIndex: 2),
    AppRoutes.editProfile: (_) => const EditProfileScreen(),
    AppRoutes.consumedToday: (_) => const ConsumedTodayScreen(),
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

  static Future<HasilKlasifikasi?> _getDailyClassification() async {
    try {
      final userId = UserSession().getUserId();
      if (userId == 0) return null;

      final profile = await ApiClient().getUserProfile(userId);
      final birthDateStr = profile['birth_date'] as String?;
      if (birthDateStr == null) return null;

      return klasifikasiNatriumDariDraft(
        birthDate: DateTime.parse(birthDateStr),
        gender: profile['gender'] as String? ?? '',
        hasHypertension: profile['has_hypertension'] as bool? ?? false,
        hypertensionCondition: profile['hypertension_condition'] as String?,
        systolicPressure: profile['systolic_pressure'] as int?,
        diastolicPressure: profile['diastolic_pressure'] as int?,
        pregnancyStatus: profile['pregnancy_status'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  static Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    double? asDouble(Object? value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '');
    }

    int? asInt(Object? value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '');
    }

    bool asBool(Object? value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      final text = value?.toString().toLowerCase().trim();
      return text == 'true' || text == '1';
    }

    if (settings.name == AppRoutes.registerPassword) {
      final email = settings.arguments as String? ?? '';
      return _buildAnimatedRoute(settings, (_) => PasswordScreen(email: email));
    }

    if (settings.name == AppRoutes.otpVerification) {
      final args = settings.arguments;
      final email = args is Map<String, dynamic>
          ? args['email'] as String? ?? ''
          : args as String? ?? '';
      final isForgotPassword = args is Map<String, dynamic>
          ? args['isForgotPassword'] as bool? ?? false
          : false;
      return _buildAnimatedRoute(
        settings,
        (_) => OtpVerificationScreen(
          email: email,
          isForgotPassword: isForgotPassword,
        ),
      );
    }

    if (settings.name == AppRoutes.changePassword) {
      final email = settings.arguments as String? ?? '';
      return _buildAnimatedRoute(
        settings,
        (_) => ChangePasswordScreen(email: email),
      );
    }

    if (settings.name == AppRoutes.changePasswordProfile) {
      return _buildAnimatedRoute(
        settings,
        (_) => const ChangePasswordFromProfileScreen(),
      );
    }

    if (settings.name == AppRoutes.chatbot) {
      final args = settings.arguments as Map<String, dynamic>?;
      final initialQuestion = args?['initialQuestion'] as String?;
      final selectedSajian = asDouble(args?['selectedSajian']);
      return _buildAnimatedRoute(
        settings,
        (_) => FutureBuilder<HasilKlasifikasi?>(
          future: _getDailyClassification(),
          builder: (context, snapshot) {
            final hasil = snapshot.data;
            final dailyLimit = hasil?.batasNatrium ?? 2000;
            return ChatbotScreen(
              apiClient: ApiClient(),
              initialQuestion: initialQuestion,
              productName: args?['productName'] as String?,
              perPortionMg: asDouble(args?['perPortionMg']),
              kategori: args?['kategori'] as String?,
              scanId: asInt(args?['scanId']),
              sodiumLevel: args?['sodiumLevel'] as String?,
              packageMl: asDouble(args?['packageMl']),
              portionsInPackage: asDouble(args?['portionsInPackage']),
              satuanTakaran: args?['satuanTakaran'] as String?,
              imagePath: args?['imagePath'] as String?,
              isConsumptionRecorded: asBool(args?['isConsumptionRecorded']),
              dailyLimitMg: dailyLimit,
              selectedSajian: selectedSajian,
            );
          },
        ),
      );
    }

    if (settings.name == AppRoutes.hasilScanAman ||
        settings.name == AppRoutes.hasilScanWaspada ||
        settings.name == AppRoutes.hasilScanBahaya) {
      final args = settings.arguments as Map<String, dynamic>?;
      final productName = args?['productName'] as String? ?? 'Produk';
      final kategori = args?['kategori'] as String? ?? 'lainnya';
      final userId = args?['userId'] as int? ?? UserSession().getUserId();
      final perPortionMg = args?['sodiumMg'] as int? ?? 0;
      final portionsInPackage = asDouble(args?['porsiPerKemasan']) ?? 1.0;
      final packageMl =
          (asDouble(args?['takaranPerPorsi']) ?? 250.0) * portionsInPackage;
      final initialServings = args?['jumlahKonsumsi'] as int? ?? 1;
      final fromHistory = args?['fromHistory'] as bool? ?? false;

      return _buildAnimatedRoute(
        settings,
        (_) => FutureBuilder<HasilKlasifikasi?>(
          future: _getDailyClassification(),
          builder: (context, snapshot) {
            final hasil = snapshot.data;
            final dailyLimit = hasil?.batasNatrium ?? 2000;
            final sodiumLevel = hasil == null
                ? 'medium'
                : _sodiumLevelLabel(hasil.kategori);
            return HasilScanAmanScreen(
              productName: productName,
              kategori: kategori,
              userId: userId,
              perPortionMg: perPortionMg,
              packageMl: packageMl,
              portionsInPackage: portionsInPackage,
              dailyLimitMg: dailyLimit,
              isHardMaximum: hasil?.isHardMaximum ?? true,
              sodiumLevel: sodiumLevel,
              initialServings: initialServings.toDouble(),
              apiClient: ApiClient(),
              fromHistory: fromHistory,
            );
          },
        ),
      );
    }
    if (settings.name == AppRoutes.hasilBandingkan) {
      final args = settings.arguments as Map<String, dynamic>;
      return _buildAnimatedRoute(
        settings,
        (_) => FutureBuilder<HasilKlasifikasi?>(
          future: _getDailyClassification(),
          builder: (context, snapshot) {
            final hasil = snapshot.data;
            final dailyLimit = hasil?.batasNatrium ?? 2000;
            final sodiumLevel = hasil == null
                ? 'medium'
                : _sodiumLevelLabel(hasil.kategori);
            return HasilBandingkanScreen(
              productA: args['productA'] as ProductCompareData,
              productB: args['productB'] as ProductCompareData,
              dailyLimitMg: dailyLimit,
              isHardMaximum: hasil?.isHardMaximum ?? true,
              sodiumLevel: sodiumLevel,
              apiClient: ApiClient(),
              originalProduct:
                  args['originalProduct']
                      as ProductCompareData?, // ← tambah ini
            );
          },
        ),
      );
    }

    if (settings.name == AppRoutes.sodiumSafe ||
        settings.name == AppRoutes.sodiumUnsafe ||
        settings.name == AppRoutes.sodiumPregnant) {
      final args = settings.arguments;
      final hasil = args is Map<String, dynamic>
          ? args['hasil'] as HasilKlasifikasi?
          : args is HasilKlasifikasi
          ? args
          : null;
      final categoryKey = args is Map<String, dynamic>
          ? args['categoryKey'] as String? ?? hasil?.categoryKey
          : hasil?.categoryKey;
      if (hasil == null) {
        return _buildAnimatedRoute(
          settings,
          (_) => const Scaffold(
            body: Center(child: Text('Hasil klasifikasi tidak tersedia')),
          ),
        );
      }

      return _buildAnimatedRoute(
        settings,
        (_) => SodiumResultScreen(
          categoryKey: categoryKey ?? hasil.categoryKey,
          hasil: hasil,
          dailyLimitMg: hasil.batasNatrium,
        ),
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // locale: DevicePreview.locale(context),
      // builder: DevicePreview.appBuilder,
      title: 'Skenna Sodium',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        textTheme: GoogleFonts.urbanistTextTheme(),
      ),
      initialRoute: '/',
      onGenerateRoute: _onGenerateRoute,
      onUnknownRoute: _notFoundRoute,
    );
  }
}
