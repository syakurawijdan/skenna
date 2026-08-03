import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NoInternetDialog extends StatelessWidget {
  const NoInternetDialog({super.key});

  static const _blue = Color(0xFF2C4A8A);
  static const _bodyText = Color(0xFF2C4A8A);

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
              'Ups, Koneksi Internet\nTerputus',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: _blue,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),
            // Ganti dengan Image.asset kalau sudah ada ilustrasinya, contoh:
            // Image.asset(
            //   'assets/illustrations/kondisi_tidak_ada_internet.png',
            //   width: 200,
            //   height: 200,
            //   fit: BoxFit.contain,
            // ),
            Container(
              width: 200,
              height: 200,
              alignment: Alignment.center,
              child: Icon(
                Icons.wifi_off_rounded,
                size: 140,
                color: _blue.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.plusJakartaSans(
                  color: _bodyText,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
                children: const [
                  TextSpan(text: 'Pastikan '),
                  TextSpan(
                    text: 'koneksi internet kamu aktif, ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: 'lalu coba scan kembali'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: _blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: Text(
                  'Coba Lagi',
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
