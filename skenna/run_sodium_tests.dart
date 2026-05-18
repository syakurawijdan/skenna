import 'frontend/lib/domain/sodium_classifier_core.dart';
import 'dart:io';

DateTime _birthFromYears(int years) {
  final now = DateTime.now();
  return DateTime(now.year - years, now.month, now.day);
}

void main() {
  final tests = <Map<String, dynamic>>[
    {
      'name': 'Case 1 - Anak 12 tahun',
      'input': {
        'tanggal_lahir': _birthFromYears(12),
        'gender': 'laki_laki',
        'riwayat_ht': 'tidak_ada',
        'sistolik': null,
        'diastolik': null,
        'status_kehamilan': 'tidak_hamil',
      },
      'expected': {
        'batas': 1300,
        'kategori': KategoriNatrium.hijau,
        'hamilDenganHT': false,
      },
    },
    {
      'name': 'Case 2 - Dewasa 30, tidak HT, TD normal',
      'input': {
        'tanggal_lahir': _birthFromYears(30),
        'gender': 'laki_laki',
        'riwayat_ht': 'tidak_ada',
        'sistolik': null,
        'diastolik': null,
        'status_kehamilan': 'tidak_hamil',
      },
      'expected': {
        'batas': 2000,
        'kategori': KategoriNatrium.hijau,
        'hamilDenganHT': false,
      },
    },
    {
      'name': 'Case 3 - Dewasa 45, HT terkontrol',
      'input': {
        'tanggal_lahir': _birthFromYears(45),
        'gender': 'laki_laki',
        'riwayat_ht': 'ya_terkontrol',
        'sistolik': null,
        'diastolik': null,
        'status_kehamilan': 'tidak_hamil',
      },
      'expected': {
        'batas': 1700,
        'kategori': KategoriNatrium.merah,
        'hamilDenganHT': false,
      },
    },
    {
      'name': 'Case 4 - Dewasa 38, HT tidak terkontrol, TD 150/95',
      'input': {
        'tanggal_lahir': _birthFromYears(38),
        'gender': 'laki_laki',
        'riwayat_ht': 'ya_tidak_terkontrol',
        'sistolik': 150,
        'diastolik': 95,
        'status_kehamilan': 'tidak_hamil',
      },
      'expected': {
        'batas': 1200,
        'kategori': KategoriNatrium.merah,
        'hamilDenganHT': false,
      },
    },
    {
      'name':
          'Case 4b - Dewasa 38, HT tidak terkontrol, TD krisis tetap override 1200',
      'input': {
        'tanggal_lahir': _birthFromYears(38),
        'gender': 'laki_laki',
        'riwayat_ht': 'ya_tidak_terkontrol',
        'sistolik': 190,
        'diastolik': 125,
        'status_kehamilan': 'tidak_hamil',
      },
      'expected': {
        'batas': 1200,
        'kategori': KategoriNatrium.merah,
        'hamilDenganHT': false,
      },
    },
    {
      'name': 'Case 5 - Perempuan 28, hamil, tidak HT',
      'input': {
        'tanggal_lahir': _birthFromYears(28),
        'gender': 'perempuan',
        'riwayat_ht': 'tidak_ada',
        'sistolik': null,
        'diastolik': null,
        'status_kehamilan': 'pregnant',
      },
      'expected': {
        'batas': 2000,
        'kategori': KategoriNatrium.kuning,
        'hamilDenganHT': false,
      },
    },
    {
      'name': 'Case 6 - Perempuan 35, hamil, HT terkontrol, TD 132/82',
      'input': {
        'tanggal_lahir': _birthFromYears(35),
        'gender': 'perempuan',
        'riwayat_ht': 'ya_terkontrol',
        'sistolik': 132,
        'diastolik': 82,
        'status_kehamilan': 'pregnant',
      },
      'expected': {
        'batas': 1500,
        'kategori': KategoriNatrium.merah,
        'hamilDenganHT': true,
      },
    },
  ];

  var passed = 0;
  for (final t in tests) {
    final name = t['name'] as String;
    final input = t['input'] as Map<String, dynamic>;
    final expected = t['expected'] as Map<String, dynamic>;

    final hasil = klasifikasiNatriumCore(
      tanggalLahir: input['tanggal_lahir'] as DateTime,
      gender: input['gender'] as String,
      riwayatHt: input['riwayat_ht'] as String,
      sistolik: input['sistolik'] as int?,
      diastolik: input['diastolik'] as int?,
      statusKehamilan: input['status_kehamilan'] as String,
    );

    final ok =
        hasil.batasNatrium == expected['batas'] &&
        hasil.kategori == expected['kategori'] &&
        hasil.hamilDenganHT == expected['hamilDenganHT'];

    print('---');
    print(name);
    print(
      'Expected: batas=${expected['batas']}, kategori=${expected['kategori']}, hamilDenganHT=${expected['hamilDenganHT']}',
    );
    print(
      'Actual:   batas=${hasil.batasNatrium}, kategori=${hasil.kategori}, hamilDenganHT=${hasil.hamilDenganHT}',
    );
    print('Result: ${ok ? 'PASS' : 'FAIL'}');

    if (ok) passed++;
  }

  print('=== SUMMARY: $passed/${tests.length} passed ===');
  if (passed != tests.length) {
    exit(1);
  }
}
