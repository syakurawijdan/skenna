import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../navigation/app_routes.dart';
import '../profile_wizard/profile_step_layout.dart';
import '../../../data/api_client.dart';

class EmailScreen extends StatefulWidget {
  const EmailScreen({super.key});

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  final _emailController = TextEditingController();
  bool _checking = false;

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

  Future<void> _next() async {
    if (!_isEmailValid || _checking) return;
    setState(() => _checking = true);
    try {
      await ApiClient().sendOtp(
        email: _emailController.text.trim(),
        purpose: 'register',
      );
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        AppRoutes.otpVerification,
        arguments: _emailController.text.trim(),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 400) {
        _showValidation('Email sudah terdaftar. Silakan login.');
      } else {
        _showValidation('Gagal mengirim OTP. Coba lagi.');
      }
    } catch (_) {
      if (!mounted) return;
      _showValidation('Gagal mengirim OTP. Coba lagi.');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _showValidation(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProfileStepLayout(
      showProgress: false,
      showBack: true,
      illustrationAsset: 'assets/illustrations/regritasi.png',
      title: 'Buat Akun SKENNA',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Email',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF2C4A8A),
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
              color: const Color(0xFF2C4A8A),
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
                borderSide: const BorderSide(color: Color(0xFF2C4A8A)),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD32F2F)),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD32F2F)),
              ),
              errorText: _emailController.text.isNotEmpty && !_isEmailValid
                  ? 'Format email tidak valid (nama@email.com)'
                  : null,
              errorStyle: GoogleFonts.plusJakartaSans(
                color: Colors.red,
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
            color: const Color(0xFF2C4A8A),
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.3,
          ),
          children: [
            TextSpan(
              text: 'Masukkan email',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const TextSpan(text: ' dan '),
            TextSpan(
              text: ' buat akun ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const TextSpan(text: ' untuk mulai memantau asupan natriummu'),
          ],
        ),
      ),
      primaryButton: FilledButton(
        onPressed: _isEmailValid && !_checking ? _next : null,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2C4A8A),
          disabledBackgroundColor: const Color(0xFFD9D9D9),
          elevation: 4,
          shadowColor: const Color(0x40000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: _checking
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Selanjutnya',
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
