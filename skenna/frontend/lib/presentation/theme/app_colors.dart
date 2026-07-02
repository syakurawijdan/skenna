import 'package:flutter/material.dart';

/// Centralized SKENNA color tokens.
///
/// Future screens should use these tokens instead of hardcoded colors:
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
/// - `AppColors.blue300` for the primary male/blue brand accent.
/// - `AppColors.pink300` for the primary female/pink brand accent.
class AppColors {
  const AppColors._();

  static const blue50 = Color(0xFFFFFFFF);
  static const blue100 = Color(0xFFDFE4ED);
  static const blue200 = Color(0xFFBEC7DB);
  static const blue300 = Color(0xFF2C4A8A);
  static const blue400 = Color(0xFF28437C);
  static const blue500 = Color(0xFF233B6E);
  static const blue600 = Color(0xFF213868);
  static const blue700 = Color(0xFF1A2C53);
  static const blue800 = Color(0xFF14213E);
  static const blue900 = Color(0xFF0F1A30);

  static const yellow50 = Color(0xFFFFF9E6);
  static const yellow100 = Color(0xFFFFF5D9);
  static const yellow200 = Color(0xFFFFEBB0);
  static const yellow300 = Color(0xFFFFBF00);
  static const yellow400 = Color(0xFFE6AC00);
  static const yellow500 = Color(0xFFCC9900);
  static const yellow600 = Color(0xFFBF8F00);
  static const yellow700 = Color(0xFF997300);
  static const yellow800 = Color(0xFF735600);
  static const yellow900 = Color(0xFF594300);

  static const pink50 = Color(0xFFF8E9F0);
  static const pink100 = Color(0xFFF5DDE9);
  static const pink200 = Color(0xFFEBB9D2);
  static const pink300 = Color(0xFFBD1E6D);
  static const pink400 = Color(0xFFAA1B62);
  static const pink500 = Color(0xFF971857);
  static const pink600 = Color(0xFF8E1752);
  static const pink700 = Color(0xFF711241);
  static const pink800 = Color(0xFF550D31);
  static const pink900 = Color(0xFF420B26);

  static const red50 = Color(0xFFFCEBEB);
  static const red100 = Color(0xFFFBE1E1);
  static const red200 = Color(0xFFF7C2C0);
  static const red300 = Color(0xFFE53935);
  static const red400 = Color(0xFFCE3330);
  static const red500 = Color(0xFFB72E2A);
  static const red600 = Color(0xFFAC2B28);
  static const red700 = Color(0xFF892220);
  static const red800 = Color(0xFF671A18);
  static const red900 = Color(0xFF501413);

  static const green50 = Color(0xFFECF6ED);
  static const green100 = Color(0xFFE3F1E3);
  static const green200 = Color(0xFFC5E2C6);
  static const green300 = Color(0xFF43A047);
  static const green400 = Color(0xFF3C9040);
  static const green500 = Color(0xFF368039);
  static const green600 = Color(0xFF327835);
  static const green700 = Color(0xFF28602B);
  static const green800 = Color(0xFF1E4820);
  static const green900 = Color(0xFF173819);

  static const neutral100 = Color(0xFFE6E6E6);
  static const neutral200 = Color(0xFFD9D9D9);
  static const neutral300 = Color(0xFFB0B0B0);
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);
}
