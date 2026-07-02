String kategoriLabel(String value) {
  const labels = {
    'mie_instan': 'Mie & Pasta Instan',
    'keripik_snack': 'Snack & Keripik',
    'saus_bumbu': 'Saus & Bumbu',
    'minuman_kemasan': 'Minuman Kemasan',
    'biskuit_roti': 'Roti',
    'makanan_kaleng': 'Makanan Kaleng',
    'sereal': 'Sereal & Oatmeal',
    'biskuit': 'Biskuit & Wafer',
    'susu': 'Susu & Produk Susu',
    'frozen_food': 'Frozen Food',
    'lainnya': 'Lainnya',
  };

  return labels[value] ?? value;
}
