import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized SKENNA text style tokens.
///
/// Future screens should compose these styles with color tokens:
///
/// ```dart
/// Text(
///   'Hello',
///   style: AppTextStyles.bold20.copyWith(
///     color: AppColors.blue300,
///   ),
/// )
/// ```
///
/// Common examples:
/// - `AppTextStyles.bold20` for section titles.
/// - `AppTextStyles.regular13` for helper or body text.
class AppTextStyles {
  const AppTextStyles._();

  static const double _height = 1.2;

  static TextStyle _style(double size, FontWeight weight) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      height: _height,
    );
  }

  static final bold50 = _style(50, FontWeight.w700);
  static final bold39 = _style(39, FontWeight.w700);
  static final bold31 = _style(31, FontWeight.w700);
  static final bold25 = _style(25, FontWeight.w700);
  static final bold20 = _style(20, FontWeight.w700);
  static final bold16 = _style(16, FontWeight.w700);
  static final bold13 = _style(13, FontWeight.w700);
  static final bold10 = _style(10, FontWeight.w700);

  static final semiBold39 = _style(39, FontWeight.w600);
  static final semiBold31 = _style(31, FontWeight.w600);
  static final semiBold25 = _style(25, FontWeight.w600);
  static final semiBold20 = _style(20, FontWeight.w600);
  static final semiBold16 = _style(16, FontWeight.w600);
  static final semiBold13 = _style(13, FontWeight.w600);
  static final semiBold10 = _style(10, FontWeight.w600);

  static final regular39 = _style(39, FontWeight.w400);
  static final regular31 = _style(31, FontWeight.w400);
  static final regular25 = _style(25, FontWeight.w400);
  static final regular20 = _style(20, FontWeight.w400);
  static final regular16 = _style(16, FontWeight.w400);
  static final regular13 = _style(13, FontWeight.w400);
  static final regular10 = _style(10, FontWeight.w400);

  static final thin39 = _style(39, FontWeight.w300);
  static final thin31 = _style(31, FontWeight.w300);
  static final thin25 = _style(25, FontWeight.w300);
  static final thin20 = _style(20, FontWeight.w300);
  static final thin16 = _style(16, FontWeight.w300);
  static final thin13 = _style(13, FontWeight.w300);
  static final thin10 = _style(10, FontWeight.w300);
}
