import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/api_client.dart';
import 'scan_screen.dart';
import 'hasil_perbandingan_produk.dart';
import 'hasil_scan_aman_screen.dart';
import '../screens/profile_wizard/profile_wizard_store.dart';
import '../widgets/custom_dropdown.dart';
import '../../domain/kategori_label.dart';
import '../../domain/natrium_classifier.dart';
import '../../../data/user_session.dart';

class ScanHistoryItem {
  final String id;
  final String productName;
  final int sodiumMg;
  final double servings;
  final DateTime timestamp;
  final String? imagePath;
  final String type;
  bool isConsumed;
  final String kategori;
  final String? productName2;
  final int? sodiumMg2;
  final String? imagePath2;
  final int packageMl;
  final int portionsInPackage;
  final String satuanTakaran;
  final int packageMl2;
  final int portionsInPackage2;
  final String satuanTakaran2;
  final Map<String, dynamic>? rekomendasiJson;

  ScanHistoryItem({
    required this.id,
    required this.productName,
    required this.sodiumMg,
    required this.servings,
    required this.timestamp,
    this.imagePath,
    this.type = 'single',
    this.isConsumed = false,
    this.kategori = 'lainnya',
    this.productName2,
    this.sodiumMg2,
    this.imagePath2,
    this.packageMl = 0,
    this.portionsInPackage = 1,
    this.satuanTakaran = 'g',
    this.packageMl2 = 0,
    this.portionsInPackage2 = 1,
    this.satuanTakaran2 = 'g',
    this.rekomendasiJson,
  });

  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) {
    return ScanHistoryItem(
      id:
          json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      productName:
          json['food_name'] as String? ??
          json['product_name'] as String? ??
          'Produk',
      sodiumMg: (json['sodium_mg'] as num?)?.toInt() ?? 0,
      servings: (json['servings'] as num?)?.toDouble() ?? 1.0,
      timestamp:
          DateTime.tryParse(json['consumed_at'] as String? ?? '') ??
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      imagePath: json['image_path'] as String?,
      type: json['type'] as String? ?? 'single',
      isConsumed: json['is_consumed'] == true || json['is_consumed'] == 1,
      kategori: json['kategori'] as String? ?? 'lainnya',
      productName2: json['product_name2'] as String?,
      sodiumMg2: (json['sodium_mg2'] as num?)?.toInt(),
      imagePath2: json['image_path2'] as String?,
      packageMl: (json['package_ml'] as num?)?.toInt() ?? 0,
      portionsInPackage: (json['portions_in_package'] as num?)?.toInt() ?? 1,
      satuanTakaran: json['satuan_takaran'] as String? ?? 'g',
      packageMl2: (json['package_ml2'] as num?)?.toInt() ?? 0,
      portionsInPackage2: (json['portions_in_package2'] as num?)?.toInt() ?? 1,
      satuanTakaran2: json['satuan_takaran2'] as String? ?? 'g',
      rekomendasiJson: json['rekomendasi_json'] != null
          ? Map<String, dynamic>.from(
              jsonDecode(json['rekomendasi_json'] as String) as Map,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_name': productName,
    'sodium_mg': sodiumMg,
    'servings': servings,
    'timestamp': timestamp.toIso8601String(),
    'image_path': imagePath,
    'type': type,
    'is_consumed': isConsumed,
    'kategori': kategori,
    'product_name2': productName2,
    'sodium_mg2': sodiumMg2,
    'image_path2': imagePath2,
    'package_ml': packageMl,
    'portions_in_package': portionsInPackage,
    'satuan_takaran': satuanTakaran,
    'package_ml2': packageMl2,
    'portions_in_package2': portionsInPackage2,
    'satuan_takaran2': satuanTakaran2,
    'rekomendasi_json': rekomendasiJson != null
        ? jsonEncode(rekomendasiJson)
        : null,
  };
}

bool isEditableHistoryRecord(ScanHistoryItem item, {DateTime? now}) {
  final recordDate = item.timestamp.toLocal();
  final currentDate = (now ?? DateTime.now()).toLocal();
  return recordDate.year == currentDate.year &&
      recordDate.month == currentDate.month &&
      recordDate.day == currentDate.day;
}

// ─────────────────────────────────────────────
// HELPER — natrium harian
// ─────────────────────────────────────────────

class DailyNatriumHelper {
  static const _key = 'daily_sodium';

  static String _dayKey() {
    final now = DateTime.now();
    final userId = UserSession().getUserId() ?? 'guest';
    return '${_key}_${userId}_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static Future<void> addMg(int mg) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _dayKey();
    await prefs.setInt(key, (prefs.getInt(key) ?? 0) + mg);
  }

  static Future<void> removeMg(int mg) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _dayKey();
    await prefs.setInt(key, ((prefs.getInt(key) ?? 0) - mg).clamp(0, 999999));
  }

  static Future<int> getTodayMg() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dayKey()) ?? 0;
  }
}

