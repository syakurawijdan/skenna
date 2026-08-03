import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileUnsavedChangesDialog extends StatefulWidget {
  const ProfileUnsavedChangesDialog({super.key});

  @override
  State<ProfileUnsavedChangesDialog> createState() =>
      _ProfileUnsavedChangesDialogState();
}

class _ProfileUnsavedChangesDialogState
    extends State<ProfileUnsavedChangesDialog> {
  static const _blue = Color(0xFF2C4A8A);
  static const _muted = Color(0xFF9AA3B5);
  bool _dismissed = false;

  void _popWith(bool value) {
    if (_dismissed) return;
    _dismissed = true;
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {},
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
                'Perubahan Belum\nDisimpan',
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
                'assets/illustrations/perhatian.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              Text(
                'Perubahan yang kamu buat akan hilang jika keluar sekarang.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: _blue,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton(
                  onPressed: () => _popWith(false),
                  style: TextButton.styleFrom(
                    foregroundColor: _muted,
                    overlayColor: _muted.withOpacity(0.1),
                  ),
                  child: Text(
                    'Keluar Tanpa Menyimpan',
                    style: GoogleFonts.plusJakartaSans(
                      color: _muted,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => _popWith(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: _blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: Text(
                    'Simpan Perubahan',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
