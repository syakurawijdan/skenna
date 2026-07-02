import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../navigation/app_routes.dart';
import '../../data/user_session.dart';

class Onboarding3Screen extends StatelessWidget {
  const Onboarding3Screen({super.key});

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
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Judul
                    Text(
                      'Kini Lebih Mudah\ndengan Skenna',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        color: darkBlue,
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Konten utama (4 kartu fitur)
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: const [
                                  Expanded(
                                    child: _FeatureCard(
                                      iconAsset: 'assets/icons/scan.svg',
                                      iconSize: 32,
                                      title: 'Scan makanan',
                                      description:
                                          'Ketahui natrium dalam sekali scan',
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: _FeatureCard(
                                      iconAsset:
                                          'assets/icons/streamline-ultimate_seasoning-food.svg',
                                      iconSize: 29,
                                      title: 'Pantau Natrium',
                                      description: 'Kontrol konsumsi natrium',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: const [
                                  Expanded(
                                    child: _FeatureCard(
                                      iconAsset:
                                          'assets/icons/repeat-circle.svg',
                                      iconSize: 30,
                                      title: 'Banding Produk',
                                      description:
                                          'Temukan pilihan yang lebih baik',
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: _FeatureCard(
                                      iconAsset:
                                          'assets/icons/fluent_bot-sparkle-16-regular.svg',
                                      iconSize: 26,
                                      title: 'Tanya Skenny',
                                      description:
                                          'Bantu pahami natrium makanan',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Bagian bawah: dot + teks + button
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Dot + teks
                          Column(
                            children: [
                              Row(
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
                                    width: 17,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: normalBlue,
                                      borderRadius: BorderRadius.circular(9999),
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
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                    height: 1.2,
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: 'Semua Fitur ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          'yang kamu butuhkan\nuntuk cek natrium ',
                                    ),
                                    TextSpan(
                                      text: 'ada di sini',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Button
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 343),
                            child: Container(
                              width: double.infinity,
                              height: 55,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x26000000),
                                    offset: Offset(0, 4),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: darkBlue,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                onPressed: () async {
                                  await UserSession().setHasCompletedOnboarding(
                                    true,
                                  );
                                  if (context.mounted) {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.welcome,
                                    );
                                  }
                                },
                                child: Text(
                                  'Mulai',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w600,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.iconAsset,
    required this.iconSize,
    required this.title,
    required this.description,
  });

  final String iconAsset;
  final double iconSize;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    const normalBlue = Color(0xFF2C4A8A);
    const darkBlue = Color(0xFF213868);
    const lightBlue = Color(0xFFDFE4ED);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: lightBlue, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
          BoxShadow(
            color: Color(0x050F172A),
            offset: Offset(0, 8),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: lightBlue,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              iconAsset,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
              colorFilter: const ColorFilter.mode(normalBlue, BlendMode.srcIn),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: darkBlue,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.visible,
            softWrap: true,
            style: GoogleFonts.plusJakartaSans(
              color: normalBlue,
              fontSize: 11,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
