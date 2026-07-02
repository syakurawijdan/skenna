// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum KategoriNatrium { hijau, kuning, merah }

class SodiumCategoryKey {
  static const normalAnak = 'normal_anak';
  static const normalDewasa = 'normal_dewasa';
  static const hipertensiDewasa = 'hipertensi_dewasa';
  static const hipertensiAnak = 'hipertensi_anak';
  static const hipertensiHamilRemaja = 'hipertensi_hamil_remaja';
  static const hamilDewasa = 'hamil_dewasa';
  static const hamilRemaja = 'hamil_remaja';

  static const values = <String>{
    normalAnak,
    normalDewasa,
    hipertensiDewasa,
    hipertensiAnak,
    hipertensiHamilRemaja,
    hamilDewasa,
    hamilRemaja,
  };
}

@immutable
class HasilKlasifikasi {
  const HasilKlasifikasi({
    required this.batasNatrium,
    required this.kategori,
    required this.hamilDenganHT,
    this.categoryKey = SodiumCategoryKey.normalDewasa,
    this.usia = 0,
    this.akgReferenceMg,
    this.escKategori,
    this.sistolik,
    this.diastolik,
    this.isPregnantOrBreastfeeding = false,
    this.hasHypertension = false,
    this.isHardMaximum = true,
  });

  final int batasNatrium;
  final KategoriNatrium kategori;
  final bool hamilDenganHT;
  final String categoryKey;
  final int usia;
  final int? akgReferenceMg;
  final String? escKategori;
  final int? sistolik;
  final int? diastolik;
  final bool isPregnantOrBreastfeeding;
  final bool hasHypertension;
  final bool isHardMaximum;
}

@immutable
class SodiumResolvedCategory {
  const SodiumResolvedCategory({
    required this.categoryKey,
    required this.bucket,
  });

  final String categoryKey;
  final KategoriNatrium bucket;
}

class SodiumCategoryResolver {
  static SodiumResolvedCategory resolve({
    required int age,
    required bool hasHypertension,
    required bool isPregnantOrBreastfeeding,
    int? systolic,
    int? diastolic,
  }) {
    if (age < 16) {
      if (hasHypertension && isPregnantOrBreastfeeding) {
        return const SodiumResolvedCategory(
          categoryKey: SodiumCategoryKey.hipertensiHamilRemaja,
          bucket: KategoriNatrium.merah,
        );
      }
      if (hasHypertension) {
        return const SodiumResolvedCategory(
          categoryKey: SodiumCategoryKey.hipertensiAnak,
          bucket: KategoriNatrium.merah,
        );
      }
      if (isPregnantOrBreastfeeding) {
        return const SodiumResolvedCategory(
          categoryKey: SodiumCategoryKey.hamilRemaja,
          bucket: KategoriNatrium.kuning,
        );
      }
      return const SodiumResolvedCategory(
        categoryKey: SodiumCategoryKey.normalAnak,
        bucket: KategoriNatrium.hijau,
      );
    }

    if (hasHypertension) {
      return const SodiumResolvedCategory(
        categoryKey: SodiumCategoryKey.hipertensiDewasa,
        bucket: KategoriNatrium.merah,
      );
    }
    if (isPregnantOrBreastfeeding) {
      return const SodiumResolvedCategory(
        categoryKey: SodiumCategoryKey.hamilDewasa,
        bucket: KategoriNatrium.kuning,
      );
    }
    return const SodiumResolvedCategory(
      categoryKey: SodiumCategoryKey.normalDewasa,
      bucket: KategoriNatrium.hijau,
    );
  }
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

  int limitForCategory(String categoryKey, int usia, String gender) {
    switch (categoryKey) {
      case SodiumCategoryKey.normalAnak:
      case SodiumCategoryKey.hipertensiAnak:
      case SodiumCategoryKey.hipertensiHamilRemaja:
      case SodiumCategoryKey.hamilRemaja:
        return akgUntukUsia(usia, gender);
      case SodiumCategoryKey.hipertensiDewasa:
        return _intValue(['referensi', 'aha', 'nilai'], fallback: 1500);
      case SodiumCategoryKey.normalDewasa:
      case SodiumCategoryKey.hamilDewasa:
      default:
        return _intValue(['referensi', 'who', 'nilai'], fallback: 2000);
    }
  }

