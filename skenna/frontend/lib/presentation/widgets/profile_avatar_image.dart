import 'package:flutter/material.dart';

class ProfileAvatarImage extends StatelessWidget {
  const ProfileAvatarImage({
    super.key,
    required this.asset,
    required this.size,
    required this.debugLabel,
    this.fit = BoxFit.cover,
  });

  final String asset;
  final double size;
  final String debugLabel;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    debugPrint('$debugLabel asset path: $asset');

    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('$debugLabel asset load error for "$asset": $error');
        debugPrintStack(stackTrace: stackTrace);

        return Container(
          width: size,
          height: size,
          color: const Color(0xFFDCE3EE),
          alignment: Alignment.center,
          child: Icon(
            Icons.person_rounded,
            color: const Color(0xFF2C4A8A).withAlpha(130),
            size: size * 0.48,
          ),
        );
      },
    );
  }
}
