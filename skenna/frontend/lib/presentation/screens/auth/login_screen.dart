import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/api_client.dart';
import '../../navigation/app_routes.dart';
import '../profile_wizard/profile_step_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiClient = ApiClient();
  bool _obscurePassword = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isEmailValid {
    final email = _emailController.text.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  bool get _isFormValid {
    return _isEmailValid && _passwordController.text.isNotEmpty;
  }

  Future<void> _login() async {
    if (!_isEmailValid) {
      _showValidation('Format email tidak valid');
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showValidation('Password wajib diisi');
      return;
    }

    setState(() => _submitting = true);
    try {
      final response = await _apiClient.loginUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final rawUserId = response['user_id'];
      final userId = rawUserId is num
          ? rawUserId.toInt()
          : int.tryParse(rawUserId?.toString() ?? '');
      if (userId == null || userId <= 0) {
        throw const FormatException('Login response tidak menyertakan user ID');
      }
      await _routeAfterLogin(userId);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == HttpStatus.notFound) {
        _showValidation('Email belum terdaftar');
      } else if (e.statusCode == HttpStatus.unauthorized) {
        _showValidation('Email atau password salah');
      } else if (e.statusCode == HttpStatus.unprocessableEntity) {
        _showValidation('Data tidak valid. Periksa kembali email/password.');
      } else {
        _showValidation('Gagal terhubung ke server. Coba lagi.');
      }
    } catch (_) {
      if (!mounted) return;
      _showValidation('Gagal terhubung ke server. Coba lagi.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _routeAfterLogin(int userId) async {
    var hasProfile = false;
    try {
      final profile = await _apiClient.getUserProfile(userId);
      hasProfile =
          (profile['birth_date'] as String?)?.isNotEmpty == true &&
          (profile['gender'] as String?)?.isNotEmpty == true;
    } catch (_) {
      hasProfile = false;
    }

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      hasProfile ? AppRoutes.dashboard : AppRoutes.onboarding1,
      (route) => false,
    );
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
      progress: 1,
      illustrationAsset: 'assets/illustrations/welcomeback.png',
      title: 'Masuk ke SKENNA',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Email',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF2C4A8A),
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            child: TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
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
                errorText: _emailController.text.isNotEmpty && !_isEmailValid
                    ? 'Format email tidak valid (nama@email.com)'
                    : null,
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD32F2F)),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD32F2F)),
                ),
                errorStyle: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFFD32F2F),
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Password',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF2C4A8A),
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            child: TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (_isFormValid) {
                  _login();
                }
              },
              autofillHints: const [AutofillHints.password],
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF2C4A8A),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              decoration: profileFieldDecoration('Password').copyWith(
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
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF2C4A8A),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.forgotPassword),
              child: Text(
                'Lupa password?',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF2C4A8A),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Belum punya akun? ',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF8A94A6),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.registerEmail),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Daftar',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF2C4A8A),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      primaryButton: FilledButton(
        onPressed: _isFormValid && !_submitting ? _login : null,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2C4A8A),
          disabledBackgroundColor: const Color(0xFFD9D9D9),
          elevation: 4,
          shadowColor: const Color(0x40000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: _submitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Masuk',
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
