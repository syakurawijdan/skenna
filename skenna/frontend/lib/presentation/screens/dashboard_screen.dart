import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/api_client.dart';
import '../../data/user_session.dart';
import '../../domain/natrium_classifier.dart';
import '../navigation/app_routes.dart';
import '../widgets/profile_avatar_image.dart';
import '../widgets/natrium_warning_dialog.dart';

enum DashboardGender { male, female }

class _DashboardPalette {
  const _DashboardPalette({
    required this.fallbackName,
    required this.greetingColor,
    required this.subtitleColor,
    required this.sectionTitleColor,
    required this.profileAsset,
    required this.editButtonBackgroundColor,
    required this.editIconColor,
    required this.primary,
    required this.heroGradient,
    required this.heroGradientStops,
    required this.gaugeCenterText,
  });

  final String fallbackName;
  final Color greetingColor;
  final Color subtitleColor;
  final Color sectionTitleColor;
  final String profileAsset;
  final Color editButtonBackgroundColor;
  final Color editIconColor;
  final Color primary;
  final List<Color> heroGradient;
  final List<double> heroGradientStops;
  final Color gaugeCenterText;
}

const _malePalette = _DashboardPalette(
  fallbackName: 'User',
  greetingColor: Color(0xFF2C4A8A),
  subtitleColor: Color(0xFF2C4A8A),
  sectionTitleColor: Color(0xFF213868),
  profileAsset: 'assets/illustrations/avatar_cowo.png',
  editButtonBackgroundColor: Color(0xFFDFE4ED),
  editIconColor: Color(0xFF2C4A8A),
  primary: Color(0xFF2C4A8A),
  heroGradient: [
    Color(0xFF28437C),
    Color(0xFF2C4A8A),
    Color(0xFF425C95),
    Color(0xFF586F9F),
    Color(0xFF8393B4),
    Color(0xFFDFE4ED),
  ],
  heroGradientStops: [0.0, 0.22, 0.40, 0.55, 0.72, 1.0],
  gaugeCenterText: Color(0xFF213868),
);

