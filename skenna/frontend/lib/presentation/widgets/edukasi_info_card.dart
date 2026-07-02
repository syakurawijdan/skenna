import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EdukasiInfoCard extends StatelessWidget {
  const EdukasiInfoCard({
    super.key,
    required this.productName,
    required this.sodiumPerServingMg,
    required this.servingDescription,
  });

  final String productName;
  final num sodiumPerServingMg;
  final String servingDescription;

  static const _blue = Color(0xFF2C4A8A);
  static const _navy = Color(0xFF1E3A6E);
  static const _bgCard = Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    final sodiumText = _formatNumber(sodiumPerServingMg);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _blue.withOpacity(0.14), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _bgCard,
              border: Border(
                bottom: BorderSide(color: _blue.withOpacity(0.12), width: 0.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          color: _navy,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 11,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Bumbu & Kondimen',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: _blue.withOpacity(0.12), width: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KANDUNGAN NATRIUM PER TAKARAN',
                  style: GoogleFonts.plusJakartaSans(
                    color: _navy.withOpacity(0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      sodiumText,
                      style: GoogleFonts.plusJakartaSans(
                        color: _blue,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        'mg',
                        style: GoogleFonts.plusJakartaSans(
                          color: _blue,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'per $servingDescription',
                  style: GoogleFonts.plusJakartaSans(
                    color: _navy.withOpacity(0.65),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _blue.withOpacity(0.12), width: 0.5),
              ),
            ),
            child: Text(
              'Bumbu, saus, atau penyedap rasa biasanya digunakan dalam jumlah kecil dan bervariasi tiap kali pakai, sehingga belum bisa dihitung otomatis ke total konsumsi harianmu.',
              style: GoogleFonts.plusJakartaSans(
                color: _navy,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.6,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, color: _blue, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Perhatikan jumlah penggunaannya untuk menjaga asupan natrium tetap aman.',
                    style: GoogleFonts.plusJakartaSans(
                      color: _navy.withOpacity(0.65),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
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

  static String _formatNumber(num value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }
}
