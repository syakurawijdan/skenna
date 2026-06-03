import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:skenna/presentation/screens/hasil_perbandingan_produk.dart';
import '../app_shell.dart';
import 'scan_confirmation_sheet.dart';
import 'package:skenna/data/user_session.dart';

class ScanScreen extends StatefulWidget {
  final dynamic apiClient;
  final ProductCompareData? compareWithProduct;

  const ScanScreen({Key? key, required this.apiClient, this.compareWithProduct})
    : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isLoading = false;
  bool _isProcessing = false;
  bool _isFlashOn = false;

  final String _geminiApiKey = "AIzaSyCWeDw70gMunk_be8IylR2uDhZgGX_E1_4";

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;
    setState(() => _isFlashOn = !_isFlashOn);
    await _cameraController!.setFlashMode(
      _isFlashOn ? FlashMode.torch : FlashMode.off,
    );
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint("Gagal buka kamera: $e");
    }
  }

  Future<void> _captureAndScan() async {
    final mockData = {
      "jenis_produk": "makanan",
      "satuan_takaran": "g",
      "isi_kemasan_angka": 180,
      "isi_kemasan_satuan": "g",
      "takaran_saji_angka": 20,
      "sajian_per_kemasan": 9,
      "sodium_mg": 60,
    };
    await _showResultDialog(mockData);
    return;

    if (_isProcessing ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized)
      return;

    setState(() {
      _isProcessing = true;
      _isLoading = true;
    });

    try {
      await _cameraController!.pausePreview();

      final XFile image = await _cameraController!.takePicture();
      final imageBytes = await File(image.path).readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final String promptText = '''
Anda adalah sistem OCR pemindai label nilai gizi produk makanan/minuman kemasan.
Analisis gambar label nilai gizi dan ekstrak data berikut secara akurat.
Respons WAJIB hanya raw JSON tanpa Markdown backticks, tanpa penjelasan apapun.

{
  "jenis_produk": "makanan" atau "minuman",
  "satuan_takaran": "g" atau "ml",
  "isi_kemasan_angka": 85,
  "isi_kemasan_satuan": "g" atau "ml",
  "takaran_saji_angka": 85,
  "sajian_per_kemasan": 1,
  "sodium_mg": 890
}

ATURAN WAJIB:
1. sodium_mg SELALU dalam miligram (mg).
   Jika label tulis gram (g), kalikan 1000. Contoh: 0.3g → 300
2. Jika produk minuman → satuan_takaran "ml", jika makanan padat → "g"
3. sajian_per_kemasan: jika tidak tertulis, hitung isi_kemasan dibagi 
   takaran_saji, bulatkan ke bawah
4. Semua nilai angka harus NUMBER bukan string
5. Jika ada info yang tidak terbaca, isi dengan null
''';

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_geminiApiKey',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": promptText},
                {
                  "inline_data": {
                    "mime_type": "image/jpeg",
                    "data": base64Image,
                  },
                },
              ],
            },
          ],
          "generationConfig": {"temperature": 0.1, "maxOutputTokens": 1024},
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final text =
            decoded['candidates'][0]['content']['parts'][0]['text'] as String;

        // ✅ TAMBAH DI SINI
        debugPrint("=== RAW GEMINI RESPONSE ===");
        debugPrint(text);
        debugPrint("===========================");

        final cleanText = text
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        debugPrint("=== CLEAN TEXT ===");
        debugPrint(cleanText);
        debugPrint("==================");

        final Map<String, dynamic> dataGizi = jsonDecode(cleanText);
        _showResultDialog(dataGizi);
      } else {
        debugPrint("API Error ${response.statusCode}: ${response.body}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "API Error ${response.statusCode}: ${jsonDecode(response.body)['error']['message']}",
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error detail: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal scan: $e")));
      }
    } finally {
      if (mounted) {
        await _cameraController!.resumePreview();
        setState(() {
          _isProcessing = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showResultDialog(Map<String, dynamic> data) async {
    final currentUserId = UserSession().getUserId();

    // Matikan kamera dulu
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      await _cameraController!.pausePreview();
      await _cameraController!.dispose();
      _cameraController = null;
      if (mounted) setState(() => _isCameraInitialized = false);
    }

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScanConfirmationSheet(
        dataGizi: data,
        userId: currentUserId,
        compareWithProduct: widget.compareWithProduct,
      ),
    );

    // Kalau user dismiss sheet tanpa lanjut, resume kamera
    if (mounted) {
      await _initializeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final scanBoxWidth = screenWidth * 0.80;
    final scanBoxHeight = screenHeight * 0.55;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Kamera full screen
          if (_isCameraInitialized)
            CameraPreview(_cameraController!)
          else
            const ColoredBox(color: Colors.black),

          // ── Overlay gelap dengan lubang kotak portrait di tengah
          Positioned.fill(
            child: CustomPaint(
              painter: _ScanOverlayPainter(
                scanBoxWidth: scanBoxWidth,
                scanBoxHeight: scanBoxHeight,
              ),
            ),
          ),

          // ── Sudut kotak scan
          Center(
            child: SizedBox(
              width: scanBoxWidth,
              height: scanBoxHeight,
              child: Stack(
                children: [
                  Positioned(top: 0, left: 0, child: _Corner()),
                  Positioned(top: 0, right: 0, child: _Corner(flipX: true)),
                  Positioned(bottom: 0, left: 0, child: _Corner(flipY: true)),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _Corner(flipX: true, flipY: true),
                  ),
                ],
              ),
            ),
          ),

          // ── Teks instruksi
          Center(
            child: Padding(
              padding: EdgeInsets.only(top: scanBoxHeight / 2 + 24),
              child: Text(
                'Arahkan ke label nilai gizi',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // ── Safe area UI
          SafeArea(
            child: Stack(
              children: [
                // ── Top bar
                Positioned(
                  top: 36,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tombol back
                      GestureDetector(
                        onTap: () => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const AppShell()),
                          (route) => false,
                        ),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 18,
                            color: Color(0xFF2C4A8A),
                          ),
                        ),
                      ),

                      // Judul
                      Text(
                        'Scanner',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),

                      // Tombol flash
                      GestureDetector(
                        onTap: _toggleFlash,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isFlashOn ? Icons.flash_on : Icons.flash_off,
                            size: 20,
                            color: const Color(0xFF2C4A8A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Tombol capture bawah
                Positioned(
                  bottom: 36,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : GestureDetector(
                            onTap: _captureAndScan,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.30),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose(); // ← sudah pakai ?. jadi aman
    super.dispose();
  }
}

// ── Overlay gelap dengan lubang kotak portrait di tengah ──
class _ScanOverlayPainter extends CustomPainter {
  final double scanBoxWidth;
  final double scanBoxHeight;

  _ScanOverlayPainter({
    required this.scanBoxWidth,
    required this.scanBoxHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.55);
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCenter(
      center: center,
      width: scanBoxWidth,
      height: scanBoxHeight,
    );

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(24)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Widget sudut kotak scan ──
class _Corner extends StatelessWidget {
  final bool flipX;
  final bool flipY;

  const _Corner({this.flipX = false, this.flipY = false});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleX: flipX ? -1 : 1,
      scaleY: flipY ? -1 : 1,
      child: SizedBox(
        width: 28,
        height: 28,
        child: CustomPaint(painter: _CornerPainter()),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, 8)
      ..arcToPoint(
        const Offset(10, 0),
        radius: const Radius.circular(10),
        clockwise: true,
      )
      ..lineTo(size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
