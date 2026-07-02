import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class YakinMakanDialog extends StatelessWidget {
  const YakinMakanDialog({super.key, this.isUpdate = false});

  final bool isUpdate;

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
              isUpdate
                  ? 'Perbarui Jumlah\nSajian Produk Ini?'
                  : 'Tambahkan Produk ke\nKonsumsi Hari Ini?',
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
              'assets/illustrations/yakin_makan_ini.png',
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
                children: isUpdate
                    ? const [
                        TextSpan(text: 'Kamu akan '),
                        TextSpan(
                          text: 'memperbarui jumlah sajian produk ini',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: ' di konsumsi hari ini'),
                      ]
                    : const [
                        TextSpan(text: 'Apakah produk yang '),
                        TextSpan(
                          text: 'baru dipindai ini',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: ' akan '),
                        TextSpan(
                          text: 'kamu konsumsi hari ini?',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton(
                onPressed: () =>
                    Navigator.pop(context, isUpdate ? null : false),
                style: TextButton.styleFrom(
                  foregroundColor: _muted,
                  overlayColor: _muted.withOpacity(0.1),
                ),
                child: Text(
                  isUpdate ? 'Batal' : 'Tidak',
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
                  isUpdate ? 'Ya, Perbarui' : 'Ya, Tambahkan',
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
