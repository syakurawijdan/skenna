import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_shell.dart';
import 'scan_screen.dart';
import '../../data/api_client.dart';
import '../../domain/kategori_label.dart';
import '../../../data/user_session.dart';
import '../widgets/stop_natrium_dialog.dart';
import '../widgets/yakin_makan_dialog.dart';
import '../widgets/unsaved_changes_dialog.dart';

// ════════════════════════════════════════════════════════════════════════════
// Model data produk untuk perbandingan
// ════════════════════════════════════════════════════════════════════════════
class ProductCompareData {
  final String productName;
  final String kategori;
  final String satuanTakaran;
  final int perPortionMg;
  final int packageMl;
  final int portionsInPackage;
  final String? imagePath;

  const ProductCompareData({
    required this.productName,
    required this.kategori,
    required this.satuanTakaran,
    required this.perPortionMg,
    required this.packageMl,
    required this.portionsInPackage,
    this.imagePath,
  });
}

class HasilBandingkanScreen extends StatefulWidget {
  const HasilBandingkanScreen({
    super.key,
    required this.productA,
    required this.productB,
    this.dailyLimitMg = 2000,
    this.isHardMaximum = true,
    this.apiClient,
    this.readOnly = false,
    this.originalProduct,
    this.sodiumLevel = 'medium',
    this.fromHistory = false,
    this.historyItemId,
    this.isConsumed = false,
    this.selectedProductName,
  });

  final ProductCompareData productA;
  final ProductCompareData productB;
  final int dailyLimitMg;
  final bool isHardMaximum;
  final ApiClient? apiClient;
  final bool readOnly;
  final ProductCompareData? originalProduct;
  final String sodiumLevel;
  final bool fromHistory;
  final String? historyItemId;
  final bool isConsumed;
  final String? selectedProductName;

  @override
  State<HasilBandingkanScreen> createState() => _HasilBandingkanScreenState();
}

