import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skenna/presentation/screens/hasil_perbandingan_produk.dart';
import '../navigation/app_routes.dart';
import '../widgets/custom_dropdown.dart';
import 'hasil_scan_aman_screen.dart';
import '../../domain/natrium_classifier.dart';

String _sodiumLevelLabel(KategoriNatrium kategori) {
  switch (kategori) {
    case KategoriNatrium.hijau:
      return 'low';
    case KategoriNatrium.kuning:
      return 'medium';
    case KategoriNatrium.merah:
      return 'high';
  }
}

class ScanConfirmationSheet extends StatefulWidget {
  final Map<String, dynamic> dataGizi;
  final int userId;
  final dynamic apiClient;
  final ProductCompareData? compareWithProduct;

  const ScanConfirmationSheet({
    Key? key,
    required this.dataGizi,
    required this.userId,
    required this.apiClient,
    this.compareWithProduct,
  }) : super(key: key);

  @override
  State<ScanConfirmationSheet> createState() => _ScanConfirmationSheetState();
}

class _ScanConfirmationSheetState extends State<ScanConfirmationSheet> {
  static const _blue = Color(0xFF2C4A8A);
  static const _navy = Color(0xFF213868);
  static const _categoryItems = [
    DropdownItem(value: 'mie_instan', label: 'Mie & Pasta Instan'),
    DropdownItem(value: 'keripik_snack', label: 'Snack & Keripik'),
    DropdownItem(value: 'makanan_kaleng', label: 'Makanan Kaleng'),
    DropdownItem(value: 'biskuit_roti', label: 'Roti'),
    DropdownItem(value: 'frozen_food', label: 'Frozen Food'),
    DropdownItem(value: 'sereal', label: 'Sereal & Oatmeal'),
    DropdownItem(value: 'biskuit', label: 'Biskuit & Wafer'),
    DropdownItem(value: 'susu', label: 'Susu & Produk Susu'),
    DropdownItem(value: 'minuman_kemasan', label: 'Minuman Kemasan'),
    DropdownItem(value: 'saus_bumbu', label: 'Saus & Bumbu'),
    DropdownItem(value: 'lainnya', label: 'Lainnya'),
  ];

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
    borderSide: const BorderSide(color: _blue, width: 1),
  );

  static InputBorder get _errorBorder => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Colors.red),
  );

  static InputDecoration _decoration({String? hint, String? suffix}) =>
      InputDecoration(
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      );

  late TextEditingController _namaController;
  late TextEditingController _takaranController;
  late TextEditingController _porsiController;
  late TextEditingController _sodiumController;
  String _kategori = '';
  double _jumlahKonsumsi = 1.0;
  bool _namaError = false;
  bool _sodiumError = false;
  bool _takaranError = false;
  bool _porsiError = false;

  // ── Apakah mode perbandingan? ──
  bool get _isModePerbandingan => widget.compareWithProduct != null;

  bool get _isBumbuCategory => _kategori == 'saus_bumbu';

  double? _parseIndoDouble(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    return double.tryParse(text.trim().replaceAll(',', '.'));
  }

  int? _parseIndoInt(String? text) {
    final parsed = _parseIndoDouble(text);
    return parsed?.toInt();
  }

  String _formatIndoNumber(dynamic value) {
    if (value == null) return '';
    final parsed = value is num
        ? value.toDouble()
        : double.tryParse(value.toString().trim().replaceAll(',', '.'));
    if (parsed == null) return '';
    if (parsed == parsed.roundToDouble()) return parsed.toInt().toString();
    return parsed.toString().replaceAll('.', ',');
  }

  bool get _formValid =>
      _namaController.text.trim().isNotEmpty &&
      _sodiumController.text.trim().isNotEmpty &&
      _kategori.isNotEmpty &&
      (_parseIndoDouble(_takaranController.text) ?? 0) > 0 &&
      (_parseIndoDouble(_porsiController.text) ?? 0) > 0;

  @override
  void initState() {
    super.initState();
    final initialKategori =
        '${widget.dataGizi['kategori'] ?? widget.dataGizi['category'] ?? ''}';
    if (_categoryItems.any((item) => item.value == initialKategori)) {
      _kategori = initialKategori;
    }
    _namaController = TextEditingController(
      text: widget.dataGizi['nama_produk'] ?? '',
    );
    _takaranController = TextEditingController(
      text: _formatIndoNumber(widget.dataGizi['takaran_saji_angka']),
    );
    _porsiController = TextEditingController(
      text: _formatIndoNumber(widget.dataGizi['sajian_per_kemasan']),
    );
    _sodiumController = TextEditingController(
      text: '${widget.dataGizi['sodium_mg'] ?? ''}',
    );
    _namaController.addListener(() => setState(() {}));
    _sodiumController.addListener(() => setState(() {}));
    _takaranController.addListener(() => setState(() {}));
    _porsiController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _namaController.dispose();
    _takaranController.dispose();
    _porsiController.dispose();
    _sodiumController.dispose();
    super.dispose();
  }

  Future<void> _lanjutkan() async {
    setState(() {
      _namaError = _namaController.text.trim().isEmpty;
      _sodiumError = _sodiumController.text.trim().isEmpty;
      _takaranError = (_parseIndoDouble(_takaranController.text) ?? 0) <= 0;
      _porsiError = (_parseIndoDouble(_porsiController.text) ?? 0) <= 0;
    });

    if (_namaError || _sodiumError || _takaranError || _porsiError) return;

    final scanId = widget.dataGizi['scan_id'] as int?;
    if (scanId != null) {
      try {
        await widget.apiClient.updateScan(
          scanId: scanId,
          namaProduk: _namaController.text,
          kategori: _kategori,
        );
      } catch (e) {
        debugPrint('=== UPDATE SCAN ERROR: $e');
      }
    }

    // ── Ambil daily limit user ──
    int dailyLimit = 2000; // ← deklarasi di sini
    bool isHardMaximum = true;
    String sodiumLevelLabel = 'medium';
    try {
      final profile = await widget.apiClient.getUserProfile(widget.userId);
      final birthDateStr = profile['birth_date'] as String?;
      if (birthDateStr != null) {
        final hasil = await klasifikasiNatriumDariDraft(
          birthDate: DateTime.parse(birthDateStr),
          gender: profile['gender'] as String? ?? '',
          hasHypertension: profile['has_hypertension'] as bool? ?? false,
          hypertensionCondition: profile['hypertension_condition'] as String?,
          systolicPressure: profile['systolic_pressure'] as int?,
          diastolicPressure: profile['diastolic_pressure'] as int?,
          pregnancyStatus: profile['pregnancy_status'] as String?,
        );
        dailyLimit = hasil.batasNatrium;
        isHardMaximum = hasil.isHardMaximum;
        sodiumLevelLabel = _sodiumLevelLabel(hasil.kategori);
      }
    } catch (e) {
      debugPrint('Gagal fetch daily limit: $e');
    }

    Navigator.of(context).pop();

    final takaranPerPorsi = _parseIndoDouble(_takaranController.text) ?? 0.0;
    final porsiPerKemasan = _parseIndoDouble(_porsiController.text) ?? 1.0;

    if (_isModePerbandingan) {
      final productB = ProductCompareData(
        productName: _namaController.text.isNotEmpty
            ? _namaController.text
            : 'Produk B',
        kategori: _kategori,
        satuanTakaran: _kategori == 'minuman_kemasan' ? 'ml' : 'g',
        perPortionMg: _parseIndoDouble(_sodiumController.text)?.toInt() ?? 0,
        packageMl: takaranPerPorsi * porsiPerKemasan,
        portionsInPackage: porsiPerKemasan,
        imagePath: widget.dataGizi['image_path'] as String?,
      );

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.hasilBandingkan,
        arguments: {
          'productA': widget.compareWithProduct,
          'productB': productB,
          'originalProduct': widget.compareWithProduct,
        },
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HasilScanAmanScreen(
            productName: _namaController.text,
            kategori: _kategori,
            perPortionMg:
                _parseIndoDouble(_sodiumController.text)?.toInt() ?? 0,
            dailyLimitMg: dailyLimit, // ← sudah terisi
            isHardMaximum: isHardMaximum,
            sodiumLevel: sodiumLevelLabel,
            satuanTakaran:
                (widget.dataGizi['satuan_takaran'] as String?)?.isNotEmpty ==
                    true
                ? widget.dataGizi['satuan_takaran'] as String
                : (_kategori == 'minuman_kemasan' ? 'ml' : 'g'),
            packageMl: takaranPerPorsi * porsiPerKemasan,
            portionsInPackage: porsiPerKemasan,
            initialServings: _jumlahKonsumsi.toDouble(),
            userId: widget.userId,
            apiClient: widget.apiClient,
            imagePath: widget.dataGizi['image_path'] as String?,
            scanId: widget.dataGizi['scan_id'] as int?,
          ),
        ),
      );
    }
  }

  String _categoryLabel(String value) {
    for (final item in _categoryItems) {
      if (item.value == value) return item.label;
    }
    return 'Pilih kategori';
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

            // ── Judul ──
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

            // ── Nama produk ──
            _buildLabel('Nama Produk'),
            TextField(
              controller: _namaController,
              style: _inputTextStyle,
              decoration: _decoration(hint: 'Masukkan nama produk').copyWith(
                enabledBorder: _namaError ? _errorBorder : _normalBorder,
                errorText: _namaError ? 'Nama produk wajib diisi' : null,
              ),
              onChanged: (_) => setState(() => _namaError = false),
            ),
            const SizedBox(height: 14),

            // ── Kategori ──
            _buildLabel('Kategori'),
            CustomDropdownField(
              value: _categoryLabel(_kategori),
              placeholder: 'Pilih kategori',
              textAlign: TextAlign.left,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              onTap: () async {
                final selected = await showCustomDropdown<String>(
                  context: context,
                  title: 'Pilih Kategori Produk',
                  items: _categoryItems,
                  selectedValue: _kategori,
                );
                if (selected == null) return;
                setState(() {
                  _kategori = selected;
                  if (_isBumbuCategory) _jumlahKonsumsi = 1.0;
                });
              },
            ),
            const SizedBox(height: 14),

            // ── Takaran & Porsi ──
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Takaran per sajian'),
                      TextField(
                        controller: _takaranController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: _inputTextStyle,
                        decoration:
                            _decoration(
                              suffix: _kategori == 'minuman_kemasan'
                                  ? 'ml'
                                  : 'g',
                            ).copyWith(
                              enabledBorder: _takaranError
                                  ? _errorBorder
                                  : _normalBorder,
                              errorText: _takaranError ? 'Wajib diisi' : null,
                            ),
                        onChanged: (_) => setState(() => _takaranError = false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Sajian per kemasan'),
                      TextField(
                        controller: _porsiController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: _inputTextStyle,
                        decoration: _decoration(suffix: 'sajian').copyWith(
                          hintText: 'contoh: 9',
                          enabledBorder: _porsiError
                              ? _errorBorder
                              : _normalBorder,
                          errorText: _porsiError ? 'Wajib diisi' : null,
                        ),
                        onChanged: (_) => setState(() => _porsiError = false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Natrium ──
            _buildLabel('Jumlah natrium per sajian'),
            TextField(
              controller: _sodiumController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: _inputTextStyle,
              decoration: _decoration(suffix: 'mg').copyWith(
                enabledBorder: _sodiumError ? _errorBorder : _normalBorder,
                errorText: _sodiumError ? 'Natrium wajib diisi' : null,
              ),
              onChanged: (_) => setState(() => _sodiumError = false),
            ),
            if (!_isBumbuCategory) ...[
              const SizedBox(height: 14),
              // ← TAMBAH header di atas preview box
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Estimasi Total Natrium',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _blue,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDFE4ED),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '= ${((_parseIndoDouble(_sodiumController.text) ?? 0) * _jumlahKonsumsi).round()} mg natrium',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: _blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            if (!_isModePerbandingan && !_isBumbuCategory) ...[
              _buildLabel('Berapa sajian yang kamu konsumsi?'),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD9D9D9)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _jumlahKonsumsi > 0.5
                          ? () => setState(() => _jumlahKonsumsi -= 0.5)
                          : null,
                      icon: const Icon(Icons.remove),
                      color: _blue,
                    ),
                    Expanded(
                      child: Text(
                        '${_formatIndoNumber(_jumlahKonsumsi)} Sajian',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _blue,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _jumlahKonsumsi < 10
                          ? () => setState(() => _jumlahKonsumsi += 0.5)
                          : null,
                      icon: const Icon(Icons.add),
                      color: _jumlahKonsumsi < 9.5 ? _blue : Colors.grey,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ] else
              const SizedBox(height: 24),

            // ── Tombol lanjutkan ──
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _formValid ? _lanjutkan : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  disabledBackgroundColor: const Color(0xFFBEC7DB),
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
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: const Color(0xFFAAAAAA),
      ),
    ),
  );
}
