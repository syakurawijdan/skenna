import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skenna/presentation/screens/hasil_perbandingan_produk.dart';
import 'package:skenna/presentation/screens/hasil_perbandingan_produk.dart';

import '../../data/api_client.dart';
import 'scan_screen.dart';
import 'history_screen.dart';
import '../app_shell.dart';
import '../../../data/user_session.dart';

// ════════════════════════════════════════════════════════════════════════════
// Model rekomendasi produk
// ════════════════════════════════════════════════════════════════════════════
class RekomendasiProduk {
  final String namaProduk;
  final String merek;
  final int sodiumPerSajianMg;
  final String alasan;

  RekomendasiProduk({
    required this.namaProduk,
    required this.merek,
    required this.sodiumPerSajianMg,
    required this.alasan,
  });

  factory RekomendasiProduk.fromJson(Map<String, dynamic> json) {
    return RekomendasiProduk(
      namaProduk: json['nama_produk'] as String? ?? '-',
      merek: json['merek'] as String? ?? '-',
      sodiumPerSajianMg: (json['sodium_per_sajian_mg'] as num?)?.toInt() ?? 0,
      alasan: json['alasan'] as String? ?? '-',
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Widget utama
// ════════════════════════════════════════════════════════════════════════════
class HasilScanAmanScreen extends StatefulWidget {
  const HasilScanAmanScreen({
    super.key,
    this.productName = 'Produk',
    this.userId = 1,
    this.kategori = 'lainnya',
    this.satuanTakaran = 'g',
    this.perPortionMg = 220,
    this.packageMl = 1000,
    this.portionsInPackage = 10,
    this.dailyLimitMg = 2000,
    this.initialServings = 1,
    this.fromHistory = false,
    this.historyItemId,
    this.isConsumed = false,
    this.imagePath,
    this.apiClient,
    this.onCatatKonsumsi,
  });

  final String productName;
  final int userId;
  final String kategori;
  final String satuanTakaran;
  final int perPortionMg;
  final int packageMl;
  final int portionsInPackage;
  final int dailyLimitMg;
  final int initialServings;
  final bool fromHistory;
  final String? historyItemId;
  final bool isConsumed; // ← true = sudah pernah dicatat, false = belum
  final String? imagePath;
  final ApiClient? apiClient;
  final Future<Map<String, dynamic>> Function({
    required int sodiumMg,
    required int servings,
    String? productName,
  })?
  onCatatKonsumsi;

  @override
  State<HasilScanAmanScreen> createState() => _HasilScanAmanScreenState();
}

class _HasilScanAmanScreenState extends State<HasilScanAmanScreen> {
  static const _navy = Color(0xFF1E3A6E);
  static const _blue = Color(0xFF2C4A8A);
  static const _muted = Color(0xFFAAAAAA);
  static const _bgCard = Color(0xFFF5F7FA);
  static const _colorSafe = Color(0xFF43A047);
  static const _colorWarn = Color(0xFFFFBF00);
  static const _colorDanger = Color(0xFFE53935);

  static const _geminiApiKey = '';

  late int _selectedPortions;
  bool _saving = false;
  bool _sudahDicatat = false;
  int _portionsSaatDicatat = 0;
  String? _localHistoryItemId;

  bool get _porsiBerubaH => _selectedPortions != _portionsSaatDicatat;

  bool get _tombolAktif => !_sudahDicatat || _porsiBerubaH;

  List<RekomendasiProduk> _rekomendasi = [];
  bool _loadingReko = false;
  String? _rekoError;

  @override
  void initState() {
    super.initState();
    _selectedPortions = widget.initialServings;
    _sudahDicatat = widget.fromHistory && widget.isConsumed;
    _portionsSaatDicatat = widget.initialServings;

    if (widget.fromHistory) {
      _localHistoryItemId = widget.historyItemId;
    } else {
      _localHistoryItemId = DateTime.now().millisecondsSinceEpoch.toString();
      // _simpanScanKeHistory();
    }

    _loadRekomendasi();
  }

  // bool _historySaved = false;
  // Future<void> _simpanScanKeHistory() async {
  //   if (widget.productName == 'Produk' && widget.perPortionMg == 0) {
  //     debugPrint('Skip simpan: data produk kosong');
  //     _historySaved = true;
  //     return;
  //   }

  //   try {
  //     final client = widget.apiClient ?? ApiClient();
  //     final activeUserId = UserSession().getUserId();
  //     if (activeUserId == 0) {
  //       debugPrint('Skip simpan: user belum login');
  //       _historySaved = true;
  //       return;
  //     }

  //     final response = await client.postScanHistory(
  //       userId: activeUserId,
  //       sodiumMg: widget.perPortionMg,
  //       servings: _selectedPortions,
  //       productName: widget.productName,
  //       sodiumLevel: _getSodiumLevel(widget.perPortionMg),
  //       kategori: widget.kategori,
  //       packageMl: widget.packageMl,
  //       portionsInPackage: widget.portionsInPackage,
  //       satuanTakaran: widget.satuanTakaran,
  //     );
  //     _localHistoryItemId = response['id'].toString();
  //     _historySaved = true;
  //   } catch (e) {
  //     debugPrint('postScanHistory error: $e');
  //     _historySaved = true;
  //   }
  // }

  // ── Prompt rekomendasi ───────────────────────────────────────────────────
  String _buildRekomendasiPrompt(String kategori, int sodiumMg) {
    return '''
Berikan 1 rekomendasi produk kemasan yang dijual di Indonesia
dengan kategori "$kategori" yang memiliki kandungan natrium
lebih rendah dari $sodiumMg mg per sajian.
Respons WAJIB hanya raw JSON tanpa Markdown backticks, tanpa penjelasan apapun.

{
  "rekomendasi": [
    {
      "nama_produk": string,
      "kategori": string,
      "sodium_per_sajian_mg": number
    }
  ]
}

ATURAN:
1. Hanya produk kemasan nyata yang beredar di Indonesia
2. Jika tidak ada produk nyata yang diketahui untuk kategori ini,
   berikan saran generik seperti "Pilih produk berlabel rendah sodium"
   dengan sodium_per_sajian_mg diisi 0
4. Semua angka harus NUMBER bukan string
''';
  }

  Future<void> _loadRekomendasi() async {
    if (!mounted) return;
    setState(() {
      _loadingReko = true;
      _rekoError = null;
    });

    try {
      final prompt = _buildRekomendasiPrompt(
        widget.kategori,
        widget.perPortionMg,
      );

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_geminiApiKey',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
              ],
            },
          ],
          "generationConfig": {"temperature": 0.2, "maxOutputTokens": 1000},
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final text =
            decoded['candidates'][0]['content']['parts'][0]['text'] as String;

        final cleanText = text
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        final Map<String, dynamic> data = jsonDecode(cleanText);
        final List<dynamic> list = data['rekomendasi'] as List<dynamic>;

        if (mounted) {
          setState(() {
            _rekomendasi = list
                .map((e) => RekomendasiProduk.fromJson(e))
                .toList();
            _loadingReko = false;
          });
        }
      } else {
        throw Exception('API Error ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _rekoError = 'Gagal memuat rekomendasi';
          _loadingReko = false;
        });
      }
      debugPrint('Rekomendasi error: $e');
    }
  }

  double _pct(int mg) => mg / widget.dailyLimitMg;

  Color _arcColor(double p) => p <= .50
      ? _colorSafe
      : p <= .75
      ? _colorWarn
      : _colorDanger;

  Color _circleColor(double p) => p <= .50
      ? const Color(0xFF2E9E3E)
      : p <= .75
      ? const Color(0xFFFFBF00)
      : const Color(0xFFE53935);

  Color _outerCircleColor(double p) => Colors.white.withOpacity(0.20);
  Color _midCircleColor(double p) => Colors.white.withOpacity(0.25);

  String _statusText(double p) => p <= .50
      ? 'Masih dalam batas aman'
      : p <= .75
      ? 'Mulai perhatikan asupan natrium'
      : 'Hampir mencapai batas harian';

  List<Color> _gradientColors(double p) => p <= .50
      ? [
          const Color(0xFF3C9040),
          const Color(0xFF43A047),
          const Color(0xFFC5E2C6),
          const Color(0xFFE8F8EA),
          const Color(0xFFFFFFFF),
        ]
      : p <= .75
      ? [
          const Color(0xFFE6AC00),
          const Color(0xFFFFBF00),
          const Color(0xFFFFEBB0),
          const Color(0xFFFFF8DC),
          const Color(0xFFFFFFFF),
        ]
      : [
          const Color(0xFFCE3330),
          const Color(0xFFE53935),
          const Color(0xFFF7C2C0),
          const Color(0xFFFFEBEE),
          const Color(0xFFFFFFFF),
        ];

  String _labelKategori(String k) {
    const map = {
      'mie_instan': 'Mie & Pasta Instan',
      'keripik_snack': 'Snack & Keripik',
      'saus_bumbu': 'Saus & Bumbu',
      'minuman_kemasan': 'Minuman Kemasan',
      'biskuit_roti': 'Roti & Biskuit',
      'makanan_kaleng': 'Makanan Kaleng',
      'sereal': 'Sereal & Oatmeal',
      'frozen_food': 'Frozen Food',
      'lainnya': 'Lainnya',
    };
    return map[k] ?? k;
  }

  // ── build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final portionSatuan = (widget.packageMl / widget.portionsInPackage).round();
    final satuan = widget.satuanTakaran;
    final totalNatrium = widget.perPortionMg * _selectedPortions;
    final pct = _pct(totalNatrium);
    final arcColor = _arcColor(pct);
    final pctInt = (pct * 100).round();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── HEADER ─────────────────────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: _gradientColors(pct),
                    stops: const [0.0, 0.45, 0.65, 0.82, 0.95],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (widget.fromHistory) {
                                  Navigator.pop(context);
                                } else {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AppShell(),
                                    ),
                                    (route) => false,
                                  );
                                }
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.chevron_left,
                                  size: 24,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ScanScreen(apiClient: widget.apiClient),
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.camera_alt_outlined,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Scan lagi',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Text(
                          'Kontribusi Produk Ini',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          width: 220,
                          height: 220,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _outerCircleColor(pct),
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                                width: 185,
                                height: 185,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _midCircleColor(pct),
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _circleColor(pct),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/fluent_molecule-24-regular.svg',
                                    width: 22,
                                    height: 22,
                                    colorFilter: ColorFilter.mode(
                                      Colors.white.withOpacity(0.85),
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$totalNatrium mg',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 31,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Total natrium',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _blue,
                        ),
                        children: [
                          const TextSpan(text: 'Produk ini menyumbang '),
                          TextSpan(
                            text: '$pctInt%',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: arcColor,
                              fontSize: 16,
                            ),
                          ),
                          const TextSpan(text: ' natrium\n'),
                          const TextSpan(text: 'dari batas harian '),
                          TextSpan(
                            text: '${widget.dailyLimitMg} mg',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              color: _blue,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    _GradientProgressBar(
                      progress: pct.clamp(0.0, 1.0),
                      thumbColor: arcColor,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Porsi Konsumsi'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: _blue, width: 1.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_selectedPortions Porsi',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _blue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PortionSlider(
                      value: _selectedPortions,
                      min: 1,
                      max: widget.portionsInPackage,
                      onChanged: (v) => setState(() => _selectedPortions = v),
                      thumbColor: _blue,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Detail Produk'),
                    const SizedBox(height: 10),
                    _infoCard('Nama Produk', widget.productName),
                    const SizedBox(height: 8),
                    _infoCard('Kategori', _labelKategori(widget.kategori)),
                    const SizedBox(height: 8),
                    _infoCard(
                      'Isi Kemasan',
                      '${widget.packageMl} $satuan (${widget.portionsInPackage} Porsi)',
                    ),
                    const SizedBox(height: 8),
                    _infoCard('Satu Porsi', '$portionSatuan $satuan'),
                    const SizedBox(height: 8),
                    _infoCard('Natrium per Porsi', '${widget.perPortionMg} mg'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Ringkasan Konsumsi'),
                    const SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _summaryCard(
                              SvgPicture.asset(
                                'assets/icons/hugeicons_serving-food.svg',
                                width: 28,
                                height: 28,
                              ),
                              'Natrium\nDikonsumsi',
                              '$totalNatrium mg',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _summaryCard(
                              SvgPicture.asset(
                                'assets/icons/fluent_food-24-regular.svg',
                                width: 28,
                                height: 28,
                              ),
                              'Jumlah yang\nkamu konsumsi',
                              '$_selectedPortions Porsi\n($portionSatuan $satuan)',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Alternatif Lebih Rendah Natrium'),
                    const SizedBox(height: 10),
                    _buildRekomendasiSection(),
                  ],
                ),
              ),

              const SizedBox(height: 78),

              // ── Catat Konsumsi ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _tombolAktif
                          ? _blue
                          : const Color(0xFFD9D9D9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 0,
                    ),
                    onPressed: (_saving || !_tombolAktif) ? null : _handleCatat,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _sudahDicatat
                                ? 'Perbarui Konsumsi'
                                : 'Catat Konsumsi',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ScanScreen(
                            apiClient: widget.apiClient,
                            compareWithProduct: ProductCompareData(
                              productName: widget.productName,
                              kategori: widget.kategori,
                              satuanTakaran: widget.satuanTakaran,
                              perPortionMg: widget.perPortionMg,
                              packageMl: widget.packageMl,
                              portionsInPackage: widget.portionsInPackage,
                            ),
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Bandingkan Produk',
                      style: GoogleFonts.plusJakartaSans(
                        color: _blue,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Rekomendasi section ──────────────────────────────────────────────────
  Widget _buildRekomendasiSection() {
    if (_loadingReko) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F1E3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBEE6C9)),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF3C8B3E),
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_rekoError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: _muted, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _rekoError!,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _muted),
              ),
            ),
            TextButton(
              onPressed: _loadRekomendasi,
              child: Text(
                'Coba lagi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: _blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_rekomendasi.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F1E3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBEE6C9)),
        ),
        child: Text(
          'Tidak ada rekomendasi yang ditemukan untuk kategori ini.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF3C8B3E),
          ),
        ),
      );
    }

    return Column(
      children: _rekomendasi.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F1E3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBEE6C9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.merek} – ${item.namaProduk}',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF3C8B3E),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC5E2C6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.sodiumPerSajianMg > 0
                        ? 'Natrium: ${item.sodiumPerSajianMg} mg per porsi'
                        : 'Pilih produk berlabel rendah sodium',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF3C8B3E),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (item.alasan.isNotEmpty && item.alasan != '-') ...[
                  const SizedBox(height: 8),
                  Text(
                    item.alasan,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF4A7C4F),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _handleCatat() async {
    setState(() => _saving = true);

    final int activeUserId = UserSession().getUserId();
    debugPrint('=== DEBUG CATAT ===');
    debugPrint('fromHistory: ${widget.fromHistory}');
    debugPrint('isConsumed: ${widget.isConsumed}');

    try {
      final client = widget.apiClient ?? ApiClient();
      if (activeUserId == 0) return;

      final isUpdate = widget.fromHistory && _sudahDicatat;

      if (isUpdate) {
        // ── Mode history: update porsi saja ──────────────────────────────
        final intakeId = int.tryParse(_localHistoryItemId ?? '');
        if (intakeId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('ID konsumsi tidak valid, coba scan ulang'),
              backgroundColor: const Color(0xFFE53935),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          setState(() => _saving = false);
          return;
        }
        await client.updateIntakeConsumed(
          intakeId: intakeId,
          userId: activeUserId,
          isConsumed: true,
          servings: _selectedPortions,
        );
      } else {
        // ── Mode scan baru: simpan dulu baru mark consumed ───────────────
        final response = await client.postScanHistory(
          userId: activeUserId,
          sodiumMg: widget.perPortionMg,
          servings: _selectedPortions,
          productName: widget.productName,
          sodiumLevel: _getSodiumLevel(widget.perPortionMg),
          kategori: widget.kategori,
          packageMl: widget.packageMl,
          portionsInPackage: widget.portionsInPackage,
          satuanTakaran: widget.satuanTakaran,
          isConsumed: true,
        );
        _localHistoryItemId = response['id'].toString();
      }

      if (!mounted) return;
      setState(() {
        _sudahDicatat = true;
        _portionsSaatDicatat = _selectedPortions;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUpdate
                ? 'Konsumsi berhasil diperbarui ✓'
                : 'Konsumsi berhasil dicatat ✓',
          ),
          backgroundColor: const Color(0xFF43A047),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AppShell(initialIndex: 2)),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: $e'),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _getSodiumLevel(int mg) {
    if (mg < 140) return 'low';
    if (mg < 400) return 'medium';
    return 'high';
  }

  // ── Helper widget ────────────────────────────────────────────────────────
  Widget _sectionTitle(String text) => Text(
    text,
    style: GoogleFonts.plusJakartaSans(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: _blue,
    ),
  );

  Widget _infoCard(String label, String value) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: _bgCard,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: _navy),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _blue,
          ),
        ),
      ],
    ),
  );

  Widget _summaryCard(Widget icon, String label, String value) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFEEEEEE)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        icon,
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: _navy,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _blue,
            height: 1.3,
          ),
        ),
      ],
    ),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// Progress Bar Gradient
