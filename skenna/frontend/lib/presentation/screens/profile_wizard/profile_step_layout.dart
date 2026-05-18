import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileStepLayout extends StatelessWidget {
  const ProfileStepLayout({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
    required this.nextLabel,
    required this.onNext,
    required this.child,
    required this.illustrationAsset,
  });

  final int step;
  final String title;
  final String subtitle;
  final String nextLabel;
  final VoidCallback? onNext;
  final Widget child;
  final String illustrationAsset;

  @override
  Widget build(BuildContext context) {
    const normalBlue = Color(0xFF2C4A8A);
    const lightBlue = Color(0xFFDFE4ED);
    const lighterText = Color(0xFFE6E6E6);

    final helperStyle = GoogleFonts.plusJakartaSans(
      color: normalBlue,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 72),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 35,
                    height: 35,
                    child: IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: lightBlue,
                        padding: const EdgeInsets.all(8),
                      ),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: normalBlue,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 275,
                    height: 8,
                    child: Stack(
                      children: [
                        Container(
                          width: 275,
                          height: 8,
                          decoration: BoxDecoration(
                            color: lighterText,
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: step / 7,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: normalBlue,
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Image.asset(
                illustrationAsset,
                width: 302,
                height: 302,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 32),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  color: normalBlue,
                  fontSize: 31,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(height: 16),
              child,
              SizedBox(height: 32),
              Text.rich(
                TextSpan(
                  style: helperStyle,
                  children: [TextSpan(text: subtitle)],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 344,
                height: 55,
                child: FilledButton(
                  onPressed: onNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: normalBlue,
                    elevation: 4,
                    shadowColor: const Color(0x40000000),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    nextLabel,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileTextField extends StatelessWidget {
  const ProfileTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.keyboardType,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: profileFieldDecoration(hintText),
    );
  }
}

class ChoiceButton extends StatelessWidget {
  const ChoiceButton({
    super.key,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2C4A8A) : const Color(0xFFDFE4ED),
          borderRadius: BorderRadius.circular(15),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF2C4A8A),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

InputDecoration profileFieldDecoration(String hintText) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(color: Color(0xFFBEC7DB), fontSize: 16),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Color(0xFFBEC7DB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Color(0xFFBEC7DB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Color(0xFF2C4A8A)),
    ),
  );
}
