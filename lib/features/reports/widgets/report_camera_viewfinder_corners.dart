import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

// ─────────────────────────────────────────
// Widget — ReportCameraViewfinderCorners
// Coins du viewfinder — partagé entre ReportCameraPage et ProofCameraPage
// ─────────────────────────────────────────
class ReportCameraViewfinderCorners extends StatelessWidget {
  const ReportCameraViewfinderCorners({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(CliinAppConstants.spacingXL),
      child: Stack(
        children: [
          Positioned(top: 0, left: 0, child: _Corner(topLeft: true)),
          Positioned(top: 0, right: 0, child: _Corner(topRight: true)),
          Positioned(bottom: 0, left: 0, child: _Corner(bottomLeft: true)),
          Positioned(bottom: 0, right: 0, child: _Corner(bottomRight: true)),
        ],
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  const _Corner({
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _CornerPainter(
          topLeft: topLeft,
          topRight: topRight,
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool topLeft, topRight, bottomLeft, bottomRight;

  _CornerPainter({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    if (topLeft) {
      canvas.drawLine(Offset(0, size.height), Offset.zero, paint);
      canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
    }
    if (topRight) {
      canvas.drawLine(Offset(0, 0), Offset(size.width, 0), paint);
      canvas.drawLine(
        Offset(size.width, 0),
        Offset(size.width, size.height),
        paint,
      );
    }
    if (bottomLeft) {
      canvas.drawLine(Offset.zero, Offset(0, size.height), paint);
      canvas.drawLine(
        Offset(0, size.height),
        Offset(size.width, size.height),
        paint,
      );
    }
    if (bottomRight) {
      canvas.drawLine(
        Offset(size.width, 0),
        Offset(size.width, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(size.width, size.height),
        Offset(0, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}
