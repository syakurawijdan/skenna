import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/api_client.dart';
import 'profile_wizard/profile_step_layout.dart';

class ChangePasswordFromProfileScreen extends StatefulWidget {
  const ChangePasswordFromProfileScreen({super.key});

  @override
  State<ChangePasswordFromProfileScreen> createState() =>
      _ChangePasswordFromProfileScreenState();
}

class _ChangePasswordFromProfileScreenState
    extends State<ChangePasswordFromProfileScreen> {
  static const _blue = Color(0xFF2C4A8A);

  final _apiClient = ApiClient();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _oldPasswordController.addListener(() => setState(() {}));
    _newPasswordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _oldPasswordController.text.isNotEmpty &&
        _newPasswordController.text.length >= 8 &&
        _confirmPasswordController.text == _newPasswordController.text;
  }

  String? get _newPasswordError {
    if (_newPasswordController.text.isEmpty) return null;
    if (_newPasswordController.text.length < 8) {
      return 'Password minimal 8 karakter';
    }
    return null;
  }

  String? get _confirmPasswordError {
    if (_confirmPasswordController.text.isEmpty) return null;
    if (_confirmPasswordController.text != _newPasswordController.text) {
      return 'Password tidak sama';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_isFormValid) return;

    setState(() => _submitting = true);
    try {
      await _apiClient.changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password berhasil diubah')));
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showValidation(e.message);
    } catch (_) {
      if (!mounted) return;
      _showValidation('Gagal mengganti password. Coba lagi.');
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
      errorText: errorText,
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
      suffixIcon: IconButton(
        onPressed: onToggle,
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: _blue,
        ),
      ),
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required String hintText,
    String? errorText,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: _blue,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          obscureText: obscure,
          textInputAction: textInputAction,
          onSubmitted: (_) {
            if (textInputAction == TextInputAction.done && _isFormValid) {
              _submit();
            }
          },
          style: GoogleFonts.plusJakartaSans(
            color: _blue,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          decoration: _passwordDecoration(
            hintText: hintText,
            obscure: obscure,
            onToggle: onToggle,
            errorText: errorText,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProfileStepLayout(
      showBack: true,
      showProgress: false,
      title: 'Ganti Password',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.08),
          _passwordField(
            label: 'Password lama',
            controller: _oldPasswordController,
            obscure: _obscureOldPassword,
            hintText: 'Masukkan password lama',
            onToggle: () =>
                setState(() => _obscureOldPassword = !_obscureOldPassword),
          ),
          const SizedBox(height: 16),
          _passwordField(
            label: 'Password baru',
            controller: _newPasswordController,
            obscure: _obscureNewPassword,
            hintText: 'Minimal 8 karakter',
            errorText: _newPasswordError,
            onToggle: () =>
                setState(() => _obscureNewPassword = !_obscureNewPassword),
          ),
          const SizedBox(height: 16),
          _passwordField(
            label: 'Konfirmasi password baru',
            controller: _confirmPasswordController,
            obscure: _obscureConfirmPassword,
            hintText: 'Ulangi password baru',
            errorText: _confirmPasswordError,
            textInputAction: TextInputAction.done,
            onToggle: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
          ),
        ],
      ),
      subtitle: Text.rich(
        TextSpan(
          style: GoogleFonts.plusJakartaSans(
            color: _blue,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.3,
          ),
          children: const [
            TextSpan(
              text: 'Verifikasi password lama ',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: 'sebelum membuat password baru'),
          ],
        ),
        textAlign: TextAlign.center,
      ),
      primaryButton: FilledButton(
        onPressed: _isFormValid && !_submitting ? _submit : null,
        style: FilledButton.styleFrom(
          backgroundColor: _blue,
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
                'Simpan',
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