// ─────────────────────────────────────────────
// HELPER — simpan/load history
// ─────────────────────────────────────────────

class ScanHistoryHelper {
  static const _key = 'scan_history';
  static String _userKey() {
    final userId = UserSession().getUserId() ?? 'guest';
    return '${_key}_$userId';
  }

  static Future<List<ScanHistoryItem>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_userKey()) ?? [];
    return raw
        .map((e) => ScanHistoryItem.fromJson(jsonDecode(e)))
        .toList()
        .reversed
        .toList();
  }

  static Future<void> saveAll(List<ScanHistoryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _userKey(),
      items.reversed.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  static Future<void> addItem(ScanHistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_userKey()) ?? [];
    raw.add(jsonEncode(item.toJson()));
    await prefs.setStringList(_userKey(), raw);
    if (item.isConsumed) {
      await DailyNatriumHelper.addMg((item.sodiumMg * item.servings).round());
    }
  }

  static Future<void> updateItem(ScanHistoryItem updated) async {
    final all = await loadAll();
    final idx = all.indexWhere((e) => e.id == updated.id);
    if (idx != -1) all[idx] = updated;
    await saveAll(all);
  }
}

// ─────────────────────────────────────────────
// ENUM
// ─────────────────────────────────────────────

enum HistoryRange { day, week, month }

enum ScanTypeFilter { all, single, comparison, bumbu }

// ─────────────────────────────────────────────
// STICKY DELEGATE — Jenis scan tetap kelihatan
// ─────────────────────────────────────────────

class _StickyTypeFilterDelegate extends SliverPersistentHeaderDelegate {
  const _StickyTypeFilterDelegate({required this.child, required this.height});
  final Widget child;
  final double height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_StickyTypeFilterDelegate oldDelegate) =>
      oldDelegate.child != child || oldDelegate.height != height;
}

