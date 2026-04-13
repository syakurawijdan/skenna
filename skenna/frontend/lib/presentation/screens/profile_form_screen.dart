import 'package:flutter/material.dart';

import '../navigation/app_routes.dart';

class ProfileFormScreen extends StatefulWidget {
  const ProfileFormScreen({super.key});

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();

  bool _hasHypertension = true;

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.pushNamed(context, AppRoutes.sodiumChoice);
  }

  @override
  Widget build(BuildContext context) {
    const pageBg = Color(0xFFF5F5F7);
    const darkBlue = Color(0xFF213868);
    const normalBlue = Color(0xFF2C4A8A);
    const fieldBg = Color(0xFFDFE4ED);
    const hint = Color(0xFFB0B0B0);

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = (constraints.maxHeight / 760).clamp(0.9, 1.0);

            return Padding(
              padding: EdgeInsets.fromLTRB(
                30 * scale,
                14 * scale,
                30 * scale,
                18 * scale,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 56 * scale),
                  Center(
                    child: Text(
                      'Ketahui Asupan\nNatrium Harianmu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 25 * scale,
                        fontWeight: FontWeight.w700,
                        color: darkBlue,
                        height: 1.05,
                      ),
                    ),
                  ),
                  SizedBox(height: 34 * scale),
                  Text(
                    'Berapa usia kamu?',
                    style: TextStyle(
                      color: normalBlue,
                      fontSize: 20 * scale,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 8 * scale),
                  _InputBox(
                    controller: _ageController,
                    hintText: 'Isi usia',
                    keyboardType: TextInputType.number,
                    bgColor: fieldBg,
                    hintColor: hint,
                    fontSize: 14 * scale,
                    borderRadius: 15 * scale,
                    horizontalPadding: 16 * scale,
                    verticalPadding: 11 * scale,
                  ),
                  SizedBox(height: 15 * scale),
                  Text(
                    'Berapa BMI kamu?',
                    style: TextStyle(
                      color: normalBlue,
                      fontSize: 20 * scale,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 6 * scale),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Tinggi badan',
                          style: TextStyle(
                            color: normalBlue,
                            fontSize: 13 * scale,
                          ),
                        ),
                      ),
                      SizedBox(width: 16 * scale),
                      Expanded(
                        child: Text(
                          'Berat badan',
                          style: TextStyle(
                            color: normalBlue,
                            fontSize: 13 * scale,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4 * scale),
                  Row(
                    children: [
                      Expanded(
                        child: _InputBox(
                          controller: _heightController,
                          hintText: 'Isi tinggi badan',
                          keyboardType: TextInputType.number,
                          bgColor: fieldBg,
                          hintColor: hint,
                          fontSize: 14 * scale,
                          borderRadius: 15 * scale,
                          horizontalPadding: 16 * scale,
                          verticalPadding: 11 * scale,
                        ),
                      ),
                      SizedBox(width: 16 * scale),
                      Expanded(
                        child: _InputBox(
                          controller: _weightController,
                          hintText: 'Isi berat badan',
                          keyboardType: TextInputType.number,
                          bgColor: fieldBg,
                          hintColor: hint,
                          fontSize: 14 * scale,
                          borderRadius: 15 * scale,
                          horizontalPadding: 16 * scale,
                          verticalPadding: 11 * scale,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15 * scale),
                  Text(
                    'Berapa tekanan darah kamu?',
                    style: TextStyle(
                      color: normalBlue,
                      fontSize: 20 * scale,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 6 * scale),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Sistolik',
                          style: TextStyle(
                            color: normalBlue,
                            fontSize: 13 * scale,
                          ),
                        ),
                      ),
                      SizedBox(width: 16 * scale),
                      Expanded(
                        child: Text(
                          'Diastolik',
                          style: TextStyle(
                            color: normalBlue,
                            fontSize: 13 * scale,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4 * scale),
                  Row(
                    children: [
                      Expanded(
                        child: _InputBox(
                          controller: _systolicController,
                          hintText: 'Isi sistolik',
                          keyboardType: TextInputType.number,
                          bgColor: fieldBg,
                          hintColor: hint,
                          fontSize: 14 * scale,
                          borderRadius: 15 * scale,
                          horizontalPadding: 16 * scale,
                          verticalPadding: 11 * scale,
                        ),
                      ),
                      SizedBox(width: 16 * scale),
                      Expanded(
                        child: _InputBox(
                          controller: _diastolicController,
                          hintText: 'Isi diastolik',
                          keyboardType: TextInputType.number,
                          bgColor: fieldBg,
                          hintColor: hint,
                          fontSize: 14 * scale,
                          borderRadius: 15 * scale,
                          horizontalPadding: 16 * scale,
                          verticalPadding: 11 * scale,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15 * scale),
                  Text(
                    'Apakah kamu memiliki riwayat hipertensi?',
                    style: TextStyle(
                      color: normalBlue,
                      fontSize: 20 * scale,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 8 * scale),
                  Row(
                    children: [
                      _RadioItem(
                        selected: _hasHypertension,
                        label: 'Ya, saya punya',
                        onTap: () => setState(() => _hasHypertension = true),
                        fontSize: 20 * scale,
                        dotSize: 12 * scale,
                        outlineSize: 24 * scale,
                        textColor: normalBlue,
                        accentColor: normalBlue,
                      ),
                      SizedBox(width: 28 * scale),
                      _RadioItem(
                        selected: !_hasHypertension,
                        label: 'Tidak',
                        onTap: () => setState(() => _hasHypertension = false),
                        fontSize: 20 * scale,
                        dotSize: 12 * scale,
                        outlineSize: 24 * scale,
                        textColor: normalBlue,
                        accentColor: normalBlue,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Center(
                    child: Text(
                      'Semakin lengkap data yang kamu isi, semakin akurat\nhasil analisis dari Skenna',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: normalBlue,
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.w400,
                        height: 1.2,
                      ),
                    ),
                  ),
                  SizedBox(height: 16 * scale),
                  SizedBox(
                    width: double.infinity,
                    height: 48 * scale,
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: normalBlue,
                        elevation: 4,
                        shadowColor: const Color(0x40000000),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24 * scale),
                        ),
                      ),
                      child: Text(
                        'Lanjutkan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20 * scale,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InputBox extends StatelessWidget {
  const _InputBox({
    required this.controller,
    required this.hintText,
    required this.keyboardType,
    required this.bgColor,
    required this.hintColor,
    required this.fontSize,
    required this.borderRadius,
    required this.horizontalPadding,
    required this.verticalPadding,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final Color bgColor;
  final Color hintColor;
  final double fontSize;
  final double borderRadius;
  final double horizontalPadding;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: const Color(0xFF2E4D93), fontSize: fontSize),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: hintColor, fontSize: fontSize),
        filled: true,
        fillColor: bgColor,
        contentPadding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _RadioItem extends StatelessWidget {
  const _RadioItem({
    required this.selected,
    required this.label,
    required this.onTap,
    required this.fontSize,
    required this.dotSize,
    required this.outlineSize,
    required this.textColor,
    required this.accentColor,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;
  final double fontSize;
  final double dotSize;
  final double outlineSize;
  final Color textColor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: outlineSize,
            height: outlineSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accentColor, width: 2),
            ),
            child: selected
                ? Center(
                    child: CircleAvatar(
                      radius: dotSize / 2,
                      backgroundColor: accentColor,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
