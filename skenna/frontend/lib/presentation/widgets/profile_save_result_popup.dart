import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileSaveResultPopup extends StatefulWidget {
  const ProfileSaveResultPopup({
    super.key,
    required this.isSuccess,
    this.autoDismissDuration = const Duration(milliseconds: 2000),
    this.onDismissed,
  });

  final bool isSuccess;
  final Duration autoDismissDuration;
  final VoidCallback? onDismissed;

  @override
  State<ProfileSaveResultPopup> createState() => _ProfileSaveResultPopupState();
}

class _ProfileSaveResultPopupState extends State<ProfileSaveResultPopup> {
  static const _blue = Color(0xFF2C4A8A);
  static const _muted = Color(0xFF9AA3B5);

  Timer? _dismissTimer;
  bool _allowTimerDismiss = false;

  @override
  void initState() {
    super.initState();
    _dismissTimer = Timer(widget.autoDismissDuration, _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    setState(() => _allowTimerDismiss = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onDismissed?.call();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowTimerDismiss,
      child: Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.isSuccess
                    ? 'Perubahan\nBerhasil Disimpan'
                    : 'Gagal Menyimpan',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: _blue,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 20),
              Image.asset(
                widget.isSuccess
                    ? 'assets/illustrations/berhasil.png'
                    : 'assets/illustrations/perhatian.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.plusJakartaSans(
                    color: _blue,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                  children: widget.isSuccess
                      ? [
                          const TextSpan(
                            text: 'Perubahan pada profil kamu\nsudah ',
                          ),
                          const TextSpan(
                            text: 'berhasil disimpan',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ]
                      : [
                          const TextSpan(text: 'Perubahan belum tersimpan,\n'),
                          const TextSpan(
                            text: 'Yuk coba lagi',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
