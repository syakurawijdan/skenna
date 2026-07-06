import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/api_client.dart';
import '../../data/user_session.dart';
import '../../domain/natrium_classifier.dart';
import 'hasil_scan_aman_screen.dart';
import '../widgets/custom_dropdown.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

String _formatIndoNumber(num value) {
  final parsed = value.toDouble();
  if (parsed == parsed.roundToDouble()) return parsed.toInt().toString();
  return parsed
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '')
      .replaceAll('.', ',');
}

class ConsumedTodayItem {
  const ConsumedTodayItem({
    required this.id,
    required this.foodName,
    required this.sodiumMg,
    required this.servings,
    required this.consumedAt,
    required this.sodiumLevel,
    this.kategori,
    this.imagePath,
    this.packageMl = 0.0,
    this.portionsInPackage = 1.0,
    this.satuanTakaran = 'g',
    this.rekomendasiJson,
    this.isConsumed = true,
  });

  final int id;
  final String foodName;
  final double sodiumMg;
  final int servings;
  final DateTime consumedAt;
  final String sodiumLevel;
  final String? kategori;
  final String? imagePath;
  final double packageMl;
  final double portionsInPackage;
  final String satuanTakaran;
  final Map<String, dynamic>? rekomendasiJson;
  final bool isConsumed;

  factory ConsumedTodayItem.fromJson(Map<String, dynamic> json) {
    return ConsumedTodayItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      foodName: json['food_name']?.toString() ?? 'Produk',
      sodiumMg: (json['sodium_mg'] as num?)?.toDouble() ?? 0,
      servings: (json['servings'] as num?)?.toInt() ?? 1,
      consumedAt:
          DateTime.tryParse(json['consumed_at']?.toString() ?? '') ??
          DateTime.now(),
      sodiumLevel: json['sodium_level']?.toString() ?? 'low',
      kategori: json['kategori']?.toString(),
      imagePath: json['image_path']?.toString(),
      packageMl: (json['package_ml'] as num?)?.toDouble() ?? 0.0,
      portionsInPackage:
          (json['portions_in_package'] as num?)?.toDouble() ?? 1.0,
      satuanTakaran: json['satuan_takaran']?.toString() ?? 'g',
      rekomendasiJson: json['rekomendasi_json'] != null
          ? Map<String, dynamic>.from(
              jsonDecode(json['rekomendasi_json'] as String) as Map,
            )
          : null,
      isConsumed: json['is_consumed'] == true || json['is_consumed'] == 1,
    );
  }
}

class ConsumedTodayScreen extends StatefulWidget {
  const ConsumedTodayScreen({super.key, this.apiClient});

  final ApiClient? apiClient;

  @override
  State<ConsumedTodayScreen> createState() => _ConsumedTodayScreenState();
}

class _ConsumedTodayScreenState extends State<ConsumedTodayScreen> {
  static const _white = Color(0xFFFFFFFF);
  static const _blue = Color(0xFF2C4A8A);
  static const _navy = Color(0xFF213868);
  static const _blueSoft = Color(0xFFDFE4ED);
  static const _gray = Color(0xFFD9D9D9);
  static const _danger = Color(0xFFE53935);

  static const List<DropdownItem<String>> _categories = [
    DropdownItem(value: 'mie_instan', label: 'Mie & Pasta Instan'),
    DropdownItem(value: 'keripik_snack', label: 'Snack & Keripik'),
    DropdownItem(value: 'makanan_kaleng', label: 'Makanan Kaleng'),
    DropdownItem(value: 'biskuit_roti', label: 'Roti'),
    DropdownItem(value: 'frozen_food', label: 'Frozen Food'),
    DropdownItem(value: 'sereal', label: 'Sereal & Oatmeal'),
    DropdownItem(value: 'biskuit', label: 'Biskuit & Wafer'),
    DropdownItem(value: 'susu', label: 'Susu & Produk Susu'),
    DropdownItem(value: 'minuman_kemasan', label: 'Minuman Kemasan'),
    DropdownItem(value: 'lainnya', label: 'Lainnya'),
  ];

  static const List<DropdownItem<String>> _levels = [
    DropdownItem(value: 'low', label: 'Low'),
    DropdownItem(value: 'medium', label: 'Medium'),
    DropdownItem(value: 'high', label: 'High'),
  ];

  late final ApiClient _apiClient;
  bool _loading = true;
  List<ConsumedTodayItem> _items = [];

