import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/natrium_classifier.dart';
import '../../domain/profile_save_service.dart';
import '../app_shell.dart';

class SodiumResultScreen extends StatefulWidget {
  const SodiumResultScreen({
    super.key,
    required this.categoryKey,
    required this.hasil,
    this.dailyLimitMg,
  });

  final String categoryKey;
  final HasilKlasifikasi hasil;
  final int? dailyLimitMg;

  @override
  State<SodiumResultScreen> createState() => _SodiumResultScreenState();
}

class _SodiumResultScreenState extends State<SodiumResultScreen> {
  static const _blue = Color(0xFF2C4A8A);
  static const _green = Color(0xFF77B06D);
  static const _yellow = Color(0xFFD5A400);
  static const _red = Color(0xFFE53935);
  static const _greenBox = Color(0xFFE8F4E5);
  static const _yellowBox = Color(0xFFFFF2D7);
  static const _redBox = Color(0xFFFFEBEE);

  final ProfileSaveService _saveService = ProfileSaveService();
  late final Future<_UiRules> _rulesFuture;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _rulesFuture = _UiRules.loadFromAsset();
  }

  Future<void> _handleSaveAndContinue() async {
    setState(() => _isSaving = true);

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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_UiRules>(
      future: _rulesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator(color: _blue)),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: Text('Konfigurasi tampilan tidak tersedia')),
          );
        }

        final rules = snapshot.data!;
        final entry = rules.category(widget.categoryKey);
        if (entry == null) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: Text('Kategori natrium tidak tersedia')),
          );
        }

        return _buildContent(context, rules, entry);
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    _UiRules rules,
    _UiCategory entry,
  ) {
    final warna = entry.warna;
    final imageAsset = _imageForColor(warna);
    final boxText = _boxText(entry.box);
    final deskripsi = entry.deskripsi;

    return Scaffold(
      backgroundColor: Colors.white,
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
                          _breakHeader(entry.header),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 33,
                            height: 1.12,
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
                        imageAsset,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                    ),
                    SizedBox(height: sectionSpacing),
                    Text(
                      '${formatNatriumMg(widget.hasil.batasNatrium)} mg',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 54,
                        fontWeight: FontWeight.w800,
                        color: _blue,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (deskripsi != null)
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: contentWidth),
                          child: _buildRichText(
                            deskripsi.template,
                            deskripsi.templateBoldSpans,
                            fontSize: 14,
                            color: _blue,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    if (boxText != null) ...[
                      const SizedBox(height: 12),
                      _InfoBox(
                        text: boxText,
                        boldSpans:
                            entry.box?.boldSpans.map(_substitute).toList() ??
                            [],
                        warna: warna,
                      ),
                    ],
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: FilledButton(
                          onPressed: _isSaving ? null : _handleSaveAndContinue,
                          style: FilledButton.styleFrom(
                            backgroundColor: _blue,
                            disabledBackgroundColor: const Color(0xFFBEC7DB),
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
                                  rules.buttonText,
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
                          rules.footerText,
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

  String? _boxText(_UiBox? box) {
    if (box == null) return null;
    if (box.tipe == 'esc' &&
        (widget.hasil.sistolik == null || widget.hasil.diastolik == null)) {
      return null;
    }
    final template = _substitute(box.template);
    final boldParts = box.boldSpans.map(_substitute).join();
    return '$template$boldParts';
  }

  /// Renders [text] as a RichText where substrings in [boldSpans]
  /// (after placeholder substitution) are FontWeight.w700,
  /// everything else is FontWeight.w500.
  Widget _buildRichText(
    String text,
    List<String> boldSpans, {
    required double fontSize,
    required Color color,
    required TextAlign textAlign,
    double height = 1.35,
  }) {
    final resolved = _substitute(text);
    final resolvedBolds = boldSpans.map(_substitute).toList();

    return _buildTemplateText(
      text: resolved,
      boldSpans: resolvedBolds,
      textAlign: textAlign,
      style: GoogleFonts.plusJakartaSans(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        height: height,
      ),
    );
  }

  String _substitute(String value) {
    final akgValue = widget.hasil.akgReferenceMg ?? widget.hasil.batasNatrium;
    return value
        .replaceAll('{nilai}', formatNatriumMg(widget.hasil.batasNatrium))
        .replaceAll('{akg_value}', formatNatriumMg(akgValue))
        .replaceAll('{esc_kategori}', widget.hasil.escKategori ?? '')
        .replaceAll('{sistol}', widget.hasil.sistolik?.toString() ?? '')
        .replaceAll('{diastol}', widget.hasil.diastolik?.toString() ?? '');
  }

  String _breakHeader(String value) {
    if (value.length <= 24 || value.contains('\n')) return value;
    final words = value.split(' ');
    final midpoint = (words.length / 2).ceil();
    return '${words.take(midpoint).join(' ')}\n${words.skip(midpoint).join(' ')}';
  }

  static String _imageForColor(String warna) {
    switch (warna) {
      case 'kuning':
        return 'assets/illustrations/batashamil.png';
      case 'merah':
        return 'assets/illustrations/batasketat.png';
      case 'hijau':
      default:
        return 'assets/illustrations/batasaman.png';
    }
  }

  static Color boxBackground(String warna) {
    switch (warna) {
      case 'kuning':
        return _yellowBox;
      case 'merah':
        return _redBox;
      case 'hijau':
      default:
        return _greenBox;
    }
  }

  static Color boxForeground(String warna) {
    switch (warna) {
      case 'kuning':
        return _yellow;
      case 'merah':
        return _red;
      case 'hijau':
      default:
        return _green;
    }
  }
}

String formatNatriumMg(int mg) {
  // Use dot as thousands separator (Indonesian convention)
  if (mg >= 1000) {
    final thousands = mg ~/ 1000;
    final remainder = mg % 1000;
    if (remainder == 0) return '$thousands.000';
    return '$thousands.${remainder.toString().padLeft(3, '0')}';
  }
  return mg.toString();
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.text,
    required this.boldSpans,
    required this.warna,
  });

  final String text;
  final List<String> boldSpans;
  final String warna;

  @override
  Widget build(BuildContext context) {
    final baseStyle = GoogleFonts.plusJakartaSans(
      color: _SodiumResultScreenState.boxForeground(warna),
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.25,
    );

    final content = _buildTemplateText(
      text: text,
      boldSpans: boldSpans,
      textAlign: TextAlign.center,
      style: baseStyle,
    );

    return Container(
      constraints: const BoxConstraints(maxWidth: 344),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: _SodiumResultScreenState.boxBackground(warna),
        borderRadius: BorderRadius.circular(18),
      ),
      child: content,
    );
  }
}

