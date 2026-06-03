import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/api_client.dart';
import '../navigation/app_routes.dart';

enum DashboardGender { male, female }

class _DashboardPalette {
  const _DashboardPalette({
    required this.fallbackName,
    required this.greetingColor,
    required this.subtitleColor,
    required this.sectionTitleColor,
    required this.profileAsset,
    required this.primary,
    required this.heroGradient,
    required this.gaugeCenterText,
  });

  final String fallbackName;
  final Color greetingColor;
  final Color subtitleColor;
  final Color sectionTitleColor;
  final String profileAsset;
  final Color primary;
  final List<Color> heroGradient;
  final Color gaugeCenterText;
}

const _malePalette = _DashboardPalette(
  fallbackName: 'User',
  greetingColor: Color(0xFF2C4A8A),
  subtitleColor: Color(0xFF2C4A8A),
  sectionTitleColor: Color(0xFF213868),
  profileAsset: 'assets/illustrations/profilemale.png',
  primary: Color(0xFF2C4A8A),
  heroGradient: [
    Color(0xFFDFE4ED),
    Color(0xFF8393B4),
    Color(0xFF586F9F),
    Color(0xFF425C95),
    Color(0xFF2C4A8A),
    Color(0xFF28437C),
  ],
  gaugeCenterText: Color(0xFF213868),
);

