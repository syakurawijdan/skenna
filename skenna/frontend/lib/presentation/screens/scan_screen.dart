import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skenna/presentation/screens/hasil_perbandingan_produk.dart';
import '../app_shell.dart';
import 'scan_confirmation_sheet.dart';
import 'package:skenna/data/user_session.dart';
import 'dart:typed_data';
import '../../data/api_client.dart';
import '../navigation/app_routes.dart';
import 'package:flutter/foundation.dart';
import 'package:skenna/presentation/widgets/ScanFailedDialog.dart';
import 'package:skenna/presentation/widgets/NoInternetDialog.dart';
import 'package:path_provider/path_provider.dart';

class ScanScreen extends StatefulWidget {
  final dynamic apiClient;
  final ProductCompareData? compareWithProduct;
  final String? historyItemId;
  final bool isConsumed;

  const ScanScreen({
    Key? key,
    required this.apiClient,
    this.compareWithProduct,
    this.historyItemId,
    this.isConsumed = false,
  }) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isLoading = false;
  bool _isProcessing = false;
  bool _isFlashOn = false;
  Uint8List? _frozenFrame;

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

    final controller = CameraController(
      cameras.first,
      // Naikkan detail capture agar teks label lebih tajam.
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await controller.initialize();
      if (mounted) {
        _cameraController = controller;
        setState(() => _isCameraInitialized = true);
      } else {
        // Widget sudah unmount sebelum init selesai, langsung dispose
        await controller.dispose();
      }
    } catch (e) {
      debugPrint("Gagal buka kamera: $e");
      await controller.dispose();
    }
  }

  Future<void> _captureAndScan() async {
    if (_isProcessing ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized)
      return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isProcessing = true;
      _isLoading = true;
    });

    File? compressedImageFile;
    try {
      final XFile image = await _cameraController!.takePicture();
      final bytes = await File(image.path).readAsBytes();

      if (mounted) setState(() => _frozenFrame = bytes);

      final results = await Future.wait([
        _disposeCamera().then((_) => Uint8List(0)),
        compute(_compressImageIsolate, bytes),
      ]);
      final compressedBytes = results[1];

      final temporaryDirectory = await getTemporaryDirectory();
      compressedImageFile = File(
        '${temporaryDirectory.path}${Platform.pathSeparator}'
        'skenna_scan_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      // Simpan hasil kompresi dan kirim file ini, bukan foto kamera berukuran besar.
      await compressedImageFile.writeAsBytes(compressedBytes, flush: true);

      final result = await widget.apiClient.scanLabel(compressedImageFile.path);

      // ── Validasi hasil OCR ──
      final takaranSaji = result['takaran_saji'];
      final sajianPerKemasan = result['sajian_per_kemasan'];
      final sodiumMg = result['sodium_mg'];

      final bool ocrTotalGagal =
          takaranSaji == null && sajianPerKemasan == null;

      if (ocrTotalGagal) {
        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const ScanFailedDialog(),
          );
          if (mounted) {
            setState(() => _frozenFrame = null);
            await _initializeCamera();
          }
        }
        return;
      }

      final dataGizi = {
        "nama_produk": result['nama_produk'] ?? result['product_name'] ?? "",
        "satuan_takaran": result['satuan_takaran'] ?? "g",
        "takaran_saji_angka": takaranSaji != null
            ? (takaranSaji as num).toDouble()
            : null,
        "sajian_per_kemasan": sajianPerKemasan != null
            ? (sajianPerKemasan as num).toDouble()
            : null,
        "sodium_mg": sodiumMg != null ? (sodiumMg as num).toDouble() : 0.0,
        "image_path": result['image_path'] as String?,
        "scan_id": result['scan_id'],
      };

      await _showResultSheetAfterDispose(dataGizi);
    } on SocketException catch (_) {
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const NoInternetDialog(),
        );
        if (mounted) {
          setState(() => _frozenFrame = null);
          await _initializeCamera();
        }
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401 && mounted) {
        await ApiClient.clearLocalSession();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi kamu telah berakhir, silakan login ulang.'),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal scan: $e")));
      }
    } catch (e) {
      debugPrint("Error detail: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal scan: $e")));
      }
    } finally {
      // File upload hanya dibutuhkan selama request; hapus agar cache tidak menumpuk.
      try {
        if (compressedImageFile != null && await compressedImageFile.exists()) {
          await compressedImageFile.delete();
        }
      } catch (e) {
        debugPrint('Gagal menghapus file scan sementara: $e');
      }
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showResultSheetAfterDispose(Map<String, dynamic> data) async {
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScanConfirmationSheet(
        dataGizi: data,
        userId: UserSession().getUserId(),
        apiClient: widget.apiClient,
        compareWithProduct: widget.compareWithProduct,
        historyItemId: widget.historyItemId,
        isConsumed: widget.isConsumed,
      ),
    );

    // Sheet ditutup — reinit kamera jika masih mounted
    if (mounted) {
      setState(() => _frozenFrame = null);
      await _initializeCamera();
    }
  }

  Future<void> _disposeCamera() async {
    final controller = _cameraController;
    _cameraController = null;
    _isFlashOn = false; // reset flag supaya sinkron dengan hardware
    if (mounted) setState(() => _isCameraInitialized = false);

    if (controller != null && controller.value.isInitialized) {
      try {
        await controller.setFlashMode(FlashMode.off); //
      } catch (_) {}
      await controller.dispose();
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
          if (_frozenFrame != null)
            Image.memory(
              _frozenFrame!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            )
          else if (_isCameraInitialized &&
              _cameraController != null &&
              _cameraController!.value.isInitialized)
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
                      GestureDetector(
                        onTap: () => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const AppShell()),
                          (route) => false,
                        ),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDFE4ED),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            size: 20,
                            color: Color(0xFF2C4A8A),
                          ),
                        ),
                      ),
                      Text(
                        'Scanner',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: _toggleFlash,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDFE4ED),
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
                        : InkWell(
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
    // Matikan flash sebelum dispose supaya tidak "nyangkut" di hardware
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        _cameraController!.setFlashMode(FlashMode.off);
      } catch (_) {}
    }
    _cameraController?.dispose();
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

Uint8List _compressImageIsolate(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;

  // Jaga detail OCR dengan sisi terpanjang sebesar 1280 px.
  final resized = decoded.width > decoded.height
      ? img.copyResize(decoded, width: 1280)
      : img.copyResize(decoded, height: 1280);

  // Quality 85 menyeimbangkan ukuran upload dan ketajaman teks.
  return img.encodeJpg(resized, quality: 85);
}
