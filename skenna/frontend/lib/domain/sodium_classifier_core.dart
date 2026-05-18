// ignore_for_file: non_constant_identifier_names

import 'dart:math';

enum KategoriNatrium { hijau, kuning, merah }

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

String _normalizeRiwayatHt(String riwayatHt) {
  final normalized = _normalizeToken(riwayatHt);
  switch (normalized) {
    case 'tidak_ada':
    case 'tidak':
    case 'no':
    case 'false':
    case '0':
      return 'tidak_ada';
    case 'ya_riwayat_saja':
    case 'riwayat_saja':
    case 'history_only':
      return 'ya_riwayat_saja';
    case 'ya_aktif_terkontrol':
      return 'ya_aktif_terkontrol';
    case 'ya_terkontrol':
    case 'terkontrol':
    case 'aktif_terkontrol':
      return 'ya_terkontrol';
    case 'ya_tidak_terkontrol':
    case 'ya':
    case 'iya':
    case 'yes':
    case 'true':
    case '1':
    case 'ada':
    case 'aktif_tidak_terkontrol':
      return 'ya_tidak_terkontrol';
    default:
      return 'tidak_ada';
  }
}

String _normalizeStatusKehamilan(String statusKehamilan) {
  final normalized = _normalizeToken(statusKehamilan);
  switch (normalized) {
    case 'hamil':
    case 'hamil_normal':
    case 'pregnant':
      return 'hamil_normal';
    case 'menyusui':
    case 'breastfeeding':
      return 'menyusui';
    default:
      return 'tidak_hamil';
  }
}

int hitungUsia(DateTime tanggalLahir) {
  final today = DateTime.now();
  var usia = today.year - tanggalLahir.year;
  if (today.month < tanggalLahir.month ||
      (today.month == tanggalLahir.month && today.day < tanggalLahir.day)) {
    usia--;
  }
  return usia;
}

int hitungBatasAKG(int usia) {
  if (usia <= 0) return 120;
  if (usia <= 1) return 370;
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

int hitungBatasHT(String riwayatHt, int batasUsia) {
  switch (_normalizeRiwayatHt(riwayatHt)) {
    case 'ya_riwayat_saja':
      return batasUsia - 300;
    case 'ya_aktif_terkontrol':
      return 1500;
    case 'ya_terkontrol':
      return batasUsia - 300;
    case 'ya_tidak_terkontrol':
      return 1200;
    case 'tidak_ada':
    default:
      return 9999;
  }
}

KategoriNatrium tentukanKategori(
  String gender,
  String riwayatHt,
  String statusKehamilan,
) {
  final normalizedGender = _normalizeGender(gender);
  final normalizedRiwayatHt = _normalizeRiwayatHt(riwayatHt);
  final normalizedStatusKehamilan = _normalizeStatusKehamilan(statusKehamilan);

  final punyaHT = normalizedRiwayatHt != 'tidak_ada';
  final sedangHamilMenyusui =
      normalizedGender == 'perempuan' &&
      (normalizedStatusKehamilan == 'hamil_normal' ||
          normalizedStatusKehamilan == 'menyusui');

  if (punyaHT) return KategoriNatrium.merah;
  if (sedangHamilMenyusui) return KategoriNatrium.kuning;
  return KategoriNatrium.hijau;
}

HasilKlasifikasi klasifikasiNatriumCore({
  required DateTime tanggalLahir,
  required String gender,
  required String riwayatHt,
  int? sistolik,
  int? diastolik,
  String statusKehamilan = 'tidak_hamil',
}) {
  final usia = hitungUsia(tanggalLahir);

  if (usia < 18) {
    return HasilKlasifikasi(
      batasNatrium: hitungBatasAKG(usia),
      kategori: KategoriNatrium.hijau,
      hamilDenganHT: false,
    );
  }

  const batasUsia = 2000;
  final batasTD = hitungBatasTD(sistolik, diastolik);
  final normalizedRiwayatHt = _normalizeRiwayatHt(riwayatHt);
  final batasHT = hitungBatasHT(normalizedRiwayatHt, batasUsia);

  final batasPrimer = normalizedRiwayatHt == 'ya_tidak_terkontrol'
      ? 1200
      : min(batasUsia, min(batasTD, batasHT));
  final batasFinal = max(batasPrimer, 1000);

  final kategori = tentukanKategori(gender, riwayatHt, statusKehamilan);

  final normalizedGender = _normalizeGender(gender);
  final normalizedStatusKehamilan = _normalizeStatusKehamilan(statusKehamilan);
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
