import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'hasil_perbandingan_produk.dart';
import 'scan_screen.dart';

const String scanOnboardingPreferenceKey = 'has_seen_scan_onboarding';

/// Entry point yang harus dipakai setiap kali aplikasi akan membuka [ScanScreen].
///
/// Gate ini mempertahankan seluruh parameter scan, tetapi menampilkan onboarding
/// terlebih dahulu untuk penggunaan pertama.
class ScanEntryGate extends StatefulWidget {
  const ScanEntryGate({
    super.key,
    required this.apiClient,
    this.compareWithProduct,
    this.historyItemId,
    this.isConsumed = false,
  });

  final dynamic apiClient;
  final ProductCompareData? compareWithProduct;
  final String? historyItemId;
  final bool isConsumed;

  @override
  State<ScanEntryGate> createState() => _ScanEntryGateState();
}

class _ScanEntryGateState extends State<ScanEntryGate> {
  late final Future<bool> _hasSeenOnboarding = _readOnboardingFlag();
  bool _completedInSession = false;

  Future<bool> _readOnboardingFlag() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(scanOnboardingPreferenceKey) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasSeenOnboarding,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF2C4A8A)),
            ),
          );
        }

        if ((snapshot.data ?? false) || _completedInSession) {
          return ScanScreen(
            apiClient: widget.apiClient,
            compareWithProduct: widget.compareWithProduct,
            historyItemId: widget.historyItemId,
            isConsumed: widget.isConsumed,
          );
        }

        return ScanOnboardingScreen(
          onContinue: () {
            if (mounted) setState(() => _completedInSession = true);
          },
        );
      },
    );
  }
}

class ScanOnboardingScreen extends StatefulWidget {
  const ScanOnboardingScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  State<ScanOnboardingScreen> createState() => _ScanOnboardingScreenState();
}

class _ScanOnboardingScreenState extends State<ScanOnboardingScreen> {
  bool _isContinuing = false;

  Future<void> _continueToScan() async {
    if (_isContinuing) return;
    setState(() => _isContinuing = true);

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(scanOnboardingPreferenceKey, true);

    if (mounted) widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF2C4A8A);
    const warningRed = Color(0xFFE53935);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 28,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        'Arahkan Kamera ke Label Gizi',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: navy,
                          fontSize: 27,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.85,
                            maxHeight: constraints.maxHeight * 0.3,
                          ),
                          child: Image.asset(
                            'assets/illustrations/produk.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.plusJakartaSans(
                            color: navy,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                          children: const [
                            TextSpan(text: 'Pastikan '),
                            TextSpan(
                              text:
                                  'Takaran Saji, Jumlah Sajian per Kemasan, dan Garam (Natrium)',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            TextSpan(text: ' terlihat jelas dalam satu foto'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3F3),
                          border: Border.all(
                            color: warningRed.withValues(alpha: 0.65),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: SvgPicture.asset(
                                'assets/icons/mingcute_warning-line.svg',
                                width: 23,
                                height: 23,
                                colorFilter: const ColorFilter.mode(
                                  warningRed,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFFE53935),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    height: 1.45,
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: 'Ketiga informasi tersebut ',
                                    ),
                                    TextSpan(
                                      text:
                                          'harus terlihat jelas dan tidak terpotong',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextSpan(text: ' agar hasil scan akurat'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: 24),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 343),
                        child: Container(
                          width: double.infinity,
                          height: 55,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x26000000),
                                offset: Offset(0, 4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: navy,
                              disabledBackgroundColor: navy.withValues(
                                alpha: 0.6,
                              ),
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            onPressed: _isContinuing ? null : _continueToScan,
                            child: _isContinuing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Mengerti',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w600,
                                      height: 1,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
