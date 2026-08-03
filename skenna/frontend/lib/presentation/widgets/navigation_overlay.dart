import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum NavigationOverlayType {
  home,
  scan,
  history,
  profile;

  String get storageKey {
    return switch (this) {
      NavigationOverlayType.home => 'seen_home_overlay',
      NavigationOverlayType.scan => 'seen_scan_overlay',
      NavigationOverlayType.history => 'seen_history_overlay',
      NavigationOverlayType.profile => 'seen_profile_overlay',
    };
  }

  // String get message {
  //   return switch (this) {
  //     NavigationOverlayType.home =>
  //       'Pantau asupan natrium harian dan rekomendasinya di sini',
  //     NavigationOverlayType.history =>
  //       'Lihat riwayat konsumsi natrium dan catatan harianmu di sini',
  //     NavigationOverlayType.scan =>
  //       'Scan label produk makanan untuk cek kandungan natriumnya langsung',
  //     NavigationOverlayType.profile =>
  //       'Kelola profil dan preferensi natriummu di sini',
  //   };
  // }
}

class NavigationOverlayController {
  NavigationOverlayController({required TickerProvider vsync})
    : _animationController = AnimationController(
        vsync: vsync,
        duration: const Duration(milliseconds: 250),
        reverseDuration: const Duration(milliseconds: 200),
      );

  Timer? _dismissTimer;
  OverlayEntry? _overlayEntry;
  final AnimationController _animationController;
  NavigationOverlayType? visibleType;
  int _overlayGeneration = 0;

  bool get isVisible => visibleType != null;

  Future<void> showIfNeeded(
    BuildContext context,
    NavigationOverlayType type, {
    required double navBarWidth,
    required Map<NavigationOverlayType, double> navItemCenters,
    required double bottom,
    int? userId,
  }) async {
    debugPrint('Navigation overlay navbar tapped: $type');
    final prefs = await SharedPreferences.getInstance();
    final key = userId != null && userId > 0
        ? '${type.storageKey}_$userId'
        : type.storageKey;
    if (prefs.getBool(key) == true) {
      debugPrint('Navigation overlay already seen: $key');
      if (isVisible) {
        await dismiss();
      }
      return;
    }

    _removeCurrentOverlay(immediate: true);

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      debugPrint('Navigation overlay skipped: no Overlay found');
      return;
    }

    await prefs.setBool(key, true);
    final generation = ++_overlayGeneration;
    visibleType = type;
    debugPrint('Navigation overlay created: $type');

    _overlayEntry = OverlayEntry(
      builder: (_) {
        final scale = Tween<double>(begin: 0.96, end: 1).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );
        return FadeTransition(
          opacity: _animationController,
          child: ScaleTransition(
            scale: scale,
            child: NavigationOverlay(
              type: type,
              navBarWidth: navBarWidth,
              navItemCenters: navItemCenters,
              bottom: bottom,
              onDismiss: dismiss,
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
    debugPrint('Navigation overlay inserted: $type');
    _animationController.forward(from: 0);

    _dismissTimer = Timer(const Duration(seconds: 3), () {
      if (generation == _overlayGeneration) {
        dismiss();
      }
    });
  }

  Future<void> dismiss() async {
    if (_overlayEntry == null) return;
    _dismissTimer?.cancel();
    final type = visibleType;
    final entry = _overlayEntry;
    final generation = _overlayGeneration;
    debugPrint('Navigation overlay removing: $type');
    try {
      await _animationController.reverse();
    } on TickerCanceled {
      return;
    }
    if (_overlayEntry == entry && generation == _overlayGeneration) {
      _removeCurrentOverlay(immediate: true);
    }
  }

  void _removeCurrentOverlay({required bool immediate}) {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      debugPrint('Navigation overlay removed');
    }
    visibleType = null;
    if (immediate) {
      _animationController.stop();
      _animationController.reset();
    }
  }

  void dispose() {
    _removeCurrentOverlay(immediate: true);
    _animationController.dispose();
  }
}

class NavigationOverlay extends StatelessWidget {
  const NavigationOverlay({
    super.key,
    required this.type,
    required this.navBarWidth,
    required this.navItemCenters,
    required this.bottom,
    required this.onDismiss,
  });

  final NavigationOverlayType type;
  final double navBarWidth;
  final Map<NavigationOverlayType, double> navItemCenters;
  final double bottom;
  final VoidCallback onDismiss;

  static const _tooltipWidth = 238.0;
  static const _tooltipRadius = 16.0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final navLeft = (screenWidth - navBarWidth) / 2;
    final itemCenter = navLeft + (navItemCenters[type] ?? navBarWidth / 2);
    final tooltipLeft = (itemCenter - _tooltipWidth / 2).clamp(
      16.0,
      screenWidth - _tooltipWidth - 16.0,
    );
    final arrowLeft = (itemCenter - tooltipLeft - 7).clamp(
      18.0,
      _tooltipWidth - 32.0,
    );

    return Stack(
      children: [
        Positioned.fill(
          bottom: bottom - 10,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onDismiss,
            child: const SizedBox.expand(),
          ),
        ),
        // Positioned(
        //   left: tooltipLeft,
        //   bottom: bottom,
        //   width: _tooltipWidth,
        //   // child: _NavigationTooltip(
        //   //   message: type.message,
        //   //   arrowLeft: arrowLeft,
        //   // ),
        // ),
      ],
    );
  }
}

class _NavigationTooltip extends StatelessWidget {
  const _NavigationTooltip({required this.message, required this.arrowLeft});

  final String message;
  final double arrowLeft;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(
              NavigationOverlay._tooltipRadius,
            ),
            border: Border.all(color: AppColors.blue100),
            boxShadow: const [
              BoxShadow(
                color: Color(0x260F1A30),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            message,
            style: AppTextStyles.regular13.copyWith(color: AppColors.blue600),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: arrowLeft),
          child: CustomPaint(
            size: const Size(14, 9),
            painter: _TooltipArrowPainter(
              fillColor: AppColors.white,
              borderColor: AppColors.blue100,
            ),
          ),
        ),
      ],
    );
  }
}

class _TooltipArrowPainter extends CustomPainter {
  const _TooltipArrowPainter({
    required this.fillColor,
    required this.borderColor,
  });

  final Color fillColor;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, Paint()..color = fillColor);
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _TooltipArrowPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor;
  }
}
