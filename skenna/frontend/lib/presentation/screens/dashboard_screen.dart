import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/api_client.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF213868);
    const normalBlue = Color(0xFF2C4A8A);
    const bg = Color(0xFFF5F5F7);

    return Container(
      color: bg,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 16, 26, 130),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 337),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hai, Syakura !',
                              style: TextStyle(
                                color: darkBlue,
                                fontSize: 31,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Yuk, perhatikan natriummu hari ini',
                              style: TextStyle(
                                color: normalBlue,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: normalBlue,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x40000000),
                              blurRadius: 4,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _DailyLimitSection(),
                  const SizedBox(height: 24),
                  _NatriumRecapCard(
                    onTapProduct: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Buka halaman produk')),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Expanded(
                        child: _MiniInfoCard(
                          title: 'Konsumsi\nHari Ini',
                          value: '2500',
                          unit: 'Mg/Na',
                          accent: normalBlue,
                          iconBg: Color(0xFFDFE4ED),
                          icon: Icons.description,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _MiniInfoCard(
                          title: 'Limit\nHari Ini',
                          value: '12',
                          unit: 'Mg/Na',
                          accent: Color(0xFFE53935),
                          iconBg: Color(0xFFFBE1E1),
                          icon: Icons.timer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SkennyCard(
                    onChatTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Buka chat Skenny')),
                      );
                    },
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

class _DailyLimitSection extends StatelessWidget {
  const _DailyLimitSection();

  @override
  Widget build(BuildContext context) {
    const normalBlue = Color(0xFF2C4A8A);

    return Center(
      child: Column(
        children: [
          Container(
            width: 200,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFDFE4ED).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Text(
              'Batas Harianmu',
              style: TextStyle(
                color: normalBlue,
                fontSize: 32 / 1.6,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 240,
            height: 165,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: SvgPicture.asset(
                    'assets/illustrations/daily_limit_blob.svg',
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  width: 136,
                  height: 136,
                  decoration: const BoxDecoration(
                    color: Color(0xFF355297),
                    shape: BoxShape.circle,
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '1250',
                        style: TextStyle(
                          color: Color(0xFFDFE4ED),
                          fontSize: 39,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Mg/Na',
                        style: TextStyle(
                          color: Color(0xFFDFE4ED),
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
          ),
        ],
      ),
    );
  }
}

class _NatriumRecapCard extends StatelessWidget {
  const _NatriumRecapCard({required this.onTapProduct});

  final VoidCallback onTapProduct;

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF213868);
    const normalBlue = Color(0xFF2C4A8A);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rekap Natrium Kamu Hari Ini',
            style: TextStyle(
              color: normalBlue,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Scan produk & cek natrium harianmu!',
            style: TextStyle(
              color: Color(0xFFB0B0B0),
              fontSize: 10,
              fontWeight: FontWeight.w400,
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '1250',
                      style: TextStyle(
                        color: normalBlue,
                        fontSize: 31,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                    TextSpan(
                      text: ' Mg/Na',
                      style: TextStyle(
                        color: normalBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 76,
                height: 28,
                child: ElevatedButton(
                  onPressed: onTapProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkBlue,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Lihat Produk',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 12,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: 0.7,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF54B857),
                          Color(0xFFE6BD56),
                          Color(0xFFC7170B),
                        ],
                        stops: [0.18, 0.76, 0.96],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              '70%',
              style: TextStyle(
                color: Color(0xFFB0B0B0),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfoCard extends StatelessWidget {
  const _MiniInfoCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.iconBg,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final String unit;
  final Color iconBg;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: accent,
                    fontWeight: FontWeight.w400,
                    height: 1,
                  ),
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: accent,
                    fontSize: 44 / 1.4,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    color: accent,
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
        ],
      ),
    );
  }
}

class _SkennyCard extends StatelessWidget {
  const _SkennyCard({required this.onChatTap});

  final VoidCallback onChatTap;

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF213868);
    const normalBlue = Color(0xFF2C4A8A);
    final questions = <String>[
      'Rekomendasi Resep Rendah Natrium',
      'Kenapa natrium perlu dibatasi?',
      'Apa perbedaan batas aman natrium menurut WHO dan DRI?',
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 37,
                height: 40,
                child: Image.asset('assets/illustrations/skenny_mascot.png'),
              ),
              SizedBox(
                width: 92,
                height: 28,
                child: ElevatedButton(
                  onPressed: onChatTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: normalBlue,
                    elevation: 2,
                    shadowColor: const Color(0x40000000),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Chat Skenny',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Halo, Aku Skenny',
            style: TextStyle(
              color: darkBlue,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Siap bantu jawab pertanyaan kamu seputar natrium!',
            style: TextStyle(
              color: normalBlue,
              fontSize: 10,
              fontWeight: FontWeight.w400,
              height: 1,
            ),
          ),
          const SizedBox(height: 10),
          ...questions.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: onChatTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDFE4ED),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: Color(0xFF28437C),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            height: 1,
                          ),
                        ),
                      ),
                      Container(
                        width: 25,
                        height: 25,
                        decoration: const BoxDecoration(
                          color: normalBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