const _femalePalette = _DashboardPalette(
  fallbackName: 'User',
  greetingColor: Color(0xFFBD1E6D),
  subtitleColor: Color(0xFFBD1E6D),
  sectionTitleColor: Color(0xFF8E1752),
  profileAsset: 'assets/illustrations/avatar_cewe_pink.png',
  editButtonBackgroundColor: Color(0xFFF5DDE9),
  editIconColor: Color(0xFFBD1E6D),
  primary: Color(0xFFBD1E6D),
  heroGradient: [
    Color(0xFFAA1B62),
    Color(0xFFBD1E6D),
    Color(0xFFCC518E),
    Color(0xFFDB83AE),
    Color(0xFFE9B6CF),
    Color(0xFFF8E9F0),
  ],
  heroGradientStops: [0.0, 0.22, 0.40, 0.55, 0.72, 1.0],
  gaugeCenterText: Color(0xFF8E1752),
);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.apiClient,
    this.gender = DashboardGender.male,
    this.userName,
    this.refreshToken = 0,
    this.onProfileUpdated,
  });

  final ApiClient apiClient;
  final DashboardGender gender;
  final String? userName;
  final int refreshToken;
  final VoidCallback? onProfileUpdated;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _skennyQuestions = [
    'Bagaimana cara mencegah hipertensi?',
    'Berikan saya resep masakan rendah natrium',
    'Berapa batas natrium harian menurut WHO?',
    'Apa saja gejala tekanan darah tinggi?',
    'Makanan apa yang tinggi natrium dan harus dihindari?',
    'Apa hubungan natrium dengan hipertensi?',
    'Berapa batas natrium harian menurut AKG Kemenkes?',
    'Apa itu hipertensi dan apa penyebabnya?',
  ];

  String? _userName;
  DashboardGender _gender = DashboardGender.male;
  int _dailyLimitMg = 2000;
  int _akgReferenceMg = 1500;
  bool _isHardMaximum = true;
  int _age = 16;
  bool _hasHypertension = false;
  int _consumedTodayMg = 0;
  int _productsScannedToday = 0;
  String? _dashboardDate;
  bool _isLoading = true;
  int? _systolicPressure;
  String _statusKehamilan = 'tidak_hamil';
  int? _diastolicPressure;
  String? _escKategori;

  @override
  void initState() {
    super.initState();
    _userName = widget.userName;
    _gender = widget.gender;
    _loadDashboardData();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken ||
        oldWidget.userName != widget.userName ||
        oldWidget.gender != widget.gender) {
      _userName = widget.userName;
      _gender = widget.gender;
      _loadDashboardData();
    }
  }

  _DashboardPalette get _palette {
    return _gender == DashboardGender.female ? _femalePalette : _malePalette;
  }

  bool get _hamilDenganHT =>
      _hasHypertension &&
      (_statusKehamilan == 'hamil_normal' || _statusKehamilan == 'menyusui');

  String _displayName(_DashboardPalette palette) {
    final trimmed = _userName?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return palette.fallbackName;
    }
    return trimmed;
  }

  Future<void> _loadDashboardData() async {
    final userId = UserSession().getUserId();
    if (userId <= 0) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final results = await Future.wait<Map<String, dynamic>>([
        widget.apiClient.getUserProfile(userId),
        widget.apiClient.getDashboardStats(userId),
      ]);
      final profile = results[0];
      final stats = results[1];
      final hasil = await klasifikasiNatriumDariDraft(
        birthDate: DateTime.parse(profile['birth_date'] as String),
        gender: profile['gender'] as String? ?? '',
        hasHypertension: profile['has_hypertension'] as bool? ?? false,
        hypertensionCondition: profile['hypertension_condition'] as String?,
        systolicPressure: profile['systolic_pressure'] as int?,
        diastolicPressure: profile['diastolic_pressure'] as int?,
        pregnancyStatus: profile['pregnancy_status'] as String?,
      );
      debugPrint('=== batasNatrium: ${hasil.batasNatrium}');
      debugPrint('=== akgReferenceMg: ${hasil.akgReferenceMg}');
      debugPrint('=== isHardMaximum: ${hasil.isHardMaximum}');
      debugPrint('=== profile gender: ${profile['gender']}');
      debugPrint(
        '=== profile has_hypertension: ${profile['has_hypertension']}',
      );
      debugPrint('=== profile birth_date: ${profile['birth_date']}');
      debugPrint('=== profile systolic: ${profile['systolic_pressure']}');
      debugPrint('=== profile diastolic: ${profile['diastolic_pressure']}');
      debugPrint(
        '=== profile pregnancy_status: ${profile['pregnancy_status']}',
      );
      debugPrint('=== hasil.statusKehamilan: ${hasil.statusKehamilan}');
      debugPrint('=== hasil.hamilDenganHT: ${hasil.hamilDenganHT}');
      if (!mounted) return;
      setState(() {
        _userName = profile['full_name'] as String?;
        _gender = _resolveDashboardGender(profile['gender'] as String? ?? '');
        _dailyLimitMg = hasil.batasNatrium;
        _akgReferenceMg = hasil.akgReferenceMg ?? hasil.batasNatrium;
        _isHardMaximum = hasil.isHardMaximum;
        _age = hasil.usia;
        _hasHypertension = hasil.hasHypertension;
        _statusKehamilan = hasil.statusKehamilan;
        _consumedTodayMg =
            (stats['total_sodium_consumed_today'] as num?)?.round() ?? 0;
        _productsScannedToday =
            (stats['products_scanned_today'] as num?)?.round() ?? 0;
        final statsDate = stats['date'];
        _dashboardDate = statsDate is String && statsDate.trim().isNotEmpty
            ? statsDate.trim()
            : null;
        _isLoading = false;
        _systolicPressure = profile['systolic_pressure'] as int?;
        _diastolicPressure = profile['diastolic_pressure'] as int?;
        _escKategori = hasil.escKategori;
        _checkAndShowWarning();
      });
    } catch (e) {
      debugPrint('Dashboard load failed: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  DashboardGender _resolveDashboardGender(String rawGender) {
    final normalized = rawGender.trim().toLowerCase();
    if (normalized == 'female' ||
        normalized == 'perempuan' ||
        normalized == 'wanita') {
      return DashboardGender.female;
    }
    return DashboardGender.male;
  }

  String _formatMg(int value) => formatNatriumMg(value);

  void _openChatbot(BuildContext context, {String? question}) {
    Navigator.pushNamed(
      context,
      AppRoutes.chatbot,
      arguments: {'initialQuestion': question},
    );
  }

  Future<void> _openEditProfile(BuildContext context) async {
    final userId = UserSession().getUserId();
    debugPrint('Dashboard open edit profile userId: $userId');
    if (userId <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi pengguna belum ditemukan. Silakan masuk ulang.'),
        ),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding1);
      return;
    }

    await ApiClient.setCurrentUserId(userId);
    final updated = await Navigator.pushNamed(context, AppRoutes.editProfile);
    if (updated == true) {
      widget.onProfileUpdated?.call();
      _loadDashboardData();
    }
  }

  Future<void> _openConsumedToday(BuildContext context) async {
    final updated = await Navigator.pushNamed(context, AppRoutes.consumedToday);
    if (updated == true) {
      _loadDashboardData();
    }
  }

  void _checkAndShowWarning() {
    final userSession = UserSession();
    final dashboardDate = _dashboardDate;
    if (_consumedTodayMg >= _dailyLimitMg &&
        _dailyLimitMg > 0 &&
        !userSession.hasShownWarningForDate(dashboardDate)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (userSession.hasShownWarningForDate(dashboardDate)) return;
        if (dashboardDate != null) {
          userSession.markSodiumWarningShown(dashboardDate);
        }
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => NatriumWarningDialog(isHardMaximum: _isHardMaximum),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final palette = _palette;
    final displayName = _displayName(palette);
    final remainingMg = math.max(0, _dailyLimitMg - _consumedTodayMg);
    const bg = Color(0xFFFFFFFF);

    return Container(
      color: bg,
      child: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 55, 16, 150),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 362),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _openEditProfile(context),
                          child: SizedBox(
                            width: 65,
                            height: 65,
                            child: ProfileAvatarImage(
                              asset: palette.profileAsset,
                              size: 68,
                              debugLabel: 'Dashboard profile avatar',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 191,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hai, $displayName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                color: palette.sectionTitleColor,
                                fontSize: 32 / 1.6,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Pantau Natriummu Hari Ini',
                              style: GoogleFonts.plusJakartaSans(
                                color: palette.sectionTitleColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Material(
                        color: palette.editButtonBackgroundColor,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _openEditProfile(context),
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/icons/edit-2.svg',
                                width: 18,
                                height: 18,
                                colorFilter: ColorFilter.mode(
                                  palette.editIconColor,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Rekap Natrium Hari Ini',
                    style: GoogleFonts.plusJakartaSans(
                      color: palette.sectionTitleColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _NatriumRecapCard(
                    palette: palette,
                    dailyLimitMg: _dailyLimitMg,
                    akgReferenceMg: _akgReferenceMg,
                    age: _age,
                    hasHypertension: _hasHypertension,
                    consumedTodayMg: _consumedTodayMg,
                    isLoading: _isLoading,
                    onTapProduct: () => _openConsumedToday(context),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniInfoCard(
                          title: 'Total Konsumsi',
                          subtitle: 'Jumlah produk yang\n dikonsumsi hari ini',
                          value: _isLoading
                              ? '-'
                              : _productsScannedToday.toString(),
                          unit: 'Produk',
                          titleColor: const Color(0xFF213868),
                          bodyColor: const Color(0xFF2C4A8A),
                          valueColor: const Color(0xFF233B6E),
                          iconBg: const Color(0xFFDFE4ED),
                          icon: 'assets/icons/document-text.svg',
                          valueChipColor: const Color(0xFFDFE4ED),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _MiniInfoCard(
                          title: 'Sisa Natrium',
                          subtitle: 'Sisa batas konsumsi\nnatrium hari ini',
                          value: _isLoading ? '-' : _formatMg(remainingMg),
                          unit: 'Mg/Na',
                          titleColor: const Color(0xFFE53935),
                          bodyColor: const Color(0xFFE53935),
                          valueColor: const Color(0xFFE53935),
                          iconBg: const Color(0xFFFBE1E1),
                          icon: 'assets/icons/timer.svg',
                          valueChipColor: const Color(0xFFFCE2E4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_hamilDenganHT) ...[
                    const _PregnancyHypertensionAlertCard(),
                    const SizedBox(height: 24),
                  ],
                  if (_systolicPressure != null &&
                      _diastolicPressure != null &&
                      _escKategori != null) ...[
                    Text(
                      'Status Hipertensi',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF213868),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _HypertensionStatusCard(
                      systolic: _systolicPressure!,
                      diastolic: _diastolicPressure!,
                      escKategori: _escKategori!,
                      onEditTap: () => _openEditProfile(context),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    'Tanya Skenny',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF213868),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SkennyCard(
                    palette: palette,
                    onChatTap: () => _openChatbot(context),
                  ),
                  const SizedBox(height: 24),
                  _SkennyQuestionGrid(
                    questions: _skennyQuestions,
                    onQuestionTap: (question) {
                      _openChatbot(context, question: question);
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

enum _NatriumRecapVariant {
  childNormal,
  childHypertension,
  adultNormal,
  adultHypertension,
}

class _NatriumRecapCopy {
  const _NatriumRecapCopy({
    required this.title,
    required this.progressLabel,
    this.badgeLabel,
  });

  final String? badgeLabel;
  final String title;
  final String? progressLabel;

  factory _NatriumRecapCopy.resolve({
    required bool isChild,
    required bool isAdult,
    required bool hasHypertension,
  }) {
    final variant = switch ((isChild, isAdult, hasHypertension)) {
      (true, false, false) => _NatriumRecapVariant.childNormal,
      (true, false, true) => _NatriumRecapVariant.childHypertension,
      (false, true, false) => _NatriumRecapVariant.adultNormal,
      (false, true, true) => _NatriumRecapVariant.adultHypertension,
      _ => throw StateError('Kelompok usia Dashboard tidak valid'),
    };

    return switch (variant) {
      _NatriumRecapVariant.childNormal => const _NatriumRecapCopy(
        // badgeLabel: 'Acuan Natrium Harian',
        title: 'Acuan Natrium Harian',
        progressLabel: 'Konsumsi Hari Ini',
      ),
      _NatriumRecapVariant.childHypertension => const _NatriumRecapCopy(
        badgeLabel: 'Pantau hipertensi kamu',
        title: 'Acuan konsumsi harian',
        progressLabel: null,
      ),
      _NatriumRecapVariant.adultNormal => const _NatriumRecapCopy(
        title: 'Batas Harianmu',
        progressLabel: 'Kebutuhan natrium harian',
      ),
      _NatriumRecapVariant.adultHypertension => const _NatriumRecapCopy(
        badgeLabel: 'Batas ketat hipertensi (AHA)',
        title: 'Batas Natrium Harianmu',
        progressLabel: null,
      ),
    };
  }
}

class _NatriumRecapCard extends StatelessWidget {
  const _NatriumRecapCard({
    required this.onTapProduct,
    required this.palette,
    required this.dailyLimitMg,
    required this.akgReferenceMg,
    required this.age,
    required this.hasHypertension,
    required this.consumedTodayMg,
    required this.isLoading,
  });

  final VoidCallback onTapProduct;
  final _DashboardPalette palette;
  final int dailyLimitMg;
  final int age;
  final bool hasHypertension;
  final int consumedTodayMg;
  final bool isLoading;
  final int akgReferenceMg;

  static const double _cardRadius = 24;
  static const double _buttonWidth = 137;
  static const double _buttonHeight = 36;

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      Theme.of(context).textTheme,
    );
    final akgProgress = dailyLimitMg <= 0
        ? 0.0
        : consumedTodayMg / dailyLimitMg;
    final akgPercentage = (akgProgress * 100).round();
    final isChild = age < 16;
    final isAdult = age >= 16;
    final copy = _NatriumRecapCopy.resolve(
      isChild: isChild,
      isAdult: isAdult,
      hasHypertension: hasHypertension,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 330;
        final ringSize = compact ? 120.0 : 132.0;
        final horizontalPadding = compact ? 16.0 : 20.0;
        final cardHeight = compact ? 176.0 : 168.0;

        return Container(
          height: cardHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_cardRadius),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3310172A),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_cardRadius),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                        colors: palette.heroGradient,
                        stops: palette.heroGradientStops,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -34,
                  top: -36,
                  width: 190,
                  height: 142,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topRight,
                        radius: 0.94,
                        colors: [
                          Colors.white.withAlpha(60),
                          Colors.white.withAlpha(62),
                          Colors.white.withAlpha(0),
                        ],
                        stops: const [0.0, 0.48, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: -46,
                  bottom: -78,
                  width: 210,
                  height: 144,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.black.withAlpha(36),
                          Colors.black.withAlpha(0),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    18,
                    horizontalPadding * 0.72,
                    16,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: copy.progressLabel != null
                              ? MainAxisAlignment.spaceBetween
                              : MainAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (copy.badgeLabel != null) ...[
                                  _NatriumReferenceBadge(
                                    label: copy.badgeLabel!,
                                    compact: compact,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                Text(
                                  copy.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white.withAlpha(225),
                                    fontSize: compact ? 12 : 13,
                                    fontWeight: FontWeight.w400,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: isLoading
                                            ? '-'
                                            : formatNatriumMg(dailyLimitMg),
                                        style: textTheme.headlineSmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontSize: compact ? 25 : 28,
                                              fontWeight: FontWeight.w700,
                                              height: 1,
                                            ),
                                      ),
                                      TextSpan(
                                        text: '  Mg/Na',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white,
                                          fontSize: compact ? 9 : 10,
                                          fontWeight: FontWeight.w400,
                                          height: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                ),
                              ],
                            ),
                            if (copy.progressLabel case final progressLabel?)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    progressLabel,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: Colors.white.withAlpha(230),
                                      fontSize: compact ? 10 : 11,
                                      fontWeight: FontWeight.w400,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          isLoading
                                              ? '-'
                                              : '${formatNatriumMg(consumedTodayMg)} / ${formatNatriumMg(akgReferenceMg)} mg',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: Colors.white,
                                            fontSize: compact ? 12 : 13,
                                            fontWeight: FontWeight.w700,
                                            height: 1,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _AkgProgressBadge(
                                        value: isLoading
                                            ? '-'
                                            : '$akgPercentage%',
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            else
                              const SizedBox(height: 20),
                            SizedBox(
                              width: _buttonWidth,
                              height: _buttonHeight,
                              child: Material(
                                color: Colors.white.withAlpha(42),
                                borderRadius: BorderRadius.circular(18),
                                child: InkWell(
                                  onTap: onTapProduct,
                                  borderRadius: BorderRadius.circular(18),
                                  child: Center(
                                    child: Text(
                                      'Lihat Produk',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
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
                      SizedBox(width: compact ? 6 : 10),
                      Center(
                        child: _SodiumRing(
                          centerTextColor: palette.gaugeCenterText,
                          consumedTodayMg: consumedTodayMg,
                          progressTargetMg: dailyLimitMg,
                          isLoading: isLoading,
                          size: ringSize,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NatriumReferenceBadge extends StatelessWidget {
  const _NatriumReferenceBadge({required this.label, required this.compact});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 25,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(44),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/icons/mage_heart-health.svg',
            width: compact ? 15 : 16,
            height: compact ? 15 : 16,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w400,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _AkgProgressBadge extends StatelessWidget {
  const _AkgProgressBadge({required this.value, required this.color});

  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      Theme.of(context).textTheme,
    );

    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withAlpha(44),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        value,
        style: textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _SodiumRing extends StatelessWidget {
  const _SodiumRing({
    required this.centerTextColor,
    required this.consumedTodayMg,
    required this.progressTargetMg,
    required this.isLoading,
    required this.size,
  });

  final Color centerTextColor;
  final int consumedTodayMg;
  final int progressTargetMg;
  final bool isLoading;
  final double size;

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      Theme.of(context).textTheme,
    );

    final innerSize = size * 0.86;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _GaugePainter(
              progress: progressTargetMg <= 0
                  ? 0
                  : consumedTodayMg / progressTargetMg,
            ),
          ),
          Container(
            width: innerSize,
            height: innerSize,
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
                  isLoading ? '-' : formatNatriumMg(consumedTodayMg),
                  style: textTheme.headlineSmall?.copyWith(
                    color: centerTextColor,
                    fontSize: size < 130 ? 25 : 30,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mg/Na',
                  style: textTheme.bodyLarge?.copyWith(
                    color: centerTextColor,
                    fontSize: size < 130 ? 14 : 16,
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
  const _GaugePainter({required this.progress});

  final double progress;
  static const _gradientStops = <double>[0, 0.42, 0.72, 1];
  static const _gradientColors = <Color>[
    Color(0xFF4CAF50),
    Color(0xFFFFC107),
    Color(0xFFFF9800),
    Color(0xFFE53935),
  ];

  Color _colorAt(double value) {
    final clampedValue = value.clamp(0.0, 1.0);
    for (var i = 0; i < _gradientStops.length - 1; i++) {
      final start = _gradientStops[i];
      final end = _gradientStops[i + 1];
      if (clampedValue <= end) {
        final localT = (clampedValue - start) / (end - start);
        return Color.lerp(_gradientColors[i], _gradientColors[i + 1], localT)!;
      }
    }
    return _gradientColors.last;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = (size.width * 0.07).clamp(8.0, 10.0).toDouble();
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

    const start = -math.pi / 2; // mulai dari atas (jam 12)
    const totalSweep = math.pi * 2;
    final clamped = progress.clamp(0.0, 1.0);

    // Track background
    paint.color = Colors.white.withAlpha(48);
    canvas.drawArc(rect, start, totalSweep, false, paint);

    if (clamped <= 0) return;

    final activeSweep = totalSweep * clamped;
    const segments = 96;
    final segmentCount = math.max(1, (segments * clamped).ceil());

    for (var i = 0; i < segmentCount; i++) {
      final tStart = i / segmentCount;
      final tEnd = (i + 1) / segmentCount;
      final arcStart = start + activeSweep * tStart;
      // Segmen terakhir mentok persis ke activeSweep
      final arcSweep = activeSweep * (tEnd - tStart) + 0.01;
      paint.color = _colorAt(tEnd * clamped); // warna berdasar posisi actual
      canvas.drawArc(rect, arcStart, arcSweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
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
  final String icon;
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
              child: Center(
                // ← ini yang ditambah
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: SvgPicture.asset(
                    icon,
                    fit: BoxFit.contain,
                    colorFilter: ColorFilter.mode(valueColor, BlendMode.srcIn),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              color: titleColor,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              color: bodyColor,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 43,
            padding: const EdgeInsets.fromLTRB(13, 3, 13, 6),
            decoration: BoxDecoration(
              color: valueChipColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  // ← bungkus dengan Flexible
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: valueColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1,
                    ),
                  ),
                ),
                Text(
                  ' $unit',
                  style: textTheme.bodyLarge?.copyWith(
                    color: valueColor,
                    fontSize: 11, // ← kurangi sedikit dari 12
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE1E6EF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 125,
            height: 125,
            child: Image.asset(
              'assets/illustrations/chatbot_2.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Halo, Aku Skenny',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF2C4A8A),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tanya aku seputar natrium!',
                  style: textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF2C4A8A),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 40,
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
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
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

class _SkennyQuestionGrid extends StatelessWidget {
  const _SkennyQuestionGrid({
    required this.questions,
    required this.onQuestionTap,
  });

  final List<String> questions;
  final ValueChanged<String> onQuestionTap;

  @override
  Widget build(BuildContext context) {
    final row1 = <String>[];
    final row2 = <String>[];
    for (var i = 0; i < questions.length; i++) {
      if (i.isEven) {
        row1.add(questions[i]);
      } else {
        row2.add(questions[i]);
      }
    }

    return Column(
      children: [
        _ChipRow(questions: row1, onQuestionTap: onQuestionTap),
        const SizedBox(height: 12),
        _ChipRow(questions: row2, onQuestionTap: onQuestionTap),
      ],
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.questions, required this.onQuestionTap});

  final List<String> questions;
  final ValueChanged<String> onQuestionTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: questions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final question = questions[index];
          return _SkennyQuestionChip(
            label: question,
            onTap: () => onQuestionTap(question),
          );
        },
      ),
    );
  }
}

class _SkennyQuestionChip extends StatelessWidget {
  const _SkennyQuestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0XFFDFE4ED),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            maxLines: 2,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0XFF2C4A8A),
              fontWeight: FontWeight.w500,
              fontSize: 13,
              height: 2,
            ),
          ),
        ),
      ),
    );
  }
}

class _HypertensionStatusCard extends StatelessWidget {
  const _HypertensionStatusCard({
    required this.systolic,
    required this.diastolic,
    required this.escKategori,
    required this.onEditTap,
  });

  final int systolic;
  final int diastolic;
  final String escKategori;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFE0E0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            escKategori,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFFE53935),
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFFE53935),
                fontSize: 13,
                height: 1.2,
              ),
              children: [
                const TextSpan(
                  text: 'Disarankan ',
                  style: TextStyle(fontWeight: FontWeight.w400),
                ),
                const TextSpan(
                  text: 'membatasi asupan natrium harian',
                  style: TextStyle(fontWeight: FontWeight.w400),
                ),
                const TextSpan(
                  text: '.',
                  style: TextStyle(fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _BloodPressureChip(
                  label: 'Sistolik',
                  value: '$systolic',
                  unit: 'mmHg',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BloodPressureChip(
                  label: 'Diastolik',
                  value: '$diastolic',
                  unit: 'mmHg',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: onEditTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: Text(
                'Edit Tekanan Darah',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
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

class _PregnancyHypertensionAlertCard extends StatelessWidget {
  const _PregnancyHypertensionAlertCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB74D)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE0B2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: Color(0xFFE65100),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kondisi Memerlukan Perhatian Khusus',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFFE65100),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Kamu sedang hamil/menyusui dan memiliki hipertensi. Batas natrium umum pada aplikasi ini mungkin tidak cukup akurat untuk kondisimu segera konsultasikan ke dokter kandungan atau dokter spesialis untuk pemantauan lebih lanjut.',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF8A4B00),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
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

class _BloodPressureChip extends StatelessWidget {
  const _BloodPressureChip({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEBEB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFFE53935),
              fontSize: 11,
              fontWeight: FontWeight.w400,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFFE53935),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(width: 3),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFFE53935),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
