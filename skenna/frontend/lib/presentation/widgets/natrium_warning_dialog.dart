import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Popup yang muncul di beranda ketika konsumsi natrium mencapai batas harian.
///
/// Ada dua varian berdasarkan [isHardMaximum]:
/// - [isHardMaximum] = true  → batas keras (usia ≥ 16 th), teks "batas maksimal"
/// - [isHardMaximum] = false → batas kecukupan (usia < 16 th / AKG), teks "kebutuhan harian"
class NatriumWarningDialog extends StatelessWidget {
  const NatriumWarningDialog({super.key, required this.isHardMaximum});

  final bool isHardMaximum;

  static const _blue = Color(0xFF2C4A8A);
  static const _muted = Color(0xFF9AA3B5);

  @override
  Widget build(BuildContext context) {
    // ── teks & asset berbeda per varian ──────────────────────────────────────
    final title = isHardMaximum
        ? 'Perhatikan\nAsupan Natrium Hari ini!'
        : 'Batas Kecukupan\nNatrium Harian Tercapai';

    final illustrationAsset = isHardMaximum
        ? 'assets/illustrations/warning.png'
        : 'assets/illustrations/natrium_tercukupi.png';

    final bodySpans = isHardMaximum
        ? <InlineSpan>[
            const TextSpan(text: 'Asupan natrium kamu '),
            const TextSpan(
              text: 'mencapai batas maksimal yang direkomendasikan',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const TextSpan(text: '.'),
          ]
        : <InlineSpan>[
            const TextSpan(text: 'Asupan natrium kamu '),
            const TextSpan(
              text:
                  'mencapai kebutuhan harian. Tetap jaga agar tidak berlebihan!',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ];

    // ── layout (sengaja identik dengan StopNatriumDialog) ────────────────────
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── judul ──────────────────────────────────────────────────────
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

            // ── ilustrasi ──────────────────────────────────────────────────
            Image.asset(
              illustrationAsset,
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),

            // ── body teks ─────────────────────────────────────────────────
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.plusJakartaSans(
                  color: _blue,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
                children: bodySpans,
              ),
            ),
            const SizedBox(height: 24),

            // ── tombol "Mengerti" ─────────────────────────────────────────
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
                  'Mengerti',
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
