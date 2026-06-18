import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:skenna/presentation/screens/hasil_perbandingan_produk.dart';

import '../../data/api_client.dart';
import 'scan_screen.dart';
import '../app_shell.dart';
import '../../../data/user_session.dart';

// ════════════════════════════════════════════════════════════════════════════
// Model rekomendasi produk
// ════════════════════════════════════════════════════════════════════════════
class RekomendasiProduk {
  final String namaProduk;
  final int sodiumPerSajianMg;
  final String alasan;

  RekomendasiProduk({
    required this.namaProduk,
    required this.sodiumPerSajianMg,
    required this.alasan,
  });

  factory RekomendasiProduk.fromJson(Map<String, dynamic> json) {
    return RekomendasiProduk(
      namaProduk: json['nama_produk'] as String? ?? '-',
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
    this.userId = 0,
    this.kategori = 'lainnya',
    this.satuanTakaran = 'g',
    this.perPortionMg = 0,
    this.packageMl = 0,
    this.portionsInPackage = 1,
    this.dailyLimitMg = 2000,
    this.isHardMaximum = true,
    this.initialServings = 1,
    this.fromHistory = false,
    this.historyItemId,
    this.isConsumed = false,
    this.imagePath,
    this.apiClient,
    this.onCatatKonsumsi,
    this.readOnly = false,
    this.isFromHistory = false,
    this.rekomendasiJson,
    this.scanId,
  });

  final String productName;
  final int userId;
  final String kategori;
  final String satuanTakaran;
  final int perPortionMg;
  final int packageMl;
  final int portionsInPackage;
  final int dailyLimitMg;
  final bool isHardMaximum;
  final int initialServings;
  final bool fromHistory;
  final String? historyItemId;
  final bool isConsumed;
  final String? imagePath;
  final ApiClient? apiClient;
  final bool readOnly;
  final bool isFromHistory;
  final Map<String, dynamic>? rekomendasiJson;
  final int? scanId;
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

  late int _selectedSajian;
  bool _saving = false;
  bool _sudahDicatat = false;
  int _sajianSaatDicatat = 0;
  String? _localHistoryItemId;

  bool get _sajianBerubah => _selectedSajian != _sajianSaatDicatat;
  bool get _tombolAktif =>
      !widget.readOnly && (!_sudahDicatat || _sajianBerubah);
  bool get _hideScanFlowButtons => widget.isFromHistory;
  String get _limitPhrase =>
      widget.isHardMaximum ? 'batas harian' : 'kebutuhan harian';
  String get _limitWarningPhrase =>
      widget.isHardMaximum ? 'batas' : 'kebutuhan harian';
  String get _limitTitle =>
      widget.isHardMaximum ? 'Batas Harian' : 'Kebutuhan Harian';

  List<RekomendasiProduk> _rekomendasi = [];
  bool _loadingReko = false;
  String? _rekoError;
  String? _tipsTeks;

