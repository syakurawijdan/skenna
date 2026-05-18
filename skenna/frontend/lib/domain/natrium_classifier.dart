// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum KategoriNatrium { hijau, kuning, merah }

@immutable
class HasilKlasifikasi {
  const HasilKlasifikasi({
    required this.batasNatrium,
    required this.kategori,
    required this.hamilDenganHT,
  });

  final int batasNatrium;
  final KategoriNatrium kategori;
  final bool hamilDenganHT;
}

class SodiumRuleBook {
  const SodiumRuleBook._({required this.raw});

  final Map<String, dynamic> raw;

  static Future<SodiumRuleBook> loadFromAsset() async {
    final jsonText = await rootBundle.loadString(
      'assets/rules/sodium_rules.json',
    );
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Format sodium_rules.json tidak valid');
    }
    return SodiumRuleBook._(raw: decoded);
  }

  int _intValue(List<String> path, {required int fallback}) {
    dynamic current = raw;
    for (final key in path) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        return fallback;
      }
    }
    if (current is int) return current;
    if (current is num) return current.toInt();
    return fallback;
  }

  List<dynamic> _listValue(List<String> path) {
    dynamic current = raw;
    for (final key in path) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        return const [];
      }
    }
    return current is List<dynamic> ? current : const [];
  }

  int batasAkgUntukUsia(int usia) {
    final rows = (raw['tabel_batas_natrium'] as List<dynamic>? ?? const []);
    for (final row in rows) {
      if (row is! Map<String, dynamic>) continue;
      final minUsia = (row['usia_min'] as num?)?.toInt();
      final maxUsia = row['usia_max'] as num?;
      if (minUsia == null) continue;
      final cocokMin = usia >= minUsia;
      final cocokMax = maxUsia == null || usia <= maxUsia.toInt();
      if (cocokMin && cocokMax) {
        final value = row['akg_batas_tercukupi_mg'];
        if (value is int) return value;
        if (value is num) return value.toInt();
      }
    }
    return _intValue([
      'aturan_dewasa',
      'batas_maksimum_who',
      'nilai',
    ], fallback: 2000);
  }

  int batasDewasa() => _intValue([
    'aturan_dewasa',
    'batas_maksimum_who',
    'nilai',
  ], fallback: 2000);

  int batasRiwayatHt(String riwayatHt, int batasUsia) {
    final normalized = _normalizeRiwayatHT(riwayatHt);
    final rows = _listValue(['aturan_dewasa', 'batas_riwayat_hipertensi']);

    if (normalized == 'ya_riwayat_saja' || normalized == 'ya_terkontrol') {
      return batasUsia - 300;
    }
    if (normalized == 'ya_aktif_terkontrol') {
      return 1500;
    }
    if (normalized == 'ya_tidak_terkontrol') {
      return 1200;
    }

    for (final row in rows) {
      if (row is! Map<String, dynamic>) continue;
      if (row['riwayat_ht'] == normalized) {
        final value = row['batas_mg'];
        if (value is int) return value;
        if (value is num) return value.toInt();
      }
    }
    return 9999;
  }

  int batasTd(int? sistolik, int? diastolik) {
    if (sistolik == null || diastolik == null) return 9999;
    final rows = _listValue(['aturan_dewasa', 'batas_tekanan_darah']);
    for (final row in rows) {
      if (row is! Map<String, dynamic>) continue;
      final batas = row['batas_mg'];
      final stage = row['stage']?.toString() ?? '';
      if (stage == 'krisis' && (sistolik >= 180 || diastolik >= 120)) {
        return _asInt(batas, fallback: 1000);
      }
      if (stage == 'stage_2' && (sistolik >= 140 || diastolik >= 90)) {
        return _asInt(batas, fallback: 1200);
      }
      if (stage == 'stage_1' && (sistolik >= 130 || diastolik >= 80)) {
        return _asInt(batas, fallback: 1500);
      }
      if (stage == 'elevated' && sistolik >= 120 && diastolik < 80) {
        return _asInt(batas, fallback: 1800);
      }
    }
    return 9999;
  }

  static int _asInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }
}

