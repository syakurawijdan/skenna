import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/natrium_classifier.dart';
import '../../domain/profile_save_service.dart';
import '../app_shell.dart';

class SodiumLimitPregnantScreen extends StatefulWidget {
  const SodiumLimitPregnantScreen({super.key, required this.hasil});

  final HasilKlasifikasi hasil;

  @override
  State<SodiumLimitPregnantScreen> createState() =>
      _SodiumLimitPregnantScreenState();
}

class _SodiumLimitPregnantScreenState extends State<SodiumLimitPregnantScreen> {
  final ProfileSaveService _saveService = ProfileSaveService();
  bool _isSaving = false;

  static const _blue = Color(0xFF2C4A8A);
  static const _background = Colors.white;

  Future<void> _handleSaveAndContinue() async {
    setState(() => _isSaving = true);
    final result = await _saveService.saveProfile();
    if (!mounted) return;
    if (result['success'] == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<void>(builder: (_) => const AppShell()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String? ?? 'Gagal menyimpan'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final topSpacing = (constraints.maxHeight * 0.08)
                .clamp(32.0, 76.0)
                .toDouble();
            final sectionSpacing = (constraints.maxHeight * 0.03)
                .clamp(18.0, 30.0)
                .toDouble();
            final illustrationWidth = MediaQuery.sizeOf(context).width;
            final illustrationHeight = MediaQuery.sizeOf(context).height * 0.30;
            final contentWidth = (constraints.maxWidth - 32)
                .clamp(0.0, 344.0)
                .toDouble();

            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ── Grup atas ──
                Column(
                  children: [
                    SizedBox(height: topSpacing),
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentWidth),
                        child: Text(
                          'Lebih Ketat\nBatas Natrium Harian',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 33,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            color: _blue,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: sectionSpacing),
                    SizedBox(
                      width: illustrationWidth,
                      height: illustrationHeight,
                      child: Image.asset(
                        'assets/illustrations/batashamil.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                    ),
                    SizedBox(height: sectionSpacing),
                    Center(
                      child: Text(
                        '${formatNatriumMg(widget.hasil.batasNatrium)} mg',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 54,
                          fontWeight: FontWeight.w800,
                          color: _blue,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentWidth),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.plusJakartaSans(
                              color: _blue,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.25,
                            ),
                            children: [
                              const TextSpan(text: 'Ibu hamil disarankan '),
                              TextSpan(
                                text: 'tidak melebihi batas',
                                style: GoogleFonts.plusJakartaSans(
                                  color: _blue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                ),
                              ),
                              const TextSpan(text: ' untuk mencegah '),
                              TextSpan(
                                text: 'hipertensi gestasional.',
                                style: GoogleFonts.plusJakartaSans(
                                  color: _blue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF2D7),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        'Kebutuhan natrium harian Anda adalah 1200 mg.',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFFD5A400),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Grup bawah (button + deskripsi) ──
                Column(
                  children: [
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: FilledButton(
                          onPressed: _isSaving ? null : _handleSaveAndContinue,
                          style: FilledButton.styleFrom(
                            backgroundColor: _blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 4,
                            shadowColor: const Color(0x40000000),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Mulai',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentWidth),
                        child: Text(
                          'Perhitungan ini mengacu pada standar AKG, WHO, dan\nAHA, berdasarkan data yang kamu isi sebelumnya',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFFB7B7B7),
                            fontSize: 12,
                            height: 1.25,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: topSpacing * 0.65),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