const _femalePalette = _DashboardPalette(
  fallbackName: 'User',
  greetingColor: Color(0xFFBD1E6D),
  subtitleColor: Color(0xFFBD1E6D),
  sectionTitleColor: Color(0xFF8E1752),
  profileAsset: 'assets/illustrations/profilefemale.png',
  primary: Color(0xFFBD1E6D),
  heroGradient: [
    Color(0xFFF8E9F0),
    Color(0xFFE9B6CF),
    Color(0xFFDB83AE),
    Color(0xFFCC518E),
    Color(0xFFBD1E6D),
    Color(0xFFAA1B62),
  ],
  gaugeCenterText: Color(0xFF8E1752),
);

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.apiClient,
    this.gender = DashboardGender.male,
    this.userName,
  });

  final ApiClient apiClient;
  final DashboardGender gender;
  final String? userName;

  _DashboardPalette get _palette {
    return gender == DashboardGender.female ? _femalePalette : _malePalette;
  }

  String _displayName(_DashboardPalette palette) {
    final trimmed = userName?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return palette.fallbackName;
    }
    return trimmed;
  }

  void _openChatbot(BuildContext context, {String? question}) {
    Navigator.pushNamed(context, AppRoutes.chatbot, arguments: question);
  }

  @override
  Widget build(BuildContext context) {
    final palette = _palette;
    final displayName = _displayName(palette);
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      Theme.of(context).textTheme,
    );
    const bg = Color(0xFFF5F6FA);

    return Container(
      color: bg,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 24, 14, 130),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 362),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCE3EE),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          palette.profileAsset,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 191,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi, $displayName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleLarge?.copyWith(
                                color: palette.greetingColor,
                                fontSize: 32 / 1.6,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pantau Natriummu Hari Ini',
                              style: textTheme.bodyMedium?.copyWith(
                                color: palette.subtitleColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDEE3EC),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: SvgPicture.asset(
                          'assets/icons/edit-2.svg',
                          width: 18,
                          height: 18,
                          colorFilter: ColorFilter.mode(
                            const Color(0xFF2C4A8A),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Rekap Natrium Hari Ini',
                    style: textTheme.titleLarge?.copyWith(
                      color: palette.sectionTitleColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _NatriumRecapCard(
                    palette: palette,
                    onTapProduct: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Buka halaman produk')),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniInfoCard(
                          title: 'Scan Produk',
                          subtitle:
                              'Jumlah produk yang\nkamu scan pada hari ini',
                          value: '5',
                          unit: 'Items',
                          titleColor: const Color(0xFF213868),
                          bodyColor: const Color(0xFF2C4A8A),
                          valueColor: const Color(0xFF2C4A8A),
                          iconBg: const Color(0xFFDFE4ED),
                          icon: Icons.receipt_long_rounded,
                          valueChipColor: const Color(0xFFCAD2E0),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: _MiniInfoCard(
                          title: 'Sisa Natrium',
                          subtitle: 'Sisa batas konsumsi\nnatrium hari ini',
                          value: '260',
                          unit: 'Mg/Na',
                          titleColor: Color(0xFFE53935),
                          bodyColor: Color(0xFFE53935),
                          valueColor: Color(0xFFE53935),
                          iconBg: Color(0xFFFBE1E1),
                          icon: Icons.hourglass_bottom_rounded,
                          valueChipColor: Color(0xFFFCE2E4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Tanya Skenny',
                    style: textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF213868),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SkennyCard(
                    palette: palette,
                    onChatTap: () => _openChatbot(context),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 38,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.zero,
                      child: Row(
                        children: [
                          _QuestionChip(
                            'Bagaimana mencegah Hipertensi?',
                            onTap: () => _openChatbot(
                              context,
                              question: 'Bagaimana mencegah Hipertensi?',
                            ),
                          ),
                          const SizedBox(width: 12),
                          _QuestionChip(
                            'Apa perbedaan batas natrium menurut WHO dan DRI?',
                            onTap: () => _openChatbot(
                              context,
                              question:
                                  'Apa perbedaan batas natrium menurut WHO dan DRI?',
                            ),
                          ),
                          const SizedBox(width: 12),
                          _QuestionChip(
                            'Kenapa hipertensi berbahaya?',
                            onTap: () => _openChatbot(
                              context,
                              question: 'Kenapa hipertensi berbahaya?',
                            ),
                          ),
                          const SizedBox(width: 12),
                          _QuestionChip(
                            'Berikan saya resep rendah natrium',
                            onTap: () => _openChatbot(
                              context,
                              question: 'Berikan saya resep rendah natrium',
                            ),
                          ),
                        ],
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

class _NatriumRecapCard extends StatelessWidget {
  const _NatriumRecapCard({required this.onTapProduct, required this.palette});

  final VoidCallback onTapProduct;
  final _DashboardPalette palette;

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      Theme.of(context).textTheme,
    );

    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.heroGradient,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2610172A),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: 308,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 140,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Batas Harianmu',
                      style: textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '1.500',
                            style: textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                          TextSpan(
                            text: ' Mg/Na',
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Kamu telah konsumsi\n1.240 mg hari ini',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 139,
                      height: 38,
                      child: Material(
                        color: Colors.white.withAlpha(51),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: onTapProduct,
                          borderRadius: BorderRadius.circular(20),
                          child: Center(
                            child: Text(
                              'Lihat Produk',
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              _SodiumRing(centerTextColor: palette.gaugeCenterText),
            ],
          ),
        ),
      ),
    );
  }
}

class _SodiumRing extends StatelessWidget {
  const _SodiumRing({required this.centerTextColor});

  final Color centerTextColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      Theme.of(context).textTheme,
    );

    return SizedBox(
      width: 154,
      height: 154,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: const Size.square(154), painter: _GaugePainter()),
          Container(
            width: 124,
            height: 124,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x20000000),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '1.240',
                  style: textTheme.headlineSmall?.copyWith(
                    color: centerTextColor,
                    fontSize: 31,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mg/Na',
                  style: textTheme.bodyLarge?.copyWith(
                    color: centerTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 10.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    const start = math.pi * 0.85;
    const totalSweep = math.pi * 1.65;
    final sweepA = totalSweep * 0.43;
    final sweepB = totalSweep * 0.26;
    final sweepC = totalSweep * 0.23;

    paint.color = const Color(0xFF53B447);
    canvas.drawArc(rect, start, sweepA, false, paint);
    paint.color = const Color(0xFFA9C729);
    canvas.drawArc(rect, start + sweepA + 0.03, sweepB, false, paint);
    paint.color = const Color(0xFFFF9900);
    canvas.drawArc(rect, start + sweepA + sweepB + 0.06, sweepC, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniInfoCard extends StatelessWidget {
  const _MiniInfoCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.unit,
    required this.iconBg,
    required this.icon,
    required this.titleColor,
    required this.bodyColor,
    required this.valueColor,
    required this.valueChipColor,
  });

  final String title;
  final String subtitle;
  final String value;
  final String unit;
  final Color iconBg;
  final IconData icon;
  final Color titleColor;
  final Color bodyColor;
  final Color valueColor;
  final Color valueChipColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      Theme.of(context).textTheme,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(11, 16, 11, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x0D000000)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2610172A),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: valueColor, size: 22),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              color: titleColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: textTheme.bodySmall?.copyWith(
              color: bodyColor,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 48,
            padding: const EdgeInsets.fromLTRB(13, 3, 13, 6),
            decoration: BoxDecoration(
              color: valueChipColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: textTheme.headlineSmall?.copyWith(
                      color: valueColor,
                      fontSize: 31,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                  TextSpan(
                    text: ' $unit',
                    style: textTheme.bodyLarge?.copyWith(
                      color: valueColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkennyCard extends StatelessWidget {
  const _SkennyCard({required this.onChatTap, required this.palette});

  final VoidCallback onChatTap;
  final _DashboardPalette palette;

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      Theme.of(context).textTheme,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFBEC7DB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 125,
                height: 87,
                child: Image.asset(
                  'assets/illustrations/chatbot_2 2.png',
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 194,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, Aku Skenny',
                      style: textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF2C4A8A),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tanya aku seputar natrium!',
                      style: textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF2C4A8A),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              onPressed: onChatTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C4A8A),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Mulai Tanya',
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionChip extends StatelessWidget {
  const _QuestionChip(this.label, {required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      Theme.of(context).textTheme,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(25),
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFDFE4ED),
          borderRadius: BorderRadius.circular(25),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: const Color(0xFF2C4A8A),
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1,
          ),
        ),
      ),
    );
  }
}
