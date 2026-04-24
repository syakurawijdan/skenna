import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../navigation/app_routes.dart';

class Onboarding3Screen extends StatelessWidget {
  const Onboarding3Screen({super.key});

  @override
  Widget build(BuildContext context) {
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
                      'Kini Lebih Mudah\ndengan Skenna',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        color: normalBlue,
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
                                width: 343,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Row(
                                      children: [
                                        _FeatureCard(
                                          iconAsset: 'assets/icons/scan.svg',
                                          iconSize: 32,
                                          title: 'Scan makanan',
                                          description:
                                              'Ketahui natrium dalam sekali scan',
                                        ),
                                        SizedBox(width: 16),
                                        _FeatureCard(
                                          iconAsset:
                                              'assets/icons/streamline-ultimate_seasoning-food.svg',
                                          iconSize: 29,
                                          title: 'Pantau Natrium',
                                          description:
                                              'Kontrol konsumsi natrium',
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16),
                                    Row(
                                      children: [
                                        _FeatureCard(
                                          iconAsset:
                                              'assets/icons/repeat-circle.svg',
                                          iconSize: 30,
                                          title: 'Banding Produk',
                                          description:
                                              'Temukan pilihan yang lebih baik',
                                        ),
                                        SizedBox(width: 16),
                                        _FeatureCard(
                                          iconAsset:
                                              'assets/icons/fluent_bot-sparkle-16-regular.svg',
                                          iconSize: 26,
                                          title: 'Tanya Skenny',
                                          description:
                                              'Bantu pahami natrium makanan',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
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
                          Text.rich(
                            TextSpan(
                              style: GoogleFonts.plusJakartaSans(
                                color: normalBlue,
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                                height: 1,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Semua fitur',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: normalBlue,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    height: 1,
                                  ),
                                ),
                                const TextSpan(text: ' yang kamu butuhkan\n'),
                                const TextSpan(text: 'untuk cek natrium '),
                                TextSpan(
                                  text: 'ada di sini.',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: normalBlue,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
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
                          Navigator.pushNamed(context, AppRoutes.profileForm);
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
      width: 163.5,
      height: 160,
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
          const SizedBox(height: 24),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: darkBlue,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: normalBlue,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