  int akgUntukUsia(int usia, String gender) {
    final table = raw['akg_usia_kurang_16'];
    if (table is Map<String, dynamic>) {
      for (final row in table.values) {
        if (row is! Map<String, dynamic>) continue;
        final minUsia = (row['usia_min_tahun'] as num?)?.toInt();
        final maxUsia = (row['usia_max_tahun'] as num?)?.toInt();
        if (minUsia == null || maxUsia == null) continue;
        if (usia < minUsia || usia > maxUsia) continue;

        final nilaiMg = row['nilai_mg'];
        if (nilaiMg is int) return nilaiMg;
        if (nilaiMg is num) return nilaiMg.toInt();

        final normalizedGender = _normalizeGender(gender);
        final genderKey = normalizedGender == 'perempuan'
            ? 'perempuan_mg'
            : 'laki_laki_mg';
        final genderValue = row[genderKey];
        if (genderValue is int) return genderValue;
        if (genderValue is num) return genderValue.toInt();
      }
    }

    return _akgFallbackForAgeAndGender(usia, gender);
  }

  int adultAkgReferenceForAge(int usia) {
    // TODO: confirm final AKG table with product owner before defense
    if (usia <= 18) return 1700;
    if (usia <= 64) return 1500;
    if (usia <= 80) return 1300;
    return 1100;
  }

