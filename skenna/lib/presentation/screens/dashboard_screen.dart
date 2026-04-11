import 'package:flutter/material.dart';

import '../../data/api_client.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF2E4D93);
    const bg = Color(0xFFF5F6FA);

    return Container(
      color: bg,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 120),
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
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: navy,
                            height: 1,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Yuk, perhatikan natriummu hari ini',
                          style: TextStyle(color: navy, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: navy,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x332E4D93),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EBF2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text(
                    'Batas Harianmu',
                    style: TextStyle(
                      color: navy,
                      fontWeight: FontWeight.w700,
                      fontSize: 26,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(child: _DailyLimitBlob()),
              const SizedBox(height: 24),
              _NatriumRecapCard(
                onTapProduct: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Buka halaman produk')),
                  );
                },
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Expanded(
                    child: _MiniInfoCard(
                      title: 'Konsumsi\nHari Ini',
                      value: '2500',
                      unit: 'Mg/Na',
                      icon: Icons.assignment,
                      accent: navy,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _MiniInfoCard(
                      title: 'Limit\nHari Ini',
                      value: '12',
                      unit: 'Mg/Na',
                      icon: Icons.timer,
                      accent: Color(0xFFE64646),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
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
    );
  }
}

class _DailyLimitBlob extends StatelessWidget {
  const _DailyLimitBlob();

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF2E4D93);
    return SizedBox(
      width: 300,
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 36,
            left: 35,
            right: 35,
            child: Container(
              height: 132,
              decoration: BoxDecoration(
                color: const Color(0xFFBFC8DD),
                borderRadius: BorderRadius.circular(64),
              ),
            ),
          ),
          Container(
            width: 168,
            height: 168,
            decoration: const BoxDecoration(
              color: navy,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x442E4D93),
                  blurRadius: 22,
                  offset: Offset(0, 9),
                ),
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '1250',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                Text(
                  'Mg/Na',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            top: 18,
            child: _Dot(size: 12, color: Color(0xFFBFC8DD)),
          ),
          const Positioned(
            left: 18,
            top: 94,
            child: _Dot(size: 34, color: Color(0xFFAAB7D6)),
          ),
          const Positioned(
            left: 22,
            top: 140,
            child: _Dot(size: 16, color: Color(0xFFAAB7D6)),
          ),
          const Positioned(
            right: 18,
            top: 78,
            child: _Dot(size: 16, color: navy),
          ),
          const Positioned(
            right: 6,
            top: 90,
            child: _Dot(size: 10, color: navy),
          ),
          const Positioned(
            bottom: 14,
            right: 92,
            child: _Dot(size: 8, color: Color(0xFFAAB7D6)),
          ),
          const Positioned(
            bottom: 8,
            right: 74,
            child: _Dot(size: 20, color: navy),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _NatriumRecapCard extends StatelessWidget {
  const _NatriumRecapCard({required this.onTapProduct});

  final VoidCallback onTapProduct;

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF2E4D93);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rekap Natrium Kamu Hari Ini',
            style: TextStyle(
              color: navy,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Scan produk & cek natrium harianmu!',
            style: TextStyle(color: Color(0xFFB1B1B1), fontSize: 15),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                '1250',
                style: TextStyle(
                  color: navy,
                  fontSize: 50,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              const Text('Mg/Na', style: TextStyle(color: navy, fontSize: 36)),
              const Spacer(),
              SizedBox(
                height: 36,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: onTapProduct,
                  child: const Text('Lihat Produk'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 0.3,
              minHeight: 11,
              backgroundColor: const Color(0xFFE8E8E8),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF4CAF50),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Align(
            alignment: Alignment.centerRight,
            child: Text('30%', style: TextStyle(color: Color(0xFFA0A0A0))),
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
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 16, color: accent, height: 1.2),
                ),
              ),
              CircleAvatar(
                radius: 16,
                backgroundColor: accent.withOpacity(0.15),
                child: Icon(icon, color: accent, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: accent,
                  fontSize: 46,
                  fontWeight: FontWeight.w700,
                  height: 0.95,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  unit,
                  style: TextStyle(color: accent, fontSize: 16),
                ),
              ),
            ],
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
    const navy = Color(0xFF2E4D93);
    final questions = <String>[
      'Rekomendasi Resep Rendah Natrium',
      'Kenapa natrium perlu dibatasi?',
      'Apa perbedaan batas aman natrium menurut WHO dan DRI?',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFEAF0FF),
                child: Icon(Icons.android, color: navy),
              ),
              const Spacer(),
              SizedBox(
                height: 38,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: navy,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  onPressed: onChatTap,
                  child: const Text('Chat Skenny'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Halo, Aku Skenny',
            style: TextStyle(
              color: navy,
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Siap bantu jawab pertanyaan kamu seputar natrium!',
            style: TextStyle(color: navy),
          ),
          const SizedBox(height: 14),
          ...questions.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onChatTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4E9F4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(color: navy, fontSize: 16),
                        ),
                      ),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: navy,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                          size: 20,
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