  static TextStyle _ts(double size, FontWeight weight, Color color) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient ?? ApiClient();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    try {
      final userId = UserSession().getUserId();
      if (userId <= 0) {
        setState(() {
          _items = [];
          _loading = false;
        });
        return;
      }
      final raw = await _apiClient.getConsumedToday(userId);
      if (!mounted) return;
      setState(() {
        _items = raw
            .whereType<Map>()
            .map(
              (item) =>
                  ConsumedTodayItem.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnack('Gagal memuat produk: $e');
    }
  }

  Future<void> _openDetail(ConsumedTodayItem item) async {
    int dailyLimit = 2000;
    bool isHardMaximum = true;
    try {
      final userId = UserSession().getUserId();
      if (userId > 0) {
        final profile = await _apiClient.getUserProfile(userId);
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

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HasilScanAmanScreen(
          productName: item.foodName,
          kategori: item.kategori ?? 'lainnya',
          perPortionMg: item.sodiumMg.round(),
          initialServings: item.servings.toDouble(),
          fromHistory: true,
          historyItemId: item.id.toString(),
          imagePath: item.imagePath,
          isConsumed: true,
          dailyLimitMg: dailyLimit,
          isHardMaximum: isHardMaximum,
          apiClient: _apiClient,
          readOnly: false,
          isFromHistory: true,
          packageMl: item.packageMl,
          portionsInPackage: item.portionsInPackage,
          satuanTakaran: item.satuanTakaran,
          rekomendasiJson: item.rekomendasiJson,
        ),
      ),
    );
    await _loadItems();
  }

  Future<void> _openEdit(ConsumedTodayItem item) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _EditInfoProductSheet(
        item: item,
        apiClient: _apiClient,
        onSaved: _loadItems,
      ),
    );
    if (saved == true) await _loadItems();
  }

  Future<void> _confirmDelete(ConsumedTodayItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => _DeleteConfirmDialog(foodName: item.foodName),
    );
    if (confirm != true) return;
    try {
      final userId = UserSession().getUserId();
      await _apiClient.deleteIntake(intakeId: item.id, userId: userId);
      await _loadItems();
      _showSnack('Produk berhasil dihapus');
    } catch (e) {
      _showSnack('Gagal menghapus produk: $e');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    return '${local.day}/${local.month}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _white,
      body: SafeArea(
        child: RefreshIndicator(
          color: _blue,
          onRefresh: _loadItems,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: _blue)),
                )
              else if (_items.isEmpty)
                SliverFillRemaining(hasScrollBody: false, child: _EmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 25, 20, 120),
                  sliver: SliverList.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return _ConsumedProductCard(
                        item: item,
                        timeLabel: _formatTime(item.consumedAt),
                        onDetail: () => _openDetail(item),
                        onEdit: () => _openEdit(item),
                        onDelete: () => _confirmDelete(item),
                        apiClient: _apiClient,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    const hariList = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const bulanList = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final hari = hariList[now.weekday - 1];
    final bulan = bulanList[now.month];
    final formattedDate = '$hari, ${now.day} $bulan ${now.year}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              Material(
                color: _blueSoft,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.pop(context, true),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(Icons.arrow_back, color: _blue, size: 20),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Konsumsi Hari Ini',
                  textAlign: TextAlign.center,
                  style: _ts(22, FontWeight.w700, _blue),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            formattedDate,
            style: _ts(13, FontWeight.w500, _blue.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }
}

class _ConsumedProductCard extends StatelessWidget {
  const _ConsumedProductCard({
    required this.item,
    required this.timeLabel,
    required this.onDetail,
    required this.onEdit,
    required this.onDelete,
    required this.apiClient,
  });

  final ConsumedTodayItem item;
  final String timeLabel;
  final VoidCallback onDetail;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ApiClient apiClient;

  static const _white = Color(0xFFFFFFFF);
  static const _blue = Color(0xFF2C4A8A);
  static const _navy = Color(0xFF213868);
  static const _blueSoft = Color(0xFFDFE4ED);
  static const _gray = Color(0xFFD9D9D9);
  static const _danger = Color(0xFFE53935);