String _normalizeToken(String value) {
  return value.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
}

String _normalizeGender(String gender) {
  final normalized = _normalizeToken(gender);
  if (normalized == 'laki_laki' || normalized == 'male') {
    return 'laki_laki';
  }
  if (normalized == 'perempuan' || normalized == 'female') {
    return 'perempuan';
  }
  return normalized;
}

String _normalizeRiwayatHT(String riwayatHT) {
  final normalized = _normalizeToken(riwayatHT);
  switch (normalized) {
    case 'ya_riwayat_saja':
    case 'riwayat_saja':
    case 'history_only':
      return 'ya_riwayat_saja';
    case 'ya_aktif_terkontrol':
    case 'aktif_terkontrol':
      return 'ya_aktif_terkontrol';
    case 'ya':
    case 'iya':
    case 'yes':
    case 'true':
    case '1':
    case 'ada':
      return 'ya_tidak_terkontrol';
    case 'terkontrol':
    case 'ya_terkontrol':
      return 'ya_terkontrol';
    case 'tidak':
    case 'no':
    case 'false':
    case '0':
    case 'tidak_ada':
      return 'tidak_ada';
    default:
      return 'tidak_ada';
  }
}

String _normalizeStatusKehamilan(String statusKehamilan) {
  final normalized = _normalizeToken(statusKehamilan);
  switch (normalized) {
    case 'hamil_normal':
    case 'menyusui':
    case 'tidak_hamil':
      return normalized;
    default:
      return 'tidak_hamil';
  }
}

int hitungUsiaTahun(DateTime birthDate, {DateTime? asOf}) {
  final today = asOf ?? DateTime.now();
  var age = today.year - birthDate.year;
  final hasNotHadBirthdayThisYear =
      today.month < birthDate.month ||
      (today.month == birthDate.month && today.day < birthDate.day);
  if (hasNotHadBirthdayThisYear) {
    age -= 1;
  }
  return age;
}

int hitungBatasUsia(int usia) {
  if (usia <= 0) return 9999;
  if (usia <= 1) return 120;
  if (usia <= 2) return 370;
  if (usia <= 3) return 800;
  if (usia <= 6) return 900;
  if (usia <= 9) return 1000;
  if (usia <= 12) return 1300;
  if (usia <= 15) return 1500;
  if (usia <= 18) return 1700;
  if (usia <= 29) return 1500;
  if (usia <= 49) return 1500;
  if (usia <= 64) return 1500;
  if (usia <= 80) return 1300;
  return 1100;
}

int hitungBatasTD(int? sistolik, int? diastolik) {
  if (sistolik == null || diastolik == null) return 9999;
  if (sistolik >= 180 || diastolik >= 120) return 1000;
  if (sistolik >= 140 || diastolik >= 90) return 1200;
  if (sistolik >= 130 || diastolik >= 80) return 1500;
  if (sistolik >= 120 && diastolik < 80) return 1800;
  return 9999;
}

int hitungBatasHT(String riwayatHT, int batasUsia) {
  switch (_normalizeRiwayatHT(riwayatHT)) {
    case 'ya_tidak_terkontrol':
      return 1200;
    case 'ya_terkontrol':
      return batasUsia - 300;
    case 'tidak_ada':
    default:
      return 9999;
  }
}

int terapkanKehamilan(int batasPrimer, String statusKehamilan) {
  switch (_normalizeStatusKehamilan(statusKehamilan)) {
    case 'hamil_normal':
    case 'menyusui':
      return math.max(batasPrimer, 1500);
    default:
      return batasPrimer;
  }
}

