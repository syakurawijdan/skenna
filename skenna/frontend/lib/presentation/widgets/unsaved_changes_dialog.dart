import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UnsavedChangesDialog extends StatelessWidget {
  const UnsavedChangesDialog({
    super.key,
    required this.title,
    required this.message,
    required this.negativeLabel,
    required this.positiveLabel,
    this.imagePath = 'assets/illustrations/yakin_makan_ini.png',
  });

  final String title;
  final Widget message;
  final String negativeLabel;
  final String positiveLabel;
  final String? imagePath;

  static const _blue = Color(0xFF2C4A8A);
  static const _muted = Color(0xFF9AA3B5);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: _blue,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),

            if (imagePath != null)
              Image.asset(
                imagePath!,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),

            const SizedBox(height: 20),

            DefaultTextStyle(
              style: GoogleFonts.plusJakartaSans(
                color: _blue,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              child: message,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  foregroundColor: _muted,
                  overlayColor: _muted.withOpacity(0.1),
                ),
                child: Text(
                  negativeLabel,
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
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: _blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: Text(
                  positiveLabel,
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
    );
  }
}