class _HasilBandingkanScreenState extends State<HasilBandingkanScreen>
    with SingleTickerProviderStateMixin {
  static const _navy = Color(0xFF1E3A6E);
  static const _blue = Color(0xFF2C4A8A);
  static const _bgCard = Color(0xFFF5F7FA);
  static const _colorSafe = Color(0xFF43A047);
  static const _colorWarn = Color(0xFFFFBF00);
  static const _colorDanger = Color(0xFFE53935);

  late TabController _tabController;
  bool _saving = false;
  int _selectedProduct = 0;
  int _selectedProductSaatDicatat = 0;
  bool _statusDikonsumsi = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.fromHistory) {
      if (widget.selectedProductName == widget.productB.productName) {
        _selectedProduct = 2;
        _selectedProductSaatDicatat = 2;
        _tabController.index = 1;
      } else {
        _selectedProduct = 1;
        _selectedProductSaatDicatat = 1;
      }
    }
    _statusDikonsumsi = widget.isConsumed;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  bool get _aLebihRendah =>
      widget.productA.perPortionMg <= widget.productB.perPortionMg;

  ProductCompareData get _winner =>
      _aLebihRendah ? widget.productA : widget.productB;
  ProductCompareData get _loser =>
      _aLebihRendah ? widget.productB : widget.productA;

  bool get _pilihanBerubah => _selectedProduct != _selectedProductSaatDicatat;
  bool get _adaPerubahanBelumDisimpan {
    if (widget.readOnly) return false;
    if (!_statusDikonsumsi) return false;
    return _pilihanBerubah;
  }

  bool get _tombolAktif {
    if (widget.readOnly) return false;
    if (_selectedProduct == 0) return false;
    if (!_statusDikonsumsi) return true;
    return _pilihanBerubah;
  }

  double _pct(int mg) => mg / widget.dailyLimitMg;
  String get _limitPhrase =>
      widget.isHardMaximum ? 'batas harian' : 'kebutuhan harian';

  Color _barColor(double p) => p <= .50
      ? _colorSafe
      : p <= .75
      ? _colorWarn
      : _colorDanger;

  String _selisihPersen() {
    final lo = _winner.perPortionMg;
    final hi = _loser.perPortionMg;
    if (hi == 0) return '0';
    return ((hi - lo) / hi * 100).round().toString();
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final pctA = _pct(widget.productA.perPortionMg);
    final pctB = _pct(widget.productB.perPortionMg);
    final isAWinner = _aLebihRendah;

    final totalKemasanA =
        widget.productA.perPortionMg * widget.productA.portionsInPackage;
    final totalKemasanB =
        widget.productB.perPortionMg * widget.productB.portionsInPackage;

    return PopScope(
      canPop: !_adaPerubahanBelumDisimpan,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldSave = await showDialog<bool>(
          context: context,
          barrierColor: Colors.black.withOpacity(0.5),
          builder: (ctx) => const UnsavedChangesDialog(),
        );
        if (shouldSave == null) return;
        if (shouldSave) {
          await _handleCatatKonsumsi();
        } else {
          if (mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── HEADER ───────────────────────────────────────────────────
                _buildHeader(),

                const SizedBox(height: 12),

                // ── BADGE WINNER + TAGLINE ────────────────────────────────────
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
                            TextSpan(
                              text: '${_selisihPersen()}%',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: _colorSafe,
                                fontSize: 16,
                              ),
                            ),
                            const TextSpan(text: ' lebih rendah natrium\n'),
                            TextSpan(
                              text: _winner.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const TextSpan(text: ' dibanding '),
                            TextSpan(
                              text: _loser.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── KARTU PILIHAN ─────────────────────────────────────────────
                if (!widget.readOnly) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kamu pilih yang mana?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _blue,
                          ),
                        ),
                        const SizedBox(height: 12),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _buildChoiceCard(
                                  product: widget.productA,
                                  isWinner: isAWinner,
                                  isSelected: _selectedProduct == 1,
                                  onTap: () => setState(() {
                                    _selectedProduct = 1;
                                    _tabController.animateTo(0);
                                  }),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildChoiceCard(
                                  product: widget.productB,
                                  isWinner: !isAWinner,
                                  isSelected: _selectedProduct == 2,
                                  onTap: () => setState(() {
                                    _selectedProduct = 2;
                                    _tabController.animateTo(1);
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── KONTRIBUSI HARIAN ─────────────────────────────────────────
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kontribusi Harian',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _blue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildKontribusiCard(
                        product: widget.productA,
                        pct: pctA,
                        isLower: totalKemasanA <= totalKemasanB,
                      ),
                      const SizedBox(height: 10),
                      _buildKontribusiCard(
                        product: widget.productB,
                        pct: pctB,
                        isLower: totalKemasanB < totalKemasanA,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── DETAIL PRODUK (TAB) ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detail Produk',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _blue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTabToggle(),
                      const SizedBox(height: 12),
                      AnimatedBuilder(
                        animation: _tabController,
                        builder: (_, __) {
                          final idx = _tabController.index;
                          return idx == 0
                              ? _buildDetailTab(widget.productA)
                              : _buildDetailTab(widget.productB);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── CTA ───────────────────────────────────────────────────────
                if (!widget.readOnly) ...[
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
                            : _handleCatatKonsumsi,
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
                                _selectedProduct == 0
                                    ? 'Pilih salah satu produk'
                                    : (_statusDikonsumsi
                                          ? 'Perbarui Konsumsi'
                                          : 'Catat Konsumsi'),
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
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ScanScreen(
                              apiClient: widget.apiClient,
                              compareWithProduct:
                                  widget.originalProduct ?? widget.productA,
                            ),
                          ),
                        ),
                        child: Text(
                          'Pilih Produk Lain',
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
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header gradient ───────────────────────────────────────────────────────
  Widget _buildHeader() {
    final screenSize = MediaQuery.sizeOf(context);
    final circleSize = (screenSize.shortestSide * 0.56)
        .clamp(176.0, 220.0)
        .toDouble();
    final middleCircleSize = circleSize * 0.84;
    final innerCircleSize = circleSize * 0.68;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF3C9040),
            Color(0xFF43A047),
            Color(0xFFC5E2C6),
            Color(0xFFE8F8EA),
            Colors.white,
          ],
          stops: [0.0, 0.45, 0.65, 0.82, 0.95],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () async {
                      if (_adaPerubahanBelumDisimpan) {
                        final shouldSave = await showDialog<bool>(
                          context: context,
                          barrierColor: Colors.black.withOpacity(0.5),
                          builder: (ctx) => const UnsavedChangesDialog(),
                        );
                        if (shouldSave == null) return;
                        if (shouldSave) {
                          await _handleCatatKonsumsi();
                          return;
                        }
                      }
                      if (mounted) Navigator.pop(context);
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
                  Text(
                    'Pilihan Rendah Natrium',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
              const SizedBox(height: 24),

              // Circle visual — winner produk
              SizedBox(
                width: circleSize,
                height: circleSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.20),
                      ),
                    ),
                    Container(
                      width: middleCircleSize,
                      height: middleCircleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.25),
                      ),
                    ),
                    Container(
                      width: innerCircleSize,
                      height: innerCircleSize,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF2E9E3E),
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
                        SizedBox(
                          width: innerCircleSize * 0.65, // ← batasi lebar teks
                          child: Text(
                            _winner.productName,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_winner.perPortionMg} mg',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Total Natrium',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
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
    );
  }

  // ── Choice card ───────────────────────────────────────────────────────────
  Widget _buildChoiceCard({
    required ProductCompareData product,
    required bool isWinner,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final borderColor = isSelected
        ? (isWinner ? const Color(0xFF43A047) : const Color(0xFFE53935))
        : (isWinner ? const Color(0xFFE3F1E3) : const Color(0xFFFBE1E1));
    final bgColor = isWinner
        ? const Color(0xFFE3F1E3)
        : const Color(0xFFFBE1E1);
    final textColor = isWinner
        ? const Color(0xFF2E7D32)
        : const Color(0xFFE53935);
    final natriumColor = isWinner
        ? const Color(0xFF327835)
        : const Color(0xFFAC2B28);
    final String svgAsset = isWinner
        ? 'assets/icons/material-symbols_readiness-score-outline-kiri.svg'
        : 'assets/icons/material-symbols_readiness-score-outline-kanan.svg';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isWinner
                        ? const Color(0xFF43A047)
                        : const Color(0xFFE53935),
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    svgAsset,
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              product.productName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isWinner ? 'Lebih rendah natrium' : 'Natrium lebih tinggi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: textColor.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${product.perPortionMg} mg',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: natriumColor,
              ),
            ),
            Text(
              'Per Sajian',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: natriumColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Kontribusi card ───────────────────────────────────────────────────────
  Widget _buildKontribusiCard({
    required ProductCompareData product,
    required double pct,
    required bool isLower,
  }) {
    final barColor = _barColor(pct);
    final pctInt = (pct * 100).round();
    final totalPerKemasan = product.perPortionMg * product.portionsInPackage;
    final pctKemasan = (totalPerKemasan / widget.dailyLimitMg * 100).round();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          Text(
            product.productName,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _blue,
            ),
          ),
          const SizedBox(height: 4),
          // ← tambah info per sajian
          Text(
            'Per sajian: ${product.perPortionMg} mg (1 dari ${product.portionsInPackage} sajian per kemasan)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: _blue.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _blue),
              children: [
                const TextSpan(text: 'Sekitar '),
                TextSpan(
                  text: '$pctInt%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _blue,
                  ),
                ),
                TextSpan(text: ' dari $_limitPhrase'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _CompareProgressBar(
            progress: pct.clamp(0.0, 1.0),
            barColor: barColor,
          ),
          // ← tambah info per kemasan penuh
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isLower
                  ? const Color(0xFFE3F1E3)
                  : const Color(0xFFFBE1E1), // ← warna bg
              borderRadius: BorderRadius.circular(8),
            ),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: isLower
                      ? const Color(0xFF43A047)
                      : const Color(0xFFE53935), // ← warna font
                ),
                children: [
                  const TextSpan(text: 'Jika 1 kemasan penuh: '),
                  TextSpan(
                    text: '$totalPerKemasan mg',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isLower
                          ? const Color(0xFF43A047)
                          : const Color(0xFFE53935),
                    ),
                  ),
                  TextSpan(text: ' ($pctKemasan% $_limitPhrase)'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab toggle ────────────────────────────────────────────────────────────
  Widget _buildTabToggle() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (_, __) {
        final idx = _tabController.index;
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _tabBtn('Produk pertama', 0, idx == 0),
              _tabBtn('Produk kedua', 1, idx == 1),
            ],
          ),
        );
      },
    );
  }

  Widget _tabBtn(String label, int idx, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(idx);
          setState(() {
            _selectedProduct = idx + 1; // tab 0 → produk 1, tab 1 → produk 2
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? _navy : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : const Color(0xFFAAAAAA),
            ),
          ),
        ),
      ),
    );
  }

  // ── Detail tab ────────────────────────────────────────────────────────────
  Widget _buildDetailTab(ProductCompareData p) {
    final portionSatuan = (p.packageMl / p.portionsInPackage).round();
    return Column(
      children: [
        _infoCard('Nama Produk', p.productName),
        const SizedBox(height: 8),
        _infoCard(
          'Isi Kemasan',
          '${p.packageMl} ${p.satuanTakaran} (${p.portionsInPackage} sajian)',
        ),
        const SizedBox(height: 8),
        _infoCard('Kategori', kategoriLabel(p.kategori)),

        const SizedBox(height: 8),
        _infoCard('Takaran per Sajian', '$portionSatuan ${p.satuanTakaran}'),
        const SizedBox(height: 8),
        _infoCard('Natrium per Sajian', '${p.perPortionMg} mg per sajian'),
      ],
    );
  }

  Widget _infoCard(String label, String value) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: _bgCard,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: _navy.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 3),
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

  // ── Catat konsumsi ────────────────────────────────────────────────────────
  Future<void> _handleCatatKonsumsi() async {
    if (widget.readOnly) return;

    final selectedData = _selectedProduct == 1
        ? widget.productA
        : widget.productB;
    final otherData = _selectedProduct == 1 ? widget.productB : widget.productA;

    final isUpdate = widget.fromHistory;

    final akanDikonsumsi = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => YakinMakanDialog(isUpdate: _statusDikonsumsi),
    );
    if (akanDikonsumsi == null) return;

    final client = widget.apiClient ?? ApiClient();
    final activeUserId = UserSession().getUserId();

    if (akanDikonsumsi) {
      int consumedToday = 0;
      try {
        final stats = await client.getDashboardStats(activeUserId);
        consumedToday =
            (stats['total_sodium_consumed_today'] as num?)?.round() ?? 0;
      } catch (e) {
        debugPrint('Gagal ambil consumedToday: $e');
      }

      final produkLama = _selectedProductSaatDicatat == 1
          ? widget.productA
          : (_selectedProductSaatDicatat == 2 ? widget.productB : null);
      final totalNatriumLama = (isUpdate && produkLama != null)
          ? produkLama.perPortionMg
          : 0;
      final totalNatrium = selectedData.perPortionMg;
      final totalSetelahCatat = consumedToday - totalNatriumLama + totalNatrium;

      if (totalSetelahCatat > widget.dailyLimitMg) {
        // ← GANTI INI
        final confirm = await showDialog<bool>(
          context: context,
          barrierColor: Colors.black.withOpacity(0.5),
          builder: (ctx) => StopNatriumDialog(limitPhrase: _limitPhrase),
        );
        if (confirm != true) return;
      }
    }

    setState(() => _saving = true);

    try {
      if (activeUserId == 0) return;

      if (isUpdate) {
        final intakeId = int.tryParse(widget.historyItemId ?? '');
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
          isConsumed: akanDikonsumsi,
          servings: 1,
          productName: selectedData.productName,
          sodiumMg: selectedData.perPortionMg,
          productName2: otherData.productName,
          sodiumMg2: otherData.perPortionMg,
          imagePath: selectedData.imagePath,
          imagePath2: otherData.imagePath,
        );
      } else {
        await client.postScanHistory(
          userId: activeUserId,
          sodiumMg: selectedData.perPortionMg,
          servings: 1,
          productName: selectedData.productName,
          sodiumLevel: widget.sodiumLevel,
          kategori: selectedData.kategori,
          type: 'comparison',
          productName2: otherData.productName,
          sodiumMg2: otherData.perPortionMg,
          isConsumed: akanDikonsumsi,
          packageMl: selectedData.packageMl,
          portionsInPackage: selectedData.portionsInPackage,
          satuanTakaran: selectedData.satuanTakaran,
          packageMl2: otherData.packageMl,
          portionsInPackage2: otherData.portionsInPackage,
          satuanTakaran2: otherData.satuanTakaran,
          imagePath: selectedData.imagePath,
          imagePath2: otherData.imagePath,
        );
      }

      if (!mounted) return;
      setState(() {
        _statusDikonsumsi = akanDikonsumsi;
        _selectedProductSaatDicatat = _selectedProduct; // ← tambahkan ini
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            akanDikonsumsi
                ? 'Konsumsi ${selectedData.productName} berhasil dicatat ✓'
                : '${selectedData.productName} dicatat sebagai tidak dikonsumsi',
          ),
          backgroundColor: akanDikonsumsi
              ? const Color(0xFF43A047)
              : const Color(0xFFE53935),
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

}

// ════════════════════════════════════════════════════════════════════════════
// Progress Bar untuk perbandingan
// ════════════════════════════════════════════════════════════════════════════
class _CompareProgressBar extends StatelessWidget {
  const _CompareProgressBar({required this.progress, required this.barColor});

  final double progress;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    const barHeight = 10.0;
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