// ════════════════════════════════════════════════════════════════════════════
class _GradientProgressBar extends StatelessWidget {
  const _GradientProgressBar({
    required this.progress,
    required this.thumbColor,
  });

  final double progress;
  final Color thumbColor;

  List<Color> _gradientColors() {
    if (progress <= 0.50) {
      return [const Color(0xFF43A047), const Color(0xFF43A047)];
    }
    if (progress <= 0.75) {
      return [const Color(0xFF43A047), const Color(0xFFFFBF00)];
    }
    return [
      const Color(0xFF43A047),
      const Color(0xFFFFBF00),
      const Color(0xFFE53935),
    ];
  }

  List<double> _gradientStops() {
    if (progress <= 0.50) return [0.0, 1.0];
    if (progress <= 0.75) return [0.0, 1.0];
    return [0.0, 0.5, 1.0];
  }

  @override
  Widget build(BuildContext context) {
    const barHeight = 16.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth;
        final filledWidth = (barWidth * progress).clamp(0.0, barWidth);
        return SizedBox(
          height: barHeight,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(barHeight / 2),
                child: Container(
                  width: barWidth,
                  height: barHeight,
                  color: const Color(0xFFE0E0E0),
                ),
              ),
              if (filledWidth > 0)
                ClipRRect(
                  borderRadius: BorderRadius.circular(barHeight / 2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    width: filledWidth,
                    height: barHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _gradientColors(),
                        stops: _gradientStops(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Slider dengan kotak angka melayang
// ════════════════════════════════════════════════════════════════════════════
class _PortionSlider extends StatelessWidget {
  const _PortionSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.thumbColor,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final Color thumbColor;

  @override
  Widget build(BuildContext context) {
    final fraction = (value - min) / (max - min);
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        const thumbRadius = 12.0;
        const horizontalPadding = 16.0;
        final usableWidth = trackWidth - horizontalPadding * 2;
        final thumbX = horizontalPadding + usableWidth * fraction;
        const boxW = 36.0;
        const boxH = 32.0;
        final boxLeft = (thumbX - boxW / 2).clamp(0.0, trackWidth - boxW);

        return SizedBox(
          height: boxH + 8 + thumbRadius * 2 + 8,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: boxLeft,
                top: 0,
                child: Container(
                  width: boxW,
                  height: boxH,
                  decoration: BoxDecoration(
                    color: thumbColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$value',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: thumbX - 5,
                top: boxH,
                child: CustomPaint(
                  painter: _TrianglePainter(color: thumbColor),
                  size: const Size(10, 6),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: thumbColor,
                    thumbColor: thumbColor,
                    inactiveTrackColor: const Color(0xFFD7DCE8),
                    overlayColor: thumbColor.withOpacity(0.1),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: thumbRadius,
                    ),
                    showValueIndicator: ShowValueIndicator.never,
                  ),
                  child: Slider(
                    value: value.toDouble(),
                    min: min.toDouble(),
                    max: max.toDouble(),
                    divisions: (max - min) > 0 ? (max - min) : null,
                    onChanged: (v) => onChanged(v.round()),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Triangle painter
// ════════════════════════════════════════════════════════════════════════════
class _TrianglePainter extends CustomPainter {
  const _TrianglePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}
