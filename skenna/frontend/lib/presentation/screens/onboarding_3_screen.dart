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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 36, 16, 28),
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  Text(
                    'Kini Lebih Mudah',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      color: normalBlue,
                      fontSize: 31,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 66),
                  Row(
                    children: const [
                      Expanded(
                        child: _FeatureCard(
                          iconAsset: 'assets/icons/scan.svg',
                          title: 'Scan makanan',
                          description: 'Ketahui natrium\ndalam sekali scan',
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _FeatureCard(
                          iconAsset:
                              'assets/icons/streamline-ultimate_seasoning-food.svg',
                          title: 'Pantau Natrium',
                          description: 'Kontrol konsumsi\nnatrium',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: const [
                      Expanded(
                        child: _FeatureCard(
                          iconAsset: 'assets/icons/repeat-circle.svg',
                          title: 'Banding Natrium',
                          description: 'Temukan pilihan yang\nlebih baik',
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _FeatureCard(
                          iconAsset:
                              'assets/icons/fluent_bot-sparkle-16-regular.svg',
                          title: 'Tanya Skenny',
                          description: 'Bantu pahami\nnatrium makanan',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 52),
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
                        width: 18,
                        height: 8,
                        decoration: BoxDecoration(
                          color: normalBlue,
                          borderRadius: BorderRadius.circular(9999),
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
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text.rich(
                    TextSpan(
                      style: GoogleFonts.plusJakartaSans(
                        color: normalBlue,
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        height: 1.05,
                      ),
                      children: const [
                        TextSpan(
                          text:
                              'Semua fitur yang kamu butuhkan\nuntuk cek natrium ',
                        ),
                        TextSpan(
                          text: 'ada di sini.',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 57,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: normalBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(29),
                        ),
                        elevation: 5,
                        shadowColor: const Color(0x1A0F172A),
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
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.iconAsset,
    required this.title,
    required this.description,
  });

  final String iconAsset;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    const normalBlue = Color(0xFF2C4A8A);
    const lightBlue = Color(0xFFDFE4ED);

    return Container(
      height: 162,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: lightBlue, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F172A05),
            offset: Offset(0, 8),
            blurRadius: 16,
          ),
          BoxShadow(
            color: Color(0x0F172A08),
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: lightBlue,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              iconAsset,
              width: 23,
              height: 23,
              fit: BoxFit.contain,
              colorFilter: const ColorFilter.mode(normalBlue, BlendMode.srcIn),
            ),
          ),
          const Spacer(),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              color: normalBlue,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: GoogleFonts.plusJakartaSans(
              color: normalBlue,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.08,
            ),
          ),
        ],
      ),
    );
  }
}