  String escKategori(int? sistolik, int? diastolik) {
    if (sistolik == null || diastolik == null) {
      return 'Tidak diketahui';
    }
    if (sistolik >= 180 || diastolik >= 110) {
      return 'Hipertensi Grade 3';
    }
    if (sistolik >= 160 || diastolik >= 100) {
      return 'Hipertensi Grade 2';
    }
    if (sistolik >= 140 || diastolik >= 90) {
      return 'Hipertensi Grade 1';
    }
    if (sistolik >= 130 || diastolik >= 85) {
      return 'High Normal';
    }
    if (sistolik >= 120 || diastolik >= 80) {
      return 'Normal';
    }
    return 'Optimal';
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
    case 'controlled':
    case 'terkontrol':
    case 'ya_terkontrol':
      return 'ya_aktif_terkontrol';
    case 'ya':
    case 'iya':
    case 'yes':
    case 'true':
    case '1':
    case 'ada':
    case 'uncontrolled':
    case 'aktif_tidak_terkontrol':
    case 'tidak_terkontrol':
    case 'ya_tidak_terkontrol':
      return 'ya_tidak_terkontrol';
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

int _akgFallbackForAgeAndGender(int usia, String gender) {
  // TODO: confirm final AKG table with product owner before defense
  // NOTE: 0-11 months intentionally collapses into the 0-5-month value (120mg) since `usia` is integer years, not months. Accepted by product owner - see sodium_rules.json's 6_11_bulan note.
  if (usia <= 0) return 120;
  if (usia <= 3) return 800;
  if (usia <= 6) return 900;
  if (usia <= 9) return 1000;
  if (usia <= 12) {
    return _normalizeGender(gender) == 'perempuan' ? 1400 : 1300;
  }
  if (usia <= 15) return 1500;
  return 2000;
}

bool _riwayatImpliesHypertension(String riwayatHT) {
  return _normalizeRiwayatHT(riwayatHT) != 'tidak_ada';
}

bool _isPregnantOrBreastfeeding(String statusKehamilan) {
  final normalized = _normalizeStatusKehamilan(statusKehamilan);
  return normalized == 'hamil_normal' || normalized == 'menyusui';
}

String routeUntukCategoryKey(String categoryKey) {
  switch (_bucketForCategoryKey(categoryKey)) {
    case KategoriNatrium.hijau:
      return '/sodium-safe';
    case KategoriNatrium.kuning:
      return '/sodium-pregnant';
    case KategoriNatrium.merah:
      return '/sodium-unsafe';
  }
}

KategoriNatrium _bucketForCategoryKey(String categoryKey) {
  switch (categoryKey) {
    case SodiumCategoryKey.hipertensiDewasa:
    case SodiumCategoryKey.hipertensiAnak:
    case SodiumCategoryKey.hipertensiHamilRemaja:
      return KategoriNatrium.merah;
    case SodiumCategoryKey.hamilDewasa:
    case SodiumCategoryKey.hamilRemaja:
      return KategoriNatrium.kuning;
    case SodiumCategoryKey.normalAnak:
    case SodiumCategoryKey.normalDewasa:
    default:
      return KategoriNatrium.hijau;
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
    case 'ya_terkontrol':
      return 'ya_aktif_terkontrol';
    case 'ya_tidak_terkontrol':
      return 'ya_tidak_terkontrol';
    default:
      return hasHypertension == true ? 'ya_tidak_terkontrol' : 'tidak_ada';
  }
}

String _mapPregnancyStatusToStatusKehamilan(String? pregnancyStatus) {
  return _normalizeStatusKehamilan(pregnancyStatus ?? '');
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
  final resolvedStatusKehamilan =
      statusKehamilan != null && statusKehamilan.isNotEmpty
      ? statusKehamilan
      : status_kehamilan;
  final normalizedGender = _normalizeGender(gender);
  final normalizedRiwayatHt = _normalizeRiwayatHT(riwayat_ht);
  final pregnantOrBreastfeeding =
      normalizedGender == 'perempuan' &&
      _isPregnantOrBreastfeeding(resolvedStatusKehamilan);
  final hasHypertension = normalizedRiwayatHt != 'tidak_ada';

  final resolved = SodiumCategoryResolver.resolve(
    age: usia,
    hasHypertension: hasHypertension,
    isPregnantOrBreastfeeding: pregnantOrBreastfeeding,
    systolic: sistolik,
    diastolic: diastolik,
  );
  final limit = ruleBook.limitForCategory(resolved.categoryKey, usia, gender);
  final akgReference = usia >= 16
      ? ruleBook.adultAkgReferenceForAge(usia)
      : ruleBook.akgUntukUsia(usia, gender);
  final hamilDenganHT = pregnantOrBreastfeeding && hasHypertension;

  return HasilKlasifikasi(
    batasNatrium: limit,
    kategori: resolved.bucket,
    hamilDenganHT: hamilDenganHT,
    categoryKey: resolved.categoryKey,
    usia: usia,
    akgReferenceMg: akgReference,
    escKategori: ruleBook.escKategori(sistolik, diastolik),
    sistolik: sistolik,
    diastolik: diastolik,
    isPregnantOrBreastfeeding: pregnantOrBreastfeeding,
    hasHypertension: hasHypertension,
    isHardMaximum: usia >= 16,
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
  final normalizedGender = _normalizeGender(gender);
  final hasHypertension = _riwayatImpliesHypertension(riwayatHT);
  final pregnantOrBreastfeeding =
      normalizedGender == 'perempuan' &&
      _isPregnantOrBreastfeeding(statusKehamilan);
  final resolved = SodiumCategoryResolver.resolve(
    age: usia,
    hasHypertension: hasHypertension,
    isPregnantOrBreastfeeding: pregnantOrBreastfeeding,
    systolic: sistolik,
    diastolic: diastolik,
  );
  final fallbackRuleBook = SodiumRuleBook._(raw: const {});
  final limit = fallbackRuleBook.limitForCategory(
    resolved.categoryKey,
    usia,
    gender,
  );
  final akgReference = usia >= 16
      ? fallbackRuleBook.adultAkgReferenceForAge(usia)
      : fallbackRuleBook.akgUntukUsia(usia, gender);

  return HasilKlasifikasi(
    batasNatrium: limit,
    kategori: resolved.bucket,
    hamilDenganHT: pregnantOrBreastfeeding && hasHypertension,
    categoryKey: resolved.categoryKey,
    usia: usia,
    akgReferenceMg: akgReference,
    escKategori: fallbackRuleBook.escKategori(sistolik, diastolik),
    sistolik: sistolik,
    diastolik: diastolik,
    isPregnantOrBreastfeeding: pregnantOrBreastfeeding,
    hasHypertension: hasHypertension,
    isHardMaximum: usia >= 16,
  );
}
