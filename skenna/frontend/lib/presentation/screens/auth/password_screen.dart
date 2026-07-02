import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/api_client.dart';
import '../../navigation/app_routes.dart';
import '../profile_wizard/profile_step_layout.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key, required this.email});

  final String email;

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _apiClient = ApiClient();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
    _confirmController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _passwordController.text.length >= 8 &&
        _passwordController.text == _confirmController.text;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_passwordController.text.length < 8) {
      _showValidation('Password minimal 8 karakter');
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      _showValidation('Konfirmasi password tidak sama');
      return;
    }

    setState(() => _submitting = true);
    try {
      await _apiClient.registerUser(
        email: widget.email,
        password: _passwordController.text,
      );

      await _apiClient.loginUser(
        email: widget.email,
        password: _passwordController.text,
      );
      if (!mounted) return;

      // Login otomatis setelah register
      final response = await _apiClient.loginUser(
        email: widget.email,
        password: _passwordController.text,
      );
      final rawUserId = response['user_id'];
      final userId = rawUserId is num
          ? rawUserId.toInt()
          : int.tryParse(rawUserId?.toString() ?? '');
      if (userId == null || userId <= 0) {
        throw const FormatException('Login response tidak menyertakan user ID');
      }

      if (!mounted) return;
      Navigator.pushNamed(
        context,
        AppRoutes.profileForm,
        arguments: widget.email,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == HttpStatus.badRequest) {
        _showValidation('Email sudah terdaftar. Silakan gunakan email lain.');
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

  void _showValidation(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  InputDecoration _passwordDecoration({
    required String hintText,
    required bool obscure,
    required VoidCallback onToggle,
    String? errorText,
  }) {
    return profileFieldDecoration(hintText).copyWith(
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
        onPressed: onToggle,
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: const Color(0xFF2C4A8A),
        ),
      ),
      errorText: errorText,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProfileStepLayout(
      showProgress: false,
      showBack: true,
      illustrationAsset: 'assets/illustrations/reset_pwd.png',
      title: 'Buat password',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF2C4A8A),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              decoration: _passwordDecoration(
                // ← ganti dari sini
                hintText: 'Minimal 8 karakter',
                obscure: _obscurePassword,
                onToggle: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                errorText:
                    _passwordController.text.isNotEmpty &&
                        _passwordController.text.length < 8
                    ? 'Password minimal 8 karakter'
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Konfirmasi password',
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
              controller: _confirmController,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (_isFormValid) {
                  _submit();
                }
              },
              autofillHints: const [AutofillHints.newPassword],
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF2C4A8A),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              decoration: _passwordDecoration(
                hintText: 'Ulangi password',
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                errorText:
                    _confirmController.text.isNotEmpty &&
                        _confirmController.text != _passwordController.text
                    ? 'Password tidak sama'
                    : null,
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
            const TextSpan(text: 'Gunakan password yang '),
            TextSpan(
              text: 'mudah \nkamu ingat dan sulit ditebak ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),

      primaryButton: FilledButton(
        onPressed: _isFormValid && !_submitting ? _submit : null,
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
