import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/natrium_classifier.dart';
import '../../domain/profile_save_service.dart';
import '../app_shell.dart';

class SodiumLimitSafeScreen extends StatefulWidget {
  const SodiumLimitSafeScreen({super.key, required this.hasil});

  final HasilKlasifikasi hasil;

  @override
  State<SodiumLimitSafeScreen> createState() => _SodiumLimitSafeScreenState();
}

class _SodiumLimitSafeScreenState extends State<SodiumLimitSafeScreen> {
  static const _blue = Color(0xFF2C4A8A);
  static const _background = Colors.white;

  late ProfileSaveService _saveService;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _saveService = ProfileSaveService();
  }

  Future<void> _handleSaveAndContinue() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final result = await _saveService.saveProfile();
      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] as String? ?? 'Tersimpan'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
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
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final topSpacing =
                (constraints.maxHeight * 0.08).clamp(32.0, 76.0).toDouble();
            final sectionSpacing =
                (constraints.maxHeight * 0.03).clamp(18.0, 30.0).toDouble();
            final illustrationWidth = MediaQuery.sizeOf(context).width;
            final illustrationHeight = MediaQuery.sizeOf(context).height * 0.30;
            final contentWidth =
                (constraints.maxWidth - 32).clamp(0.0, 344.0).toDouble();

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    SizedBox(height: topSpacing),
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentWidth),
                        child: Text(
                          'Batas Maksimal\nNatrium Harian',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 35,
                            height: 1.05,
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
                        'assets/illustrations/batasaman.png',
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
                    const SizedBox(height: 10),
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
                              const TextSpan(
                                text: 'Batas natrium harianmu hingga\n',
                              ),
                              TextSpan(
                                text:
                                    '${formatNatriumMg(widget.hasil.batasNatrium)} mg',
                                style: GoogleFonts.plusJakartaSans(
                                  color: _blue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                ),
                              ),
                              const TextSpan(text: ' per hari untuk '),
                              TextSpan(
                                text: 'kondisi normal',
                                style: GoogleFonts.plusJakartaSans(
                                  color: _blue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F4E5),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        'Kebutuhan natrium harian Anda adalah 1800 mg.',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF77B06D),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: FilledButton(
                            onPressed:
                                _isSaving ? null : _handleSaveAndContinue,
                            style: FilledButton.styleFrom(
                              backgroundColor: _blue,
                              disabledBackgroundColor:
                                  const Color(0xFFBEC7DB),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 4,
                              shadowColor: const Color(0x40000000),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
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
              ),
            );
          },
        ),
      ),
    );
  }
}