// ─────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.apiClient});
  final ApiClient apiClient;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const _white = Color(0xFFFFFFFF);
  static const _blue = Color(0xFF2C4A8A);
  static const _blueSoft = Color(0xFFDFE4ED);
  static const _blueGray = Color(0xFFBEC7DB);
  static const _gray = Color(0xFFD9D9D9);

  bool _loading = false;
  List<ScanHistoryItem> _items = [];
  HistoryRange _range = HistoryRange.month;
  ScanTypeFilter _typeFilter = ScanTypeFilter.all;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final userId = UserSession().getUserId();
      if (userId == 0) {
        if (mounted) setState(() => _items = []);
        return;
      }

      final raw = await widget.apiClient.getIntakeHistory(userId);

      debugPrint('=== RAW HISTORY: ${raw.first}');
      debugPrint('=== REKO JSON: ${(raw.first as Map)['rekomendasi_json']}');

      final now = DateTime.now();
      final allItems = raw
          .map(
            (e) =>
                ScanHistoryItem.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();

      final filtered = allItems.where((item) {
        final ts = item.timestamp.toLocal();
        final inRange = switch (_range) {
          HistoryRange.day =>
            ts.year == now.year && ts.month == now.month && ts.day == now.day,
          HistoryRange.week => now.difference(ts).inDays <= 7,
          HistoryRange.month => now.difference(ts).inDays <= 30,
        };
        if (!inRange) return false;
        return switch (_typeFilter) {
          ScanTypeFilter.all => true,
          ScanTypeFilter.single => item.type == 'single',
          ScanTypeFilter.comparison => item.type == 'comparison',
          ScanTypeFilter.bumbu => item.type == 'bumbu',
        };
      }).toList();

      if (mounted) setState(() => _items = filtered);
    } catch (e) {
      debugPrint('History load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatTime(DateTime ts) {
    final local = ts.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    return '${local.day}/${local.month}/${local.year}';
  }

  static TextStyle _ts(double size, FontWeight weight, Color color) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
      );

  // ─── BUILD UTAMA — pakai CustomScrollView ────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Ambil tinggi status bar agar header tidak tertutup
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      color: _white,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: topPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 26),
                  _buildWaktuDropdown(),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTypeFilterDelegate(
              height: 96,
              child: Container(
                color: _white,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                child: _buildTypeFilterChipsContent(),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
            sliver: _buildBodySliver(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Riwayat Scan',
              textAlign: TextAlign.center,
              style: _ts(22, FontWeight.w700, _blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaktuDropdown() {
    const rangeLabels = {
      HistoryRange.day: 'Hari ini',
      HistoryRange.week: 'Minggu ini',
      HistoryRange.month: 'Bulan ini',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Waktu', style: _ts(16, FontWeight.w600, _blue)),
          const SizedBox(height: 8),
          SizedBox(
            width: 125,
            child: CustomDropdownField(
              value: rangeLabels[_range],
              placeholder: 'Pilih waktu',
              height: 40,
              fontSize: 13,
              textAlign: TextAlign.left,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              onTap: () async {
                final selected = await showCustomDropdown<HistoryRange>(
                  context: context,
                  title: 'Pilih Rentang Waktu',
                  items: HistoryRange.values
                      .map(
                        (range) => DropdownItem(
                          value: range,
                          label: rangeLabels[range]!,
                        ),
                      )
                      .toList(),
                  selectedValue: _range,
                );
                if (selected == null) return;
                setState(() => _range = selected);
                _loadHistory();
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── chips tanpa Padding luar, untuk ditaruh di sticky header ─────────────
  Widget _buildTypeFilterChipsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Jenis scan', style: _ts(16, FontWeight.w600, _blue)),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _TypeChip(
                label: 'Semua',
                iconAsset: 'assets/icons/mingcute_grid-fil.svg',
                fallbackIcon: Icons.apps_rounded,
                isActive: _typeFilter == ScanTypeFilter.all,
                onTap: () {
                  setState(() => _typeFilter = ScanTypeFilter.all);
                  _loadHistory();
                },
              ),
              const SizedBox(width: 10),
              _TypeChip(
                label: 'Single Produk',
                iconAsset: 'assets/icons/scan.svg',
                fallbackIcon: Icons.qr_code_scanner_rounded,
                isActive: _typeFilter == ScanTypeFilter.single,
                onTap: () {
                  setState(() => _typeFilter = ScanTypeFilter.single);
                  _loadHistory();
                },
              ),
              const SizedBox(width: 10),
              _TypeChip(
                label: 'Perbandingan Produk',
                iconAsset: 'assets/icons/repeat-circle.svg',
                fallbackIcon: Icons.compare_arrows_rounded,
                isActive: _typeFilter == ScanTypeFilter.comparison,
                onTap: () {
                  setState(() => _typeFilter = ScanTypeFilter.comparison);
                  _loadHistory();
                },
              ),
              const SizedBox(width: 10),
              _TypeChip(
                label: 'Saus & Bumbu',
                iconAsset:
                    'assets/icons/streamline-ultimate_seasoning-food.svg',
                fallbackIcon: Icons.restaurant_menu_rounded,
                isActive: _typeFilter == ScanTypeFilter.bumbu,
                onTap: () {
                  setState(() => _typeFilter = ScanTypeFilter.bumbu);
                  _loadHistory();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── body sebagai Sliver ───────────────────────────────────────────────────
  Widget _buildBodySliver() {
    if (_loading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: _blue)),
      );
    }

    if (_items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(),
      );
    }

    final singles = _items.where((e) => e.type == 'single').toList();
    final comparisons = _items.where((e) => e.type == 'comparison').toList();
    final bumbus = _items.where((e) => e.type == 'bumbu').toList();

    final List<Widget> cards = [];

    if ((_typeFilter == ScanTypeFilter.all ||
            _typeFilter == ScanTypeFilter.single) &&
        singles.isNotEmpty) {
      cards.add(_sectionLabel('Single Produk'));
      cards.add(const SizedBox(height: 10));
      for (final item in singles) {
        cards.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _SingleItemCard(
              item: item,
              apiClient: widget.apiClient,
              timeLabel: _formatTime(item.timestamp),
              onDetail: () => _openDetail(item),
            ),
          ),
        );
      }
    }

    if ((_typeFilter == ScanTypeFilter.all ||
            _typeFilter == ScanTypeFilter.comparison) &&
        comparisons.isNotEmpty) {
      cards.add(const SizedBox(height: 6));
      cards.add(_sectionLabel('Perbandingan Produk'));
      cards.add(const SizedBox(height: 10));
      for (final item in comparisons) {
        cards.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _ComparisonItemCard(
              item: item,
              apiClient: widget.apiClient,
              timeLabel: _formatTime(item.timestamp),
              onDetail: () => _openDetail(item),
            ),
          ),
        );
      }
    }

    if ((_typeFilter == ScanTypeFilter.all ||
            _typeFilter == ScanTypeFilter.bumbu) &&
        bumbus.isNotEmpty) {
      cards.add(const SizedBox(height: 6));
      cards.add(_sectionLabel('Saus & Bumbu'));
      cards.add(const SizedBox(height: 10));
      for (final item in bumbus) {
        cards.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _BumbuItemCard(
              item: item,
              apiClient: widget.apiClient,
              timeLabel: _formatTime(item.timestamp),
              onDetail: () => _openDetail(item),
            ),
          ),
        );
      }
    }

    return SliverList(delegate: SliverChildListDelegate(cards));
  }

  Widget _buildEmptyState() {
    final emptyImageSize = (MediaQuery.sizeOf(context).height * 0.28)
        .clamp(180.0, 240.0)
        .toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 160),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/illustrations/belum_ada_history.png',
            width: emptyImageSize,
            height: emptyImageSize,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 8),
          Center(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: _blue,
                ),
                children: [
                  const TextSpan(text: 'Yuk, '),
                  TextSpan(
                    text: 'scan kemasan produk ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _blue,
                    ),
                  ),
                  const TextSpan(text: 'untuk mulai\n'),
                  TextSpan(
                    text: 'menyimpan riwayatmu ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _blue,
                    ),
                  ),
                  const TextSpan(text: 'sekarang!'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) =>
      Text(text, style: _ts(16, FontWeight.w700, _blue));

  void _openDetail(ScanHistoryItem item) async {
    debugPrint('=== OPEN DETAIL: id=${item.id}, reko=${item.rekomendasiJson}');
    final isEditable = isEditableHistoryRecord(item);
    int dailyLimit = 2000;
    bool isHardMaximum = true;
    try {
      final userId = UserSession().getUserId();
      if (userId > 0) {
        final profile = await widget.apiClient.getUserProfile(userId);
        final birthDateStr = profile['birth_date'] as String?;
        if (birthDateStr != null) {
          final hasil = await klasifikasiNatriumDariDraft(
            birthDate: DateTime.parse(birthDateStr),
            gender: profile['gender'] as String? ?? '',
            hasHypertension: profile['has_hypertension'] as bool? ?? false,
            hypertensionCondition: profile['hypertension_condition'] as String?,
            systolicPressure: profile['systolic_pressure'] as int?,
            diastolicPressure: profile['diastolic_pressure'] as int?,
            pregnancyStatus: profile['pregnancy_status'] as String?,
          );
          dailyLimit = hasil.batasNatrium;
          isHardMaximum = hasil.isHardMaximum;
        }
      }
    } catch (e) {
      debugPrint('Gagal fetch daily limit: $e');
    }

    if (item.type == 'comparison') {
      final produkA = ProductCompareData(
        productName: item.productName,
        kategori: item.kategori,
        satuanTakaran: item.satuanTakaran,
        perPortionMg: item.sodiumMg,
        packageMl: item.packageMl,
        portionsInPackage: item.portionsInPackage,
        imagePath: item.imagePath,
      );

      final produkB = ProductCompareData(
        productName: item.productName2 ?? '-',
        kategori: item.kategori,
        satuanTakaran: item.satuanTakaran2,
        perPortionMg: item.sodiumMg2 ?? 0,
        packageMl: item.packageMl2,
        portionsInPackage: item.portionsInPackage2,
        imagePath: item.imagePath2,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HasilBandingkanScreen(
            productA: produkA,
            productB: produkB,
            dailyLimitMg: dailyLimit,
            isHardMaximum: isHardMaximum,
            apiClient: widget.apiClient,
            readOnly: !isEditable,
            fromHistory: true,
            historyItemId: item.id,
            isConsumed: item.isConsumed,
            selectedProductName: item.productName,
          ),
        ),
      ).then((_) => _loadHistory());
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HasilScanAmanScreen(
          productName: item.productName,
          kategori: item.kategori,
          perPortionMg: item.sodiumMg,
          initialServings: item.servings.toInt(),
          fromHistory: true,
          historyItemId: item.id,
          imagePath: item.imagePath,
          isConsumed: item.isConsumed,
          dailyLimitMg: dailyLimit,
          isHardMaximum: isHardMaximum,
          apiClient: widget.apiClient,
          readOnly: !isEditable,
          rekomendasiJson: item.rekomendasiJson,
          packageMl: item.packageMl,
          portionsInPackage: item.portionsInPackage,
          satuanTakaran: item.satuanTakaran,
          scanDate: item.timestamp,
        ),
      ),
    ).then((_) => _loadHistory());
  }
}

