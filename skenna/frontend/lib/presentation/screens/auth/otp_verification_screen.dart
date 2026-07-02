import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/api_client.dart';
import '../../navigation/app_routes.dart';
import '../profile_wizard/profile_step_layout.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.isForgotPassword = false,
  });

  final String email;
  final bool isForgotPassword;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const _blue = Color(0xFF2C4A8A);

  final _apiClient = ApiClient();
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int _remainingSeconds = 60;
  bool _verifying = false;
  bool _sendingOtp = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isForgotPassword) {
        _sendOtp();
      } else {
        _startCountdown();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((controller) => controller.text).join();

  bool get _isOtpComplete => _otp.length == 6;

  Map<String, dynamic>? get _routeArguments {
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is Map<String, dynamic> ? args : null;
  }

  String get _email {
    return _routeArguments?['email'] as String? ?? widget.email;
  }

  bool get _isForgotPassword {
    return _routeArguments?['isForgotPassword'] as bool? ??
        widget.isForgotPassword;
  }

  Future<void> _sendOtp() async {
    if (_sendingOtp) return;
    setState(() => _sendingOtp = true);
    try {
      await _apiClient.sendOtp(
        email: _email,
        purpose: widget.isForgotPassword ? 'forgot_password' : 'register',
      );
      _startCountdown();
    } catch (_) {
      if (!mounted) return;
      _showMessage('Gagal mengirim OTP. Coba lagi.');
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _remainingSeconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
        return;
      }
      setState(() => _remainingSeconds -= 1);
    });
  }

  Future<void> _verifyOtp() async {
    if (!_isOtpComplete || _verifying) return;
    setState(() => _verifying = true);
    try {
      await _apiClient.verifyOtp(email: widget.email, otp: _otp);
      if (!mounted) return;
      if (_isForgotPassword) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.changePassword,
          arguments: _email,
        );
      } else {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.registerPassword,
          arguments: _email,
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (e is ApiException && e.statusCode == 400) {
        _showMessage('Email sudah terdaftar. Silakan login.');
      } else if (e is ApiException && e.statusCode == 404) {
        _showMessage('Email tidak terdaftar');
      } else {
        _showMessage('Gagal mengirim OTP. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty && index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
    if (_isOtpComplete) {
      FocusScope.of(context).unfocus();
    }
  }

  Widget _otpBox(int index) {
    return SizedBox(
      width: 46,
      height: 55,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.plusJakartaSans(
          color: _blue,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: false,
          contentPadding: EdgeInsets.zero,
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
            borderSide: const BorderSide(color: _blue, width: 1.5),
          ),
        ),
        onChanged: (value) => _onOtpChanged(index, value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProfileStepLayout(
      showProgress: false,
      showBack: true,
      illustrationAsset: 'assets/illustrations/OTP.png',
      title: 'Verifikasi Akunmu',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Masukkan 6 digit kode OTP yang dikirim ke',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: _blue,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _email,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: _blue,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, _otpBox),
          ),
          const SizedBox(height: 18),
          TextButton(
            onPressed: _remainingSeconds == 0 && !_sendingOtp ? _sendOtp : null,
            child: Text(
              _remainingSeconds == 0
                  ? (_sendingOtp ? 'Mengirim...' : 'Kirim ulang OTP')
                  : 'Kirim ulang dalam $_remainingSeconds detik',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: _remainingSeconds == 0 ? _blue : const Color(0xFF8A94A6),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      primaryButton: FilledButton(
        onPressed: _isOtpComplete && !_verifying ? _verifyOtp : null,
        style: FilledButton.styleFrom(
          backgroundColor: _blue,
          disabledBackgroundColor: const Color(0xFFD9D9D9),
          elevation: 4,
          shadowColor: const Color(0x40000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: _verifying
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Verifikasi',
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
