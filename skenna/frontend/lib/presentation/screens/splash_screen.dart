import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skenna/data/user_session.dart';

import '../../data/api_client.dart';
import '../navigation/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  late final AnimationController _entranceController;
  late final AnimationController _naFlashController;
  late final Animation<Offset> _skenSlide;
  late final Animation<double> _skenOpacity;
  late final Animation<Offset> _naSlide;
  late final Animation<double> _naOpacity;
  late final Animation<Color?> _naColor;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _subtitleOpacity;
  bool _naFlashStarted = false;
  bool _hasRouted = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _naFlashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _skenSlide = Tween<Offset>(begin: const Offset(-1.0, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
          ),
        );
    _skenOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _naSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.266, 0.6, curve: Curves.elasticOut),
          ),
        );
    _naOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.266, 0.6, curve: Curves.easeOut),
      ),
    );
    _naColor = ColorTween(
      begin: const Color(0xFFBEC7DB),
      end: Colors.white,
    ).chain(CurveTween(curve: Curves.easeOut)).animate(_naFlashController);
    _subtitleSlide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.533, 0.733, curve: Curves.easeOut),
          ),
        );
    _subtitleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.533, 0.733, curve: Curves.easeOut),
      ),
    );

    _entranceController.addListener(() {
      if (!_naFlashStarted && _entranceController.value >= 0.6) {
        _naFlashStarted = true;
        _naFlashController.forward(from: 0).then((_) {
          if (mounted) _naFlashController.reverse();
        });
      }
    });
    _entranceController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Timer(const Duration(milliseconds: 500), _routeFromProfileState);
      }
    });
    _entranceController.forward();
    Future<void>.delayed(const Duration(seconds: 3), _routeFromProfileState);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _naFlashController.dispose();
    super.dispose();
  }

  Future<void> _routeFromProfileState() async {
    if (!mounted) return;
    if (_hasRouted) return;
    _hasRouted = true;

    await UserSession().init();
    final userId = UserSession().getUserId();
    final hasOnboarded = UserSession().hasCompletedOnboarding();

    String nextRoute;

    if (!hasOnboarded) {
      // baru install, belum pernah lihat onboarding
      nextRoute = AppRoutes.onboarding1;
    } else if (userId > 0) {
      // pernah login, sesi (mungkin) masih ada -> cek profil
      try {
        final profile = await _apiClient.getUserProfile(userId);
        final hasProfile =
            (profile['birth_date'] as String?)?.isNotEmpty == true &&
            (profile['gender'] as String?)?.isNotEmpty == true;
        nextRoute = hasProfile ? AppRoutes.dashboard : AppRoutes.profileForm;
      } on ApiException catch (e) {
        if (e.statusCode == 401) {
          // token expired -> login lagi, BUKAN onboarding
          await UserSession().clear();
          nextRoute = AppRoutes.login;
        } else {
          debugPrint('Gagal ambil profil, fallback ke dashboard: $e');
          nextRoute = AppRoutes.dashboard;
        }
      } catch (e) {
        debugPrint(
          'Gagal ambil profil (koneksi/timeout), fallback ke dashboard: $e',
        );
        nextRoute = AppRoutes.dashboard;
      }
    } else {
      nextRoute = AppRoutes.login;
    }

    debugPrint('Navigating: $nextRoute');

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    final logoWidth = (MediaQuery.sizeOf(context).width * 0.46)
        .clamp(150.0, 185.0)
        .toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFF28437C),
      body: SafeArea(
        child: SizedBox.expand(
          child: Align(
            alignment: const Alignment(0, -0.09),
            child: SizedBox(
              width: logoWidth,
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _entranceController,
                  _naFlashController,
                ]),
                builder: (context, child) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FractionalTranslation(
                              translation: _skenSlide.value,
                              child: Opacity(
                                opacity: _skenOpacity.value,
                                child: Text(
                                  'Sken.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 45,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -1.125,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            FractionalTranslation(
                              translation: _naSlide.value,
                              child: Opacity(
                                opacity: _naOpacity.value,
                                child: Text(
                                  'Na',
                                  style: GoogleFonts.poppins(
                                    fontSize: 45,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -1.125,
                                    color:
                                        _naColor.value ??
                                        const Color(0xFFBEC7DB),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      FractionalTranslation(
                        translation: _subtitleSlide.value,
                        child: Opacity(
                          opacity: _subtitleOpacity.value,
                          child: Text(
                            'Track Your Sodium',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