  static TextStyle _ts(double size, FontWeight weight, Color color) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalSodiumMg = (item.sodiumMg * item.servings).round();
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
              item.foodName,
              style: _ts(17, FontWeight.w700, _navy),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
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
                          '$totalSodiumMg mg natrium',
                          style: _ts(13, FontWeight.w600, _blue),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _MetadataChips(
                        servingLabel: '${item.servings} Porsi',
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

class _MetadataChips extends StatelessWidget {
  const _MetadataChips({required this.servingLabel, required this.timeLabel});

  final String servingLabel;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: _IconChip(
            iconAsset: 'assets/icons/fluent_food-24-regular.svg',
            fallbackIcon: Icons.restaurant_menu_rounded,
            label: servingLabel,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
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

class _SodiumLevelBadge extends StatelessWidget {
  const _SodiumLevelBadge({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    final normalized = level.toLowerCase();
    final color = normalized == 'high'
        ? const Color(0xFFE53935)
        : normalized == 'medium'
        ? const Color(0xFFFFBF00)
        : const Color(0xFF43A047);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        normalized,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.consumed});
  final bool consumed;

  static const _green = Color(0xFF43A047);
  static const _amber = Color(0xFFFFBF00);

  @override
  Widget build(BuildContext context) {
    final color = consumed ? _green : _amber;
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15, color: color),
      label: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({
    this.path,
    required this.size,
    required this.apiClient, // ← tambah parameter ini
  });

  final String? path;
  final double size;
  final ApiClient apiClient; // ← tambah ini

  static const _blueSoft = Color(0xFFDFE4ED);
  static const _blueGray = Color(0xFFBEC7DB);

  @override
  Widget build(BuildContext context) {
    if (path != null && path!.isNotEmpty) {
      // Coba baca file lokal dulu
      final file = File(path!);
      if (file.existsSync()) {
        return Image.file(file, width: size, height: size, fit: BoxFit.cover);
      }

      // Fallback ke server URL (sama seperti history_screen)
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
      child: Icon(Icons.fastfood_rounded, color: _blueGray, size: 28),
    );
  }
}

class _EditInfoProductSheet extends StatefulWidget {
  const _EditInfoProductSheet({
    required this.item,
    required this.apiClient,
    required this.onSaved,
  });

  final ConsumedTodayItem item;
  final ApiClient apiClient;
  final Future<void> Function() onSaved;

  @override
  State<_EditInfoProductSheet> createState() => _EditInfoProductSheetState();
}

class _EditInfoProductSheetState extends State<_EditInfoProductSheet> {
  static const _blue = Color(0xFF2C4A8A);
  static const _border = Color(0xFFD7DCE8);

  late final TextEditingController _nameController;
  late final TextEditingController _portionSizeController;
  late final TextEditingController _portionsController;
  late final TextEditingController _sodiumController;
  late String _kategori;
  late int _servings;
  bool _saving = false;

  double? _parseIndoDouble(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    return double.tryParse(text.trim().replaceAll(',', '.'));
  }

  int? _parseIndoInt(String? text) {
    final parsed = _parseIndoDouble(text);
    return parsed?.toInt();
  }

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    final portions = math.max(1.0, item.portionsInPackage);
    final portionSize = item.packageMl > 0
        ? math.max(1.0, item.packageMl / portions)
        : 0.0;
    _nameController = TextEditingController(text: item.foodName);
    _portionSizeController = TextEditingController(
      text: _formatIndoNumber(portionSize),
    );
    _portionsController = TextEditingController(
      text: _formatIndoNumber(portions),
    );
    _sodiumController = TextEditingController(
      text: '${(item.sodiumMg * portions).round()}',
    );
    _kategori = item.kategori ?? 'lainnya';
    _servings = widget.item.servings.clamp(1, 10).toInt();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _portionSizeController.dispose();
    _portionsController.dispose();
    _sodiumController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final portionSize =
        _parseIndoDouble(_portionSizeController.text.trim()) ?? 0.0;
    final portions = _portionsInPackage;
    final sodiumPerPackage = _parseIndoDouble(_sodiumController.text.trim());
    if (name.isEmpty || sodiumPerPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua field wajib')),
      );
      return;
    }
    final sodiumPerServing = sodiumPerPackage / portions;

    setState(() => _saving = true);
    await widget.apiClient.updateIntake(
      intakeId: widget.item.id,
      userId: UserSession().getUserId(),
      foodName: name,
      kategori: _kategori,
      sodiumMg: sodiumPerServing,
      sodiumLevel: widget.item.sodiumLevel,
      servings: _servings,
      packageMl: portionSize * portions,
      portionsInPackage: portions,
      satuanTakaran: widget.item.satuanTakaran,
    );
    await widget.onSaved();
    if (mounted) Navigator.pop(context, true);
  }

  double get _portionsInPackage {
    return math.max(
      1.0,
      _parseIndoDouble(_portionsController.text.trim()) ?? 1.0,
    );
  }

  void _changeServing(int delta) {
    setState(() {
      _servings = (_servings + delta).clamp(1, 10).toInt();
    });
  }

  String _categoryLabel(String value) {
    for (final item in _ConsumedTodayScreenState._categories) {
      if (item.value == value) return item.label;
    }
    return 'Lainnya';
  }

  @override
  Widget build(BuildContext context) {
    if (_servings > 10) _servings = 10;

    return Padding(
      padding: EdgeInsets.only(
        left: 32,
        right: 32,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 26,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Center(
              child: Text(
                'Edit Informasi Produk',
                style: GoogleFonts.plusJakartaSans(
                  color: _blue,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 34),
            _EditInfoField(
              label: 'Nama Produk',
              requiredField: true,
              controller: _nameController,
            ),
            const SizedBox(height: 20),
            _EditInfoDropdown(
              label: 'Kategori',
              requiredField: true,
              value: _categoryLabel(_kategori),
              onTap: () async {
                final selected = await showCustomDropdown<String>(
                  context: context,
                  title: 'Pilih Kategori',
                  items: _ConsumedTodayScreenState._categories,
                  selectedValue: _kategori,
                );
                if (selected != null) setState(() => _kategori = selected);
              },
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _EditInfoField(
                    label: 'Takaran per porsi',
                    requiredField: true,
                    controller: _portionSizeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    suffixText: 'ml/g',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _EditInfoField(
                    label: 'Porsi per kemasan',
                    requiredField: true,
                    controller: _portionsController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    suffixText: 'Porsi',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _EditInfoField(
              label: 'Jumlah natrium per kemasan',
              requiredField: true,
              controller: _sodiumController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              suffixText: 'mg',
            ),
            const SizedBox(height: 20),
            Text(
              'Jumlah yang kamu konsumsi',
              style: GoogleFonts.plusJakartaSans(
                color: _blue,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            _EditInfoStepper(
              value: _servings,
              max: 10,
              label: '$_servings',
              onMinus: () => _changeServing(-1),
              onPlus: () => _changeServing(1),
            ),
            const SizedBox(height: 38),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Simpan Perubahan',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditInfoField extends StatelessWidget {
  const _EditInfoField({
    required this.label,
    required this.controller,
    this.requiredField = false,
    this.keyboardType,
    this.suffixText,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final bool requiredField;
  final TextInputType? keyboardType;
  final String? suffixText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EditInfoLabel(label, requiredField: requiredField),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  onChanged: onChanged,
                  inputFormatters: keyboardType == TextInputType.number
                      ? [FilteringTextInputFormatter.digitsOnly]
                      : null,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF213868),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: const BorderSide(
                        color: _EditInfoProductSheetState._border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: const BorderSide(
                        color: _EditInfoProductSheetState._blue,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: const BorderSide(
                        color: _EditInfoProductSheetState._border,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (suffixText != null) ...[
              const SizedBox(width: 8),
              Text(
                suffixText!,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF213868),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _EditInfoDropdown extends StatelessWidget {
  const _EditInfoDropdown({
    required this.label,
    required this.value,
    required this.onTap,
    this.requiredField = false,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EditInfoLabel(label, requiredField: requiredField),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: _EditInfoProductSheetState._border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF213868),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF2C4A8A),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EditInfoLabel extends StatelessWidget {
  const _EditInfoLabel(this.text, {this.requiredField = false});

  final String text;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: text,
        style: GoogleFonts.plusJakartaSans(
          color: const Color(0xFF213868),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        children: [
          if (requiredField)
            TextSpan(
              text: '*',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFFE53935),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

class _EditInfoStepper extends StatelessWidget {
  const _EditInfoStepper({
    required this.value,
    required this.max,
    required this.label,
    required this.onMinus,
    required this.onPlus,
  });

  final int value;
  final int max;
  final String label;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _EditInfoStepperButton(
          icon: Icons.remove,
          enabled: value > 1,
          onTap: onMinus,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: _EditInfoProductSheetState._border),
            ),
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF213868),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        _EditInfoStepperButton(
          icon: Icons.add,
          enabled: value < max,
          onTap: onPlus,
        ),
      ],
    );
  }
}

class _EditInfoStepperButton extends StatelessWidget {
  const _EditInfoStepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: enabled
              ? _EditInfoProductSheetState._blue
              : const Color(0xFFD9D9D9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _EditConsumedSheet extends StatefulWidget {
  const _EditConsumedSheet({
    required this.item,
    required this.apiClient,
    required this.onSaved,
  });

  final ConsumedTodayItem item;
  final ApiClient apiClient;
  final Future<void> Function() onSaved;

  @override
  State<_EditConsumedSheet> createState() => _EditConsumedSheetState();
}

class _EditConsumedSheetState extends State<_EditConsumedSheet> {
  static const _blue = Color(0xFF2C4A8A);
  static const _muted = Color(0xFFAAAAAA);

  late final TextEditingController _nameController;
  late final TextEditingController _sodiumController;
  late final TextEditingController _servingsController;
  late final TextEditingController _packageController;
  late final TextEditingController _portionsController;
  late final TextEditingController _unitController;
  late String _kategori;
  late String _level;
  late int _selectedServings;
  bool _saving = false;

  double? _parseIndoDouble(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    return double.tryParse(text.trim().replaceAll(',', '.'));
  }

  int? _parseIndoInt(String? text) {
    final parsed = _parseIndoDouble(text);
    return parsed?.toInt();
  }

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item.foodName);
    _sodiumController = TextEditingController(
      text: item.sodiumMg.round().toString(),
    );
    _servingsController = TextEditingController(text: item.servings.toString());
    _packageController = TextEditingController(
      text: _formatIndoNumber(item.packageMl),
    );
    _portionsController = TextEditingController(
      text: _formatIndoNumber(item.portionsInPackage),
    );
    _unitController = TextEditingController(text: item.satuanTakaran);
    _kategori = item.kategori ?? 'lainnya';
    _level = item.sodiumLevel;
    _selectedServings = math.max(1, item.servings);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sodiumController.dispose();
    _servingsController.dispose();
    _packageController.dispose();
    _portionsController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final userId = UserSession().getUserId();
    final sodium = _parseIndoDouble(_sodiumController.text.trim());
    final packageMl = _parseIndoDouble(_packageController.text.trim()) ?? 0.0;
    final portions = _parseIndoDouble(_portionsController.text.trim()) ?? 1.0;
    if (_nameController.text.trim().isEmpty || sodium == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi nama dan natrium')),
      );
      return;
    }
    setState(() => _saving = true);
    await widget.apiClient.updateIntake(
      intakeId: widget.item.id,
      userId: userId,
      foodName: _nameController.text.trim(),
      kategori: _kategori,
      sodiumMg: sodium,
      sodiumLevel: _level,
      servings: _selectedServings,
      packageMl: packageMl,
      portionsInPackage: portions,
      satuanTakaran: _unitController.text.trim().isEmpty
          ? 'g'
          : _unitController.text.trim(),
    );
    await widget.onSaved();
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final unit = _unitController.text.trim().isEmpty
        ? 'g'
        : _unitController.text.trim();
    final packageMl = _parseIndoDouble(_packageController.text.trim()) ?? 0.0;
    final portions = math.max(
      1.0,
      _parseIndoDouble(_portionsController.text.trim()) ??
          widget.item.portionsInPackage,
    );
    final takaranPerSajian = packageMl > 0
        ? math.max(1.0, packageMl / portions)
        : 0.0;
    final sliderMax = math.max(
      10,
      math.max(portions.ceil(), _selectedServings),
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF28437C),
                    Color(0xFF2C4A8A),
                    Color(0xFF425C95),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Edit Produk',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sesuaikan data konsumsi hari ini',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _FormSection(
              title: 'Data Produk',
              children: [
                _EditField(label: 'Nama Produk', controller: _nameController),
                _EditField(
                  label: 'Natrium',
                  controller: _sodiumController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _FormSection(
              title: 'Berapa sajian yang kamu konsumsi?',
              children: [
                Text(
                  takaranPerSajian > 0
                      ? '1 sajian = ${_formatIndoNumber(takaranPerSajian)} $unit - ${_formatIndoNumber(portions)} sajian per kemasan'
                      : '1 sajian = ${_sodiumController.text.trim().isEmpty ? 0 : _sodiumController.text.trim()} mg natrium',
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
                    takaranPerSajian > 0
                        ? '$_selectedServings Sajian  (${_formatIndoNumber(_selectedServings * takaranPerSajian)} $unit)'
                        : '$_selectedServings Sajian',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _blue,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _PortionSlider(
                  value: _selectedServings,
                  min: 1,
                  max: sliderMax,
                  thumbColor: _blue,
                  onChanged: _setServings,
                ),
                const SizedBox(height: 8),
                _EditField(
                  label: 'Porsi/Servings',
                  controller: _servingsController,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    if (parsed != null && parsed > 0) {
                      _setServings(parsed);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _FormSection(
              title: 'Detail Produk',
              children: [
                _SheetDropdown(
                  label: 'Kategori',
                  value: _categoryLabel(_kategori),
                  onTap: () async {
                    final selected = await showCustomDropdown<String>(
                      context: context,
                      title: 'Pilih Kategori',
                      items: _ConsumedTodayScreenState._categories,
                      selectedValue: _kategori,
                    );
                    if (selected != null) setState(() => _kategori = selected);
                  },
                ),
                _SheetDropdown(
                  label: 'Level Natrium',
                  value: _level,
                  onTap: () async {
                    final selected = await showCustomDropdown<String>(
                      context: context,
                      title: 'Pilih Level Natrium',
                      items: _ConsumedTodayScreenState._levels,
                      selectedValue: _level,
                    );
                    if (selected != null) setState(() => _level = selected);
                  },
                ),
                _EditField(
                  label: 'Package ML',
                  controller: _packageController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                _EditField(
                  label: 'Sajian/Kemasan',
                  controller: _portionsController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                _EditField(
                  label: 'Satuan Takaran',
                  controller: _unitController,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Simpan Perubahan',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setServings(int value) {
    final safeValue = math.max(1, value);
    setState(() {
      _selectedServings = safeValue;
      _servingsController.text = safeValue.toString();
      _servingsController.selection = TextSelection.fromPosition(
        TextPosition(offset: _servingsController.text.length),
      );
    });
  }

  String _categoryLabel(String value) {
    for (final item in _ConsumedTodayScreenState._categories) {
      if (item.value == value) return item.label;
    }
    return 'Lainnya';
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2C4A8A),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

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
        final boxLeft = (thumbX - boxW / 2)
            .clamp(0.0, trackWidth - boxW)
            .toDouble();

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
                    value: value
                        .toDouble()
                        .clamp(min.toDouble(), math.max(min, max).toDouble())
                        .toDouble(),
                    min: min.toDouble(),
                    max: math.max(min, max).toDouble(),
                    divisions: range > 0 ? range : null,
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
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF2C4A8A),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: onChanged,
            inputFormatters: keyboardType == TextInputType.number
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF2C4A8A),
              fontSize: 14,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCCD2DF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2C4A8A)),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCCD2DF)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetDropdown extends StatelessWidget {
  const _SheetDropdown({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF2C4A8A),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          CustomDropdownField(
            value: value,
            placeholder: label,
            textAlign: TextAlign.left,
            height: 55,
            fontSize: 15,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/illustrations/belum_konsumsi_hariini.png',
              width: 255,
              height: 255,
            ),
            const SizedBox(height: 4),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF2C4A8A).withOpacity(0.7),
                  fontSize: 16,
                  height: 1.3,
                ),
                children: [
                  TextSpan(
                    text: 'Belum ada ',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF2C4A8A),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const TextSpan(text: 'yang tercatat'),
                  TextSpan(
                    text: ' hari ini.',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF2C4A8A),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const TextSpan(text: ' \nyuk,'),
                  TextSpan(
                    text: ' mulai scan',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF2C4A8A),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const TextSpan(text: ' kemasan produk!'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteConfirmDialog extends StatelessWidget {
  const _DeleteConfirmDialog({required this.foodName});

  final String foodName;

  static const _blue = Color(0xFF2C4A8A);
  static const _muted = Color(0xFF9AA3B5);
  static const _red = Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Yakin Hapus Catatan\nKonsumsi?',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: _blue,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),
            Image.asset(
              'assets/illustrations/delete.png',
              width: 180,
              height: 180,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.plusJakartaSans(
                  color: _blue,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
                children: const [
                  TextSpan(text: 'Riwayat scan yang dipilih '),
                  TextSpan(
                    text: 'akan dihapus',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: '\ndan '),
                  TextSpan(
                    text: 'tidak dapat dipulihkan',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Batal — TextButton muted (tanpa fill)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  foregroundColor: _muted,
                  overlayColor: _muted.withOpacity(0.1),
                ),
                child: Text(
                  'Batal',
                  style: GoogleFonts.plusJakartaSans(
                    color: _muted,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Hapus — FilledButton merah
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: _red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: Text(
                  'Hapus',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
