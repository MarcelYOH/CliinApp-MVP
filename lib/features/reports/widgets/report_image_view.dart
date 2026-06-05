import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────
// Widget — ReportImageView
// Affiche une image locale compatible Web + Mobile
// Sur Web  : Image.network (path = URL blob)
// Sur Mobile : Image.file
// ─────────────────────────────────────────
class ReportImageView extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;

  const ReportImageView({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Sur Web, image_picker retourne une URL blob
      return Image.network(
        imagePath,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    } else {
      // Sur Mobile (Android / iOS)
      return Image.file(
        File(imagePath),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFE0E0E0),
      child: const Icon(Icons.image_not_supported_outlined,
          color: Color(0xFF9E9E9E), size: 40),
    );
  }
}