import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skenna/presentation/screens/hasil_perbandingan_produk.dart';
import '../navigation/app_routes.dart';
import 'hasil_scan_aman_screen.dart';

class ScanConfirmationSheet extends StatefulWidget {
  final Map<String, dynamic> dataGizi;
  final int userId;
  // ── TAMBAH: jika tidak null → mode perbandingan ──
  final ProductCompareData? compareWithProduct;

  const ScanConfirmationSheet({
    Key? key,
    required this.dataGizi,
    required this.userId,
    this.compareWithProduct, // ← nullable, default null = mode normal
  }) : super(key: key);

  @override
  State<ScanConfirmationSheet> createState() => _ScanConfirmationSheetState();
}

class _ScanConfirmationSheetState extends State<ScanConfirmationSheet> {
  static const _blue = Color(0xFF2C4A8A);
  static const _navy = Color(0xFF213868);

  static TextStyle get _inputTextStyle => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: _blue,
  );

  static TextStyle get _hintStyle =>
      GoogleFonts.plusJakartaSans(fontSize: 14, color: Color(0xFFBEC7DB));

  static InputBorder get _normalBorder => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: Color(0xFFD9D9D9)),
  );

  static InputBorder get _focusedBorder => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: _blue, width: 2),
  );

  static InputDecoration _decoration({
    String? hint,
    String? suffix,
    TextInputType? keyboardType,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: _hintStyle,
    suffixText: suffix,
    suffixStyle: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: _blue,
    ),
    border: _normalBorder,
    enabledBorder: _normalBorder,
    focusedBorder: _focusedBorder,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  );

  late TextEditingController _namaController;
  late TextEditingController _takaranController;
  late TextEditingController _porsiController;
  late TextEditingController _sodiumController;
  String _kategori = 'minuman_kemasan';
  int _jumlahKonsumsi = 1;

  // ── Apakah mode perbandingan? ──
  bool get _isModePerbandingan => widget.compareWithProduct != null;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(
      text: widget.dataGizi['jenis_produk'] ?? '',
    );
    _takaranController = TextEditingController(
      text: '${widget.dataGizi['takaran_saji_angka'] ?? ''}',
    );
    _porsiController = TextEditingController(
      text: '${widget.dataGizi['sajian_per_kemasan'] ?? ''}',
    );
    _sodiumController = TextEditingController(
      text: '${widget.dataGizi['sodium_mg'] ?? ''}',
    );
    _kategori = widget.dataGizi['jenis_produk'] == 'minuman'
        ? 'minuman_kemasan'
        : 'makanan_lainnya';
  }

  @override
  void dispose() {
    _namaController.dispose();
    _takaranController.dispose();
    _porsiController.dispose();
    _sodiumController.dispose();
    super.dispose();
  }

  void _lanjutkan() {
    Navigator.of(context).pop(); // tutup sheet dulu

    if (_isModePerbandingan) {
      // ── MODE PERBANDINGAN ────────────────────────────────────────────
      // Buat ProductCompareData untuk produk B (yang baru di-scan)
      final takaranPerPorsi = int.tryParse(_takaranController.text) ?? 0;
      final porsiPerKemasan = int.tryParse(_porsiController.text) ?? 1;

      final productB = ProductCompareData(
        productName: _namaController.text.isNotEmpty
            ? _namaController.text
            : 'Produk B',
        kategori: _kategori,
        satuanTakaran: _kategori == 'minuman_kemasan' ? 'ml' : 'g',
        perPortionMg: int.tryParse(_sodiumController.text) ?? 0,
        // isi kemasan = takaran per porsi × jumlah porsi
        packageMl: takaranPerPorsi * porsiPerKemasan,
        portionsInPackage: porsiPerKemasan,
      );

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.hasilBandingkan,
        arguments: {
          'productA': widget.compareWithProduct,
          'productB': productB,
        },
      );
    } else {
      // ── MODE NORMAL (scan biasa) ──────────────────────────────────────
      final takaranPerPorsi = int.tryParse(_takaranController.text) ?? 0;
      final porsiPerKemasan = int.tryParse(_porsiController.text) ?? 1;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HasilScanAmanScreen(
            productName: _namaController.text,
            kategori: _kategori,
            perPortionMg: int.tryParse(_sodiumController.text) ?? 0,
            satuanTakaran: _kategori == 'minuman_kemasan' ? 'ml' : 'g',
            packageMl: takaranPerPorsi * porsiPerKemasan, // ← total isi kemasan
            portionsInPackage: porsiPerKemasan,
            initialServings: _jumlahKonsumsi,
            userId: widget.userId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Judul — beda teks tergantung mode ──
            Text(
              _isModePerbandingan
                  ? 'Produk Pembanding'
                  : 'Informasi Label Produk',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _navy,
              ),
            ),
            const SizedBox(height: 4),

            // ── Subtitle — tampilkan nama produk A jika mode perbandingan ──
            Text(
              _isModePerbandingan
                  ? 'Dibandingkan dengan: ${widget.compareWithProduct!.productName}'
                  : 'Periksa & edit jika ada yang kurang tepat',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: _isModePerbandingan ? _blue : const Color(0xFFBEC7DB),
                fontWeight: _isModePerbandingan
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 20),

            // ── Nama produk ─────────────────────
            _buildLabel('Nama Produk'),
            TextField(
              controller: _namaController,
              style: _inputTextStyle,
              decoration: _decoration(hint: 'Masukkan nama produk...'),
            ),
            const SizedBox(height: 14),

            // ── Kategori ────────────────────────
            _buildLabel('Kategori'),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD9D9D9)),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _kategori,
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  focusColor: Colors.transparent,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _blue,
                  ),
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _blue,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'mie', child: Text('Mie Instan')),
                    DropdownMenuItem(value: 'snack', child: Text('Snack')),
                    DropdownMenuItem(
                      value: 'makanan_kaleng',
                      child: Text('Makanan Kaleng'),
                    ),
                    DropdownMenuItem(
                      value: 'saus',
                      child: Text('Saus & Bumbu'),
                    ),
                    DropdownMenuItem(
                      value: 'roti',
                      child: Text('Roti & Bakeri'),
                    ),
                    DropdownMenuItem(
                      value: 'frozen_food',
                      child: Text('Frozen Food'),
                    ),
                    DropdownMenuItem(value: 'sereal', child: Text('Sereal')),
                    DropdownMenuItem(
                      value: 'minuman_kemasan',
                      child: Text('Minuman Kemasan'),
                    ),
                    DropdownMenuItem(
                      value: 'makanan_lainnya',
                      child: Text('Lainnya'),
                    ),
                  ],
                  onChanged: (val) => setState(() => _kategori = val!),
                ),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Takaran per porsi'),
                      TextField(
                        controller: _takaranController,
                        keyboardType: TextInputType.number,
                        style: _inputTextStyle,
                        decoration: _decoration(
                          suffix: _kategori == 'minuman_kemasan' ? 'ml' : 'g',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Porsi per kemasan'),
                      TextField(
                        controller: _porsiController,
                        keyboardType: TextInputType.number,
                        style: _inputTextStyle,
                        decoration: _decoration(suffix: 'porsi'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Natrium ──────────────────────────
            _buildLabel('Jumlah natrium per porsi'),
            TextField(
              controller: _sodiumController,
              keyboardType: TextInputType.number,
              style: _inputTextStyle,
              decoration: _decoration(suffix: 'mg'),
            ),
            const SizedBox(height: 14),

            // ── Jumlah konsumsi — HANYA tampil di mode normal ──
            if (!_isModePerbandingan) ...[
              _buildLabel('Jumlah yang akan dikonsumsi'),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD9D9D9)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _jumlahKonsumsi > 1
                          ? () => setState(() => _jumlahKonsumsi--)
                          : null,
                      icon: const Icon(Icons.remove),
                      color: _blue,
                    ),
                    Expanded(
                      child: Text(
                        '$_jumlahKonsumsi Porsi',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _blue,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _jumlahKonsumsi < 9
                          ? () => setState(() => _jumlahKonsumsi++)
                          : null,
                      icon: const Icon(Icons.add),
                      color: _jumlahKonsumsi < 9 ? _blue : Colors.grey,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ] else
              const SizedBox(height: 24),

            // ── Tombol lanjutkan ─────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _lanjutkan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: Text(
                  _isModePerbandingan ? 'Lihat Perbandingan' : 'Lanjutkan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFFAAAAAA),
      ),
    ),
  );
}