class _UiRules {
  const _UiRules({
    required this.footerText,
    required this.buttonText,
    required this.kategori,
  });

  final String footerText;
  final String buttonText;
  final Map<String, _UiCategory> kategori;

  static Future<_UiRules> loadFromAsset() async {
    final jsonText = await rootBundle.loadString('assets/rules/ui_rules.json');
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Format ui_rules.json tidak valid');
    }

    final shared = Map<String, dynamic>.from(decoded['shared'] as Map);
    final rawKategori = Map<String, dynamic>.from(decoded['kategori'] as Map);
    return _UiRules(
      footerText: shared['footer_text'] as String? ?? '',
      buttonText: shared['button_text'] as String? ?? 'Mulai',
      kategori: rawKategori.map(
        (key, value) => MapEntry(
          key,
          _UiCategory.fromJson(Map<String, dynamic>.from(value as Map)),
        ),
      ),
    );
  }

  _UiCategory? category(String key) => kategori[key];
}

class _UiCategory {
  const _UiCategory({
    required this.header,
    required this.warna,
    required this.deskripsi,
    required this.box,
  });

  final String header;
  final String warna;
  final _UiTemplate? deskripsi;
  final _UiBox? box;

  factory _UiCategory.fromJson(Map<String, dynamic> json) {
    final rawDeskripsi = json['deskripsi'];
    final rawBox = json['box'];
    return _UiCategory(
      header: json['header'] as String? ?? '',
      warna: json['warna'] as String? ?? 'hijau',
      deskripsi: rawDeskripsi is Map
          ? _UiTemplate.fromJson(Map<String, dynamic>.from(rawDeskripsi))
          : null,
      box: rawBox is Map
          ? _UiBox.fromJson(Map<String, dynamic>.from(rawBox))
          : null,
    );
  }
}

class _UiTemplate {
  const _UiTemplate({
    required this.template,
    required this.templateBoldSpans,
  });

  final String template;
  final List<String> templateBoldSpans;

  factory _UiTemplate.fromJson(Map<String, dynamic> json) {
    final rawBoldSpans = json['template_bold_spans'];
    return _UiTemplate(
      template: json['template'] as String? ?? '',
      templateBoldSpans: rawBoldSpans is List
          ? rawBoldSpans.whereType<String>().toList()
          : const [],
    );
  }
}

class _UiBox {
  const _UiBox({
    required this.tipe,
    required this.template,
    required this.boldSpans,
  });

  final String tipe;
  final String template;
  final List<String> boldSpans;

  factory _UiBox.fromJson(Map<String, dynamic> json) {
    final template = _UiTemplate.fromJson(json);
    return _UiBox(
      tipe: json['tipe'] as String? ?? '',
      template: template.template,
      boldSpans: template.templateBoldSpans,
    );
  }
}

Widget _buildTemplateText({
  required String text,
  required List<String> boldSpans,
  required TextAlign textAlign,
  required TextStyle style,
}) {
  final nonEmptyBoldSpans = boldSpans.where((span) => span.isNotEmpty).toList();
  if (nonEmptyBoldSpans.isEmpty) {
    return Text(text, textAlign: textAlign, style: style);
  }

  final spans = <TextSpan>[];
  var cursor = 0;
  while (cursor < text.length) {
    var earliestStart = text.length;
    String? matchedBold;
    for (final bold in nonEmptyBoldSpans) {
      final index = text.indexOf(bold, cursor);
      if (index != -1 && index < earliestStart) {
        earliestStart = index;
        matchedBold = bold;
      }
    }
    if (matchedBold == null) {
      spans.add(TextSpan(text: text.substring(cursor)));
      break;
    }
    if (earliestStart > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, earliestStart)));
    }
    spans.add(
      TextSpan(
        text: matchedBold,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
    cursor = earliestStart + matchedBold.length;
  }

  return RichText(
    textAlign: textAlign,
    text: TextSpan(style: style, children: spans),
  );
}