  @override
  void initState() {
    super.initState();
    _selectedSajian = widget.initialServings;
    _sudahDicatat = widget.fromHistory && widget.isConsumed;
    _sajianSaatDicatat = widget.initialServings;

    if (!widget.fromHistory && !widget.readOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cekOverLimitHarian();
      });
    }

    if (widget.rekomendasiJson != null) {
      _parseRekomendasiFromJson(widget.rekomendasiJson!);
    } else {
      _loadRekomendasi();
    }
  }

  void _parseRekomendasiFromJson(Map<String, dynamic> data) {
    final List<dynamic> items = data['rekomendasi'] ?? [];
    final String? tips = data['tips'] as String?;
    if (tips != null && items.isEmpty) {
      _tipsTeks = tips;
      _rekomendasi = [];
    } else {
      _rekomendasi = items
          .map((e) => RekomendasiProduk.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> _cekOverLimitHarian() async {
    try {
      final userId = UserSession().getUserId();
      if (userId <= 0) return;
      final client = widget.apiClient ?? ApiClient();
      final stats = await client.getDashboardStats(userId);
      final consumedToday =
          (stats['total_sodium_consumed_today'] as num?)?.round() ?? 0;

      if (!mounted) return;
      if (consumedToday >= widget.dailyLimitMg) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Natrium harianmu sudah melebihi $_limitWarningPhrase ${widget.dailyLimitMg} mg!',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Cek over limit gagal: $e');
    }
  }

  Future<void> _loadRekomendasi() async {
    if (!mounted) return;
    setState(() {
      _loadingReko = true;
      _rekoError = null;
      _tipsTeks = null;
    });

    try {
      final client = widget.apiClient ?? ApiClient();
      final result = await client.getRekomendasiProduk(
        kategori: widget.kategori,
        sodiumMg: widget.perPortionMg,
      );
      debugPrint('=== REKO RESULT: $result');
      final List<dynamic> items = result['rekomendasi'] ?? [];
      final String? tips = result['tips'] as String?;

      if (!mounted) return;
      setState(() {
        if (tips != null && items.isEmpty) {
          _tipsTeks = tips;
          _rekomendasi = [];
        } else {
          _rekomendasi = items
              .map((e) => RekomendasiProduk.fromJson(e as Map<String, dynamic>))
              .toList();
          _tipsTeks = null;
        }
        _loadingReko = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _rekoError = 'Gagal memuat rekomendasi.';
        _loadingReko = false;
      });
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
      'minuman_kemasan': 'Minuman Kemasan',
      'biskuit_roti': 'Roti & Biskuit',
      'makanan_kaleng': 'Makanan Kaleng',
      'sereal': 'Sereal & Oatmeal',
      'biskuit': 'Biskuit & Wafer',
      'susu': 'Susu & Produk Susu',
      'frozen_food': 'Frozen Food',
      'lainnya': 'Lainnya',
    };
    return map[k] ?? k;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final circleSize = (screenSize.shortestSide * 0.56)
        .clamp(176.0, 220.0)
        .toDouble();
    final middleCircleSize = circleSize * 0.84;
    final innerCircleSize = circleSize * 0.68;

    // Takaran per sajian (gram/ml per 1 sajian)
    final takaranPerSajian = widget.portionsInPackage > 0
        ? (widget.packageMl / widget.portionsInPackage).round()
        : 0;
    final satuan = widget.satuanTakaran;

    // Total natrium dari sajian yang dipilih
    final totalNatrium = widget.perPortionMg * _selectedSajian;
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
              // ── HEADER ──────────────────────────────────────────────────
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
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_back,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (!_hideScanFlowButtons)
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
                                    horizontal: 15,
                                    vertical: 10,
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
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Scan lagi',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
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
                          width: circleSize,
                          height: circleSize,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                                width: circleSize,
                                height: circleSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _outerCircleColor(pct),
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                                width: middleCircleSize,
                                height: middleCircleSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _midCircleColor(pct),
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                                width: innerCircleSize,
                                height: innerCircleSize,
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
                                  const SizedBox(height: 4),
                                  Text(
                                    '$totalNatrium mg',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Total natrium',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.8),
                                      fontWeight: FontWeight.w600,
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

              // ── % KONTRIBUSI + PROGRESS BAR ─────────────────────────────
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
                          TextSpan(text: 'dari $_limitPhrase '),
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

              // ── PILIH SAJIAN ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Berapa sajian yang kamu konsumsi?'),
                    const SizedBox(height: 6),
                    // Keterangan konteks
                    Text(
                      widget.packageMl > 0
                          ? '1 sajian = $takaranPerSajian $satuan · ${widget.portionsInPackage} sajian per kemasan'
                          : '1 sajian = ${widget.perPortionMg} mg natrium',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: _muted,
                      ),
                    ),
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
                        '$_selectedSajian Sajian  (${_selectedSajian * takaranPerSajian} $satuan)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _blue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PortionSlider(
                      value: _selectedSajian,
                      min: 1,
                      max: 10,
                      onChanged: (v) => setState(() => _selectedSajian = v),
                      thumbColor: _blue,
                      enabled: !widget.readOnly,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── DETAIL PRODUK ───────────────────────────────────────────
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
                      '${widget.packageMl} $satuan (${widget.portionsInPackage} sajian)',
                    ),
                    const SizedBox(height: 8),
                    _infoCard(
                      'Takaran per Sajian',
                      '$takaranPerSajian $satuan',
                    ),
                    const SizedBox(height: 8),
                    _infoCard(
                      'Natrium per Sajian',
                      '${widget.perPortionMg} mg',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── RINGKASAN KONSUMSI ──────────────────────────────────────
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
                              'Total Natrium\nDikonsumsi',
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
                              'Jumlah Sajian\nDikonsumsi',
                              '$_selectedSajian Sajian\n(${_selectedSajian * takaranPerSajian} $satuan)',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── REKOMENDASI ─────────────────────────────────────────────
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

              if (!widget.readOnly && !_hideScanFlowButtons) ...[
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
                      onPressed: (_saving || !_tombolAktif)
                          ? null
                          : _handleCatat,
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
                                imagePath:
                                    widget.imagePath != null &&
                                        widget.imagePath!.startsWith('/')
                                    ? widget.imagePath
                                    : null,
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
              ],
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

    if (_tipsTeks != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFE082)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _tipsTeks!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF7B6000),
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
          'Tidak ada rekomendasi untuk kategori ini.',
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
                  item.namaProduk,
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
                        ? 'Natrium: ${item.sodiumPerSajianMg} mg per sajian'
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
    if (widget.readOnly) return;

    // ── Cek over limit ──────────────────────────────────────────
    final totalNatrium = widget.perPortionMg * _selectedSajian;
    if (totalNatrium > widget.dailyLimitMg) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935)),
              const SizedBox(width: 8),
              Text(
                '$_limitTitle Terlampaui',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: Text(
            'Produk ini menyumbang ${((totalNatrium / widget.dailyLimitMg) * 100).round()}% dari ${_limitPhrase}mu (${widget.dailyLimitMg} mg).\n\nTetap catat konsumsi ini?',
            style: GoogleFonts.plusJakartaSans(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Batal',
                style: GoogleFonts.plusJakartaSans(color: _muted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'Tetap Catat',
                style: GoogleFonts.plusJakartaSans(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      if (confirm != true) return; // user tekan Batal
    }
    setState(() => _saving = true);

    final int activeUserId = UserSession().getUserId();

    try {
      final client = widget.apiClient ?? ApiClient();
      if (activeUserId == 0) return;

      final isUpdate = widget.fromHistory && _sudahDicatat;

      if (isUpdate) {
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
          servings: _selectedSajian,
        );
      } else {
        debugPrint('=== POST SCAN HISTORY ===');
        debugPrint('sodiumMg: ${widget.perPortionMg}');
        debugPrint('servings: $_selectedSajian');
        debugPrint('productName: ${widget.productName}');
        debugPrint('kategori: ${widget.kategori}');
        debugPrint('packageMl: ${widget.packageMl}');
        debugPrint('portionsInPackage: ${widget.portionsInPackage}');
        debugPrint('satuanTakaran: ${widget.satuanTakaran}');
        final response = await client.postScanHistory(
          userId: activeUserId,
          sodiumMg: widget.perPortionMg,
          servings: _selectedSajian,
          productName: widget.productName,
          sodiumLevel: _getSodiumLevel(widget.perPortionMg),
          kategori: widget.kategori,
          packageMl: widget.packageMl,
          portionsInPackage: widget.portionsInPackage,
          satuanTakaran: widget.satuanTakaran,
          isConsumed: true,
          imagePath: widget.imagePath,
          scanId: widget.scanId,
        );
        _localHistoryItemId = response['id'].toString();
      }

      if (!mounted) return;
      setState(() {
        _sudahDicatat = true;
        _sajianSaatDicatat = _selectedSajian;
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
                      borderRadius: BorderRadius.circular(barHeight / 2),
                      gradient: LinearGradient(
                        colors: const [
                          Color(0xFF43A047),
                          Color(0xFFFFBF00),
                          Color(0xFFE53935),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                        begin: Alignment.centerLeft,
                        end: Alignment(
                          progress > 0 ? (1 / progress).clamp(1.0, 10.0) : 1.0,
                          0,
                        ),
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
    this.enabled = true,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final Color thumbColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final range = max - min;
    final fraction = range <= 0 ? 0.0 : (value - min) / range;
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
                  child: IgnorePointer(
                    ignoring: !enabled,
                    child: Slider(
                      value: value.toDouble().clamp(
                        min.toDouble(),
                        math.max(min, max).toDouble(),
                      ),
                      min: min.toDouble(),
                      max: math.max(min, max).toDouble(),
                      divisions: range > 0 ? range : null,
                      onChanged: (v) => onChanged(v.round()),
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