KategoriNatrium tentukanKategori(
  String gender,
  String riwayatHT,
  String statusKehamilan,
) {
  final normalizedGender = _normalizeGender(gender);
  final punyaHT = _normalizeRiwayatHT(riwayatHT) != 'tidak_ada';
  final normalizedStatusKehamilan = _normalizeStatusKehamilan(statusKehamilan);
  final sedangHamil =
      normalizedGender == 'perempuan' &&
      (normalizedStatusKehamilan == 'hamil_normal' ||
          normalizedStatusKehamilan == 'menyusui');

  if (punyaHT) {
    return KategoriNatrium.merah;
  }
  if (sedangHamil) {
    return KategoriNatrium.kuning;
  }
  return KategoriNatrium.hijau;
}

String routeUntukKategori(KategoriNatrium kategori) {
  switch (kategori) {
    case KategoriNatrium.hijau:
      return '/sodium-safe';
    case KategoriNatrium.kuning:
      return '/sodium-pregnant';
    case KategoriNatrium.merah:
      return '/sodium-unsafe';
  }
}

String formatNatriumMg(int value) {
  final raw = value.toString();
  final reversed = raw.split('').reversed.toList();
  final buffer = StringBuffer();
  for (var index = 0; index < reversed.length; index++) {
    if (index > 0 && index % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(reversed[index]);
  }
  return buffer.toString().split('').reversed.join();
}

String _mapHypertensionConditionToRiwayatHt({
  required bool? hasHypertension,
  String? hypertensionCondition,
}) {
  final normalized = _normalizeToken(hypertensionCondition ?? '');
  final conditionImpliesHypertension =
      normalized == 'history_only' ||
      normalized == 'controlled' ||
      normalized == 'terkontrol' ||
      normalized == 'aktif_terkontrol' ||
      normalized == 'uncontrolled' ||
      normalized == 'aktif_tidak_terkontrol' ||
      normalized == 'tidak_terkontrol';

  if (hasHypertension != true && !conditionImpliesHypertension) {
    return 'tidak_ada';
  }

  switch (normalized) {
    case 'history_only':
      return 'ya_riwayat_saja';
    case 'controlled':
    case 'terkontrol':
    case 'aktif_terkontrol':
      return 'ya_aktif_terkontrol';
    case 'uncontrolled':
    case 'aktif_tidak_terkontrol':
    case 'tidak_terkontrol':
      return 'ya_tidak_terkontrol';
    case 'ya_riwayat_saja':
      return 'ya_riwayat_saja';
    case 'ya_aktif_terkontrol':
      return 'ya_aktif_terkontrol';
    case 'ya_terkontrol':
      return 'ya_riwayat_saja';
    case 'ya_tidak_terkontrol':
      return 'ya_tidak_terkontrol';
    default:
      return hasHypertension == true ? 'ya_tidak_terkontrol' : 'tidak_ada';
  }
}

String _mapPregnancyStatusToStatusKehamilan(String? pregnancyStatus) {
  final normalized = _normalizeToken(pregnancyStatus ?? '');
  switch (normalized) {
    case 'pregnant':
    case 'hamil':
    case 'hamil_normal':
      return 'hamil_normal';
    case 'breastfeeding':
    case 'menyusui':
      return 'menyusui';
    default:
      return 'tidak_hamil';
  }
}

Future<HasilKlasifikasi> klasifikasiNatriumDariDraft({
  required DateTime birthDate,
  required String gender,
  required bool? hasHypertension,
  String? hypertensionCondition,
  int? systolicPressure,
  int? diastolicPressure,
  String? pregnancyStatus,
}) {
  return klasifikasiNatriumDariAsset(
    tanggal_lahir: birthDate,
    gender: gender,
    riwayat_ht: _mapHypertensionConditionToRiwayatHt(
      hasHypertension: hasHypertension,
      hypertensionCondition: hypertensionCondition,
    ),
    sistolik: systolicPressure,
    diastolik: diastolicPressure,
    status_kehamilan: _mapPregnancyStatusToStatusKehamilan(pregnancyStatus),
  );
}

Future<HasilKlasifikasi> klasifikasiNatriumDariAsset({
  DateTime? tanggal_lahir,
  DateTime? tanggalLahir,
  required String gender,
  required String riwayat_ht,
  int? sistolik,
  int? diastolik,
  String status_kehamilan = 'tidak_hamil',
  String? statusKehamilan,
}) async {
  final ruleBook = await SodiumRuleBook.loadFromAsset();
  final resolvedTanggalLahir = tanggal_lahir ?? tanggalLahir;
  if (resolvedTanggalLahir == null) {
    throw ArgumentError('tanggal_lahir wajib diisi');
  }

  final usia = hitungUsiaTahun(resolvedTanggalLahir);
  if (usia < 18) {
    return HasilKlasifikasi(
      batasNatrium: ruleBook.batasAkgUntukUsia(usia),
      kategori: KategoriNatrium.hijau,
      hamilDenganHT: false,
    );
  }

  final resolvedStatusKehamilan =
      statusKehamilan != null && statusKehamilan.isNotEmpty
      ? statusKehamilan
      : status_kehamilan;
  final batasUsia = ruleBook.batasDewasa();
  final batasTd = ruleBook.batasTd(sistolik, diastolik);
  final batasHt = ruleBook.batasRiwayatHt(riwayat_ht, batasUsia);
  final normalizedRiwayatHt = _normalizeRiwayatHT(riwayat_ht);
  final batasFinal = normalizedRiwayatHt == 'ya_tidak_terkontrol'
      ? 1200
      : math.max(math.min(batasUsia, math.min(batasTd, batasHt)), 1000);
  final kategori = tentukanKategori(
    gender,
    riwayat_ht,
    resolvedStatusKehamilan,
  );
  final normalizedGender = _normalizeGender(gender);
  final normalizedStatusKehamilan = _normalizeStatusKehamilan(
    resolvedStatusKehamilan,
  );
  final hamilDenganHT =
      normalizedGender == 'perempuan' &&
      normalizedRiwayatHt != 'tidak_ada' &&
      (normalizedStatusKehamilan == 'hamil_normal' ||
          normalizedStatusKehamilan == 'menyusui');

  return HasilKlasifikasi(
    batasNatrium: batasFinal,
    kategori: kategori,
    hamilDenganHT: hamilDenganHT,
  );
}

HasilKlasifikasi klasifikasiNatrium({
  required int usia,
  required String gender,
  required String riwayatHT,
  int? sistolik,
  int? diastolik,
  String statusKehamilan = 'tidak_hamil',
}) {
  final batasUsia = hitungBatasUsia(usia);
  final batasTD = hitungBatasTD(sistolik, diastolik);
  final batasHT = hitungBatasHT(riwayatHT, batasUsia);
  final normalizedRiwayatHt = _normalizeRiwayatHT(riwayatHT);

  var batasPrimer = normalizedRiwayatHt == 'ya_tidak_terkontrol'
      ? 1200
      : math.min(batasUsia, math.min(batasTD, batasHT));

  if (_normalizeGender(gender) == 'perempuan') {
    batasPrimer = terapkanKehamilan(batasPrimer, statusKehamilan);
  }

  final batasFinal = math.max(batasPrimer, 1000);
  final kategori = tentukanKategori(gender, riwayatHT, statusKehamilan);
  final hamilDenganHT =
      _normalizeGender(gender) == 'perempuan' &&
      normalizedRiwayatHt != 'tidak_ada' &&
      (_normalizeStatusKehamilan(statusKehamilan) == 'hamil_normal' ||
          _normalizeStatusKehamilan(statusKehamilan) == 'menyusui');

  return HasilKlasifikasi(
    batasNatrium: batasFinal,
    kategori: kategori,
    hamilDenganHT: hamilDenganHT,
  );
}
