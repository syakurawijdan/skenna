import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileStepLayout extends StatelessWidget {
  ProfileStepLayout({
    super.key,
    this.step,
    this.progress,
    required this.title,
    this.subtitle,
    this.nextLabel,
    this.onNext,
    Widget? child,
    Widget? content,
    required this.illustrationAsset,
    this.primaryButton,
    this.secondaryAction,
    this.showProgress = true,
    this.showBack = false,
  }) : assert(child != null || content != null),
       child = child ?? content!;

  final int? step;
  final double? progress;
  final String title;
  final Object? subtitle;
  final String? nextLabel;
  final VoidCallback? onNext;
  final Widget child;
  final String illustrationAsset;
  final Widget? primaryButton;
  final Widget? secondaryAction;
  final bool showProgress;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    const normalBlue = Color(0xFF2C4A8A);
    const lightBlue = Color(0xFFDFE4ED);
    const lighterText = Color(0xFFE6E6E6);

    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;
    final progressValue = progress ?? ((step ?? 0) / 7);

    final helperStyle = GoogleFonts.plusJakartaSans(
      color: normalBlue,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1,
    );
    final subtitleWidget = subtitle is Widget
        ? subtitle as Widget
        : Text.rich(
            TextSpan(
              style: helperStyle,
              children: [TextSpan(text: subtitle?.toString() ?? '')],
            ),
            textAlign: TextAlign.center,
          );
    final button =
        primaryButton ??
        FilledButton(
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
            nextLabel ?? '',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        );

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              subtitleWidget,
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 343),
                child: Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x26000000),
                        offset: Offset(0, 4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: button,
                ),
              ),
              if (secondaryAction != null) ...[
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 343),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: secondaryAction,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showProgress || showBack)
                    Row(
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
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
                        if (showProgress) ...[
                          const SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(
                              height: 8,
                              child: Stack(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: lighterText,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: progressValue,
                                    child: Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: normalBlue,
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    height: isKeyboardVisible
                        ? 0
                        : mediaQuery.size.height * 0.30,
                    child: isKeyboardVisible
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Image.asset(
                              illustrationAsset,
                              fit: BoxFit.contain,
                            ),
                          ),
                  ),

                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.only(
                      top: isKeyboardVisible ? 150 : 0,
                      bottom: 16,
                    ),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        color: normalBlue,
                        fontSize: isKeyboardVisible ? 27 : 26,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),

                  Expanded(child: SingleChildScrollView(child: child)),
                ],
              ),
            ),
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
            fontWeight: FontWeight.w500,
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
