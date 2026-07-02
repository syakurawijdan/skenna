import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../navigation/app_routes.dart';
import '../profile_wizard/profile_step_layout.dart';

class ForgotEmailScreen extends StatefulWidget {
  const ForgotEmailScreen({super.key});

  @override
  State<ForgotEmailScreen> createState() => _ForgotEmailScreenState();
}

class _ForgotEmailScreenState extends State<ForgotEmailScreen> {
  static const _blue = Color(0xFF2C4A8A);
  static const _error = Color(0xFFD32F2F);

  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool get _isEmailValid {
    final email = _emailController.text.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  void _sendOtp() {
    if (!_isEmailValid) return;
    Navigator.pushNamed(
      context,
      AppRoutes.otpVerification,
      arguments: <String, dynamic>{
        'email': _emailController.text.trim(),
        'isForgotPassword': true,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProfileStepLayout(
      showProgress: false,
      showBack: true,
      illustrationAsset: 'assets/illustrations/lupa _pwd.png',
      title: 'Lupa Password?',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Email',
            style: GoogleFonts.plusJakartaSans(
              color: _blue,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Pastikan email aktif untuk menerima OTP',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF8A94A6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            autofillHints: const [AutofillHints.email],
            style: GoogleFonts.plusJakartaSans(
              color: _blue,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            decoration: profileFieldDecoration('nama@email.com').copyWith(
              hintStyle: GoogleFonts.plusJakartaSans(
                color: const Color(0xFFB0B0B0),
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              filled: false,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFBEC7DB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFBEC7DB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _blue),
              ),
              errorText: _emailController.text.isNotEmpty && !_isEmailValid
                  ? 'Format email tidak valid (nama@email.com)'
                  : null,
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _error),
              ),
              errorStyle: GoogleFonts.plusJakartaSans(
                color: _error,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text.rich(
        textAlign: TextAlign.center,
        TextSpan(
          style: GoogleFonts.plusJakartaSans(
            color: _blue,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.3,
          ),
          children: const [
            TextSpan(
              text: 'Masukkan email ',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: 'yang terdaftar untuk '),
            TextSpan(
              text: 'menerima kode OTP',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      primaryButton: FilledButton(
        onPressed: _isEmailValid ? _sendOtp : null,
        style: FilledButton.styleFrom(
          backgroundColor: _blue,
          disabledBackgroundColor: const Color(0xFFD9D9D9),
          elevation: 4,
          shadowColor: const Color(0x40000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Text(
          'Kirim OTP',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
      ),
    );
  }
}