// ─────────────────────────────────────────────
// CARD — Single Item
// ─────────────────────────────────────────────

class _SingleItemCard extends StatelessWidget {
  const _SingleItemCard({
    required this.item,
    required this.apiClient,
    required this.timeLabel,
    required this.onDetail,
  });

  final ScanHistoryItem item;
  final ApiClient apiClient;
  final String timeLabel;
  final VoidCallback onDetail;

  static const _white = Color(0xFFFFFFFF);
  static const _blue = Color(0xFF2C4A8A);
  static const _navy = Color(0xFF213868);
  static const _blueSoft = Color(0xFFDFE4ED);
  static const _gray = Color(0xFFD9D9D9);

  static TextStyle _ts(double size, FontWeight w, Color c) =>
      GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: w, color: c);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Text(
              item.productName,
              style: _ts(17, FontWeight.w700, _navy),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _ProductImage(
                    path: item.imagePath,
                    size: 64,
                    apiClient: apiClient,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _blueSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${(item.sodiumMg * item.servings).round()} mg natrium',
                          style: _ts(13, FontWeight.w600, _blue),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _HistoryMetadataChips(
                        servingLabel:
                            '${item.servings % 1 == 0 ? item.servings.toInt() : item.servings} Porsi',
                        timeLabel: timeLabel,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: _gray),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(
              children: [
                _StatusBadge(consumed: item.isConsumed),
                const Spacer(),
                GestureDetector(
                  onTap: onDetail,
                  child: Text(
                    'Lihat Detail',
                    style: _ts(12, FontWeight.w500, _blue),
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

// ─────────────────────────────────────────────
// CARD — Comparison Item
// ─────────────────────────────────────────────

class _BumbuItemCard extends StatelessWidget {
  const _BumbuItemCard({
    required this.item,
    required this.apiClient,
    required this.timeLabel,
    required this.onDetail,
  });

  final ScanHistoryItem item;
  final ApiClient apiClient;
  final String timeLabel;
  final VoidCallback onDetail;

  static const _white = Color(0xFFFFFFFF);
  static const _blue = Color(0xFF2C4A8A);
  static const _navy = Color(0xFF213868);
  static const _blueSoft = Color(0xFFDFE4ED);
  static const _gray = Color(0xFFD9D9D9);

  static TextStyle _ts(double size, FontWeight w, Color c) =>
      GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: w, color: c);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Text(
              item.productName,
              style: _ts(17, FontWeight.w700, _navy),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _ProductImage(
                    path: item.imagePath,
                    size: 64,
                    apiClient: apiClient,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _blueSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${item.sodiumMg} mg natrium/sajian',
                          style: _ts(13, FontWeight.w600, _blue),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // _IconChip(
                          //   fallbackIcon: Icons.category_rounded,
                          //   label: kategoriLabel(item.kategori),
                          // ),
                          _IconChip(
                            iconAsset: 'assets/icons/video-time.svg',
                            fallbackIcon: Icons.access_time_rounded,
                            label: timeLabel,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: _gray),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(
              children: [
                // Text(
                //   'Referensi produk',
                //   style: _ts(12, FontWeight.w500, _blue),
                // ),
                const Spacer(),
                GestureDetector(
                  onTap: onDetail,
                  child: Text(
                    'Lihat Detail',
                    style: _ts(12, FontWeight.w500, _blue),
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

class _ComparisonItemCard extends StatelessWidget {
  const _ComparisonItemCard({
    required this.item,
    required this.apiClient,
    required this.timeLabel,
    required this.onDetail,
  });

  final ScanHistoryItem item;
  final ApiClient apiClient;
  final String timeLabel;
  final VoidCallback onDetail;

  static const _white = Color(0xFFFFFFFF);
  static const _darkblue = Color(0xFF213868);
  static const _blue = Color(0xFF2C4A8A);
  static const _gray = Color(0xFFD9D9D9);

  static TextStyle _ts(double size, FontWeight w, Color c) =>
      GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: w, color: c);

  @override
  Widget build(BuildContext context) {
    final name2 = item.productName2 ?? '-';
    final sodium2 = item.sodiumMg2 ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                  child: _ProductImage(
                    path: item.imagePath,
                    size: 64,
                    apiClient: apiClient,
                  ),
                ),
                const SizedBox(width: 2),
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                  child: _ProductImage(
                    path: item.imagePath2,
                    size: 64,
                    apiClient: apiClient,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: _ts(15, FontWeight.w700, _darkblue),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.sodiumMg} mg Natrium',
                        style: _ts(13, FontWeight.w500, _blue),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        name2,
                        style: _ts(15, FontWeight.w700, _darkblue),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$sodium2 mg Natrium',
                        style: _ts(12, FontWeight.w500, _blue),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: _HistoryMetadataChips(
              servingLabel:
                  '${item.servings % 1 == 0 ? item.servings.toInt() : item.servings} Porsi',
              timeLabel: timeLabel,
            ),
          ),
          Divider(height: 1, color: _gray),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(
              children: [
                _StatusBadge(consumed: item.isConsumed),
                const Spacer(),
                GestureDetector(
                  onTap: onDetail,
                  child: Text(
                    'Lihat Detail',
                    style: _ts(12, FontWeight.w500, _blue),
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

// ─────────────────────────────────────────────
// WIDGET — _HistoryMetadataChips
// ─────────────────────────────────────────────

class _HistoryMetadataChips extends StatelessWidget {
  const _HistoryMetadataChips({
    required this.servingLabel,
    required this.timeLabel,
  });

  final String servingLabel;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: _IconChip(
            iconAsset: 'assets/icons/fluent_food-24-regular.svg',
            fallbackIcon: Icons.restaurant_menu_rounded,
            label: servingLabel,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          fit: FlexFit.loose,
          child: _IconChip(
            iconAsset: 'assets/icons/video-time.svg',
            fallbackIcon: Icons.access_time_rounded,
            label: timeLabel,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// WIDGET — _IconChip
// ─────────────────────────────────────────────

class _IconChip extends StatelessWidget {
  const _IconChip({required this.label, this.iconAsset, this.fallbackIcon});

  final String label;
  final String? iconAsset;
  final IconData? fallbackIcon;

  static const _blue = Color(0xFF2C4A8A);
  static const _blueSoft = Color(0xFFDFE4ED);
  static const _gray = Color(0xFFD9D9D9);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gray),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: _blueSoft,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: iconAsset != null
                  ? SvgPicture.asset(
                      iconAsset!,
                      width: 14,
                      height: 14,
                      colorFilter: const ColorFilter.mode(
                        _blue,
                        BlendMode.srcIn,
                      ),
                    )
                  : Icon(fallbackIcon, size: 14, color: _blue),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WIDGET — _StatusBadge
// ─────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.consumed});
  final bool consumed;

  static const _green = Color(0xFF43A047);
  static const _red = Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    final color = consumed ? _green : _red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            consumed
                ? Icons.check_circle_outline_rounded
                : Icons.cancel_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            consumed ? 'Dikonsumsi' : 'Tidak dikonsumsi',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WIDGET — _ProductImage
// ─────────────────────────────────────────────

class _ProductImage extends StatelessWidget {
  const _ProductImage({this.path, required this.size, required this.apiClient});
  final String? path;
  final double size;
  final ApiClient apiClient;

  static const _blueSoft = Color(0xFFDFE4ED);
  static const _blueGray = Color(0xFFBEC7DB);

  @override
  Widget build(BuildContext context) {
    if (path != null && path!.isNotEmpty) {
      final file = File(path!);
      if (file.existsSync()) {
        return Image.file(file, width: size, height: size, fit: BoxFit.cover);
      }

      final isServerPath =
          path!.startsWith('/uploads') || path!.startsWith('http');
      final imageFullUrl = isServerPath ? apiClient.imageUrl(path) : '';
      if (imageFullUrl.isNotEmpty) {
        return Image.network(
          imageFullUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      }
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      color: _blueSoft,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: _blueGray,
        size: 28,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WIDGET — _TypeChip
// ─────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.iconAsset,
    this.fallbackIcon,
  }) : assert(
         iconAsset != null || fallbackIcon != null,
         'Harus isi salah satu: iconAsset atau fallbackIcon',
       );

  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final String? iconAsset;
  final IconData? fallbackIcon;

  static const _white = Color(0xFFFFFFFF);
  static const _blue = Color(0xFF2C4A8A);
  static const _gray = Color(0xFFD9D9D9);

  @override
  Widget build(BuildContext context) {
    final iconColor = isActive ? Colors.white : _blue;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? _blue : _white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isActive ? _blue : _gray),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: _blue.withOpacity(0.20),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconAsset != null)
              Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withOpacity(0.20)
                      : const Color(0xFFDFE4ED),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    iconAsset!,
                    width: 18,
                    height: 18,
                    colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                  ),
                ),
              )
            else
              Icon(fallbackIcon, size: 15, color: iconColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
