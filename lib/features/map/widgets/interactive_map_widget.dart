// lib/features/map/widgets/interactive_map_widget.dart
// Carte interactive — placeholder visuel — Page Carte — CliinApp
// Remplaçable par GoogleMap() quand la clé API est disponible

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';

class MapMarkerData {
  final double top;    // position relative (0.0 à 1.0)
  final double left;
  final Color color;
  final int? clusterCount;
  final bool isUserLocation;

  const MapMarkerData({
    required this.top,
    required this.left,
    required this.color,
    this.clusterCount,
    this.isUserLocation = false,
  });
}

class InteractiveMapWidget extends StatelessWidget {
  final VoidCallback? onLayersTap;
  final VoidCallback? onRecenterTap;

  const InteractiveMapWidget({
    super.key,
    this.onLayersTap,
    this.onRecenterTap,
  });

  static const List<MapMarkerData> _markers = [
    // Position utilisateur — centre
    MapMarkerData(top: 0.42, left: 0.48, color: Colors.blue, isUserLocation: true),

    // Cluster rouge x3 — Angré
    MapMarkerData(top: 0.18, left: 0.30, color: Color(0xFFE53935), clusterCount: 3),

    // Cluster rouge x2 — Yopougon
    MapMarkerData(top: 0.50, left: 0.08, color: Color(0xFFE53935), clusterCount: 2),

    // Cluster rouge x5 — Marcory
    MapMarkerData(top: 0.70, left: 0.52, color: Color(0xFFE53935), clusterCount: 5),

    // Marqueur orange — Riviera
    MapMarkerData(top: 0.30, left: 0.62, color: Color(0xFFFF9800)),

    // Marqueur orange — centre
    MapMarkerData(top: 0.44, left: 0.58, color: Color(0xFFFF9800)),

    // Marqueur orange — bas centre
    MapMarkerData(top: 0.60, left: 0.38, color: Color(0xFFFF9800)),

    // Marqueur vert — Angré droite
    MapMarkerData(top: 0.22, left: 0.55, color: Color(0xFF2DB84B)),

    // Marqueur vert — centre gauche
    MapMarkerData(top: 0.48, left: 0.22, color: Color(0xFF2DB84B)),

    // Marqueur vert — bas droite
    MapMarkerData(top: 0.62, left: 0.60, color: Color(0xFF2DB84B)),

    // Marqueur jaune — Riviera droite
    MapMarkerData(top: 0.28, left: 0.72, color: Color(0xFFFFC107)),

    // Marqueur jaune — bas droite
    MapMarkerData(top: 0.62, left: 0.75, color: Color(0xFFFFC107)),

    // Marqueur violet — Riviera extrême droite
    MapMarkerData(top: 0.40, left: 0.88, color: Color(0xFF9C27B0)),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Fond de carte simulé ───────────────────
        Positioned.fill(
          child: CustomPaint(
            painter: _MapBackgroundPainter(),
          ),
        ),

        // ── Labels quartiers ───────────────────────
        ..._buildAreaLabels(),

        // ── Marqueurs ─────────────────────────────
        ..._buildMarkers(),

        // ── Boutons flottants droite ───────────────
        Positioned(
          right: CliinAppConstants.spacingL,
          bottom: CliinAppConstants.spacingXL,
          child: Column(
            children: [
              _buildFloatingButton(
                icon: Icons.layers_rounded,
                onTap: onLayersTap,
              ),
              const SizedBox(height: CliinAppConstants.spacingS),
              _buildFloatingButton(
                icon: Icons.navigation_rounded,
                onTap: onRecenterTap,
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAreaLabels() {
    const labels = [
      (text: 'COCODY',           top: 0.06, left: 0.42),
      (text: 'ANGRÉ',            top: 0.22, left: 0.34),
      (text: 'RIVIERA',          top: 0.22, left: 0.60),
      (text: 'RIVIERA\nPALMERAIE', top: 0.44, left: 0.62),
      (text: 'YOPOUGON',         top: 0.56, left: 0.04),
      (text: 'PLATEAU',          top: 0.72, left: 0.24),
      (text: 'MARCORY',          top: 0.72, left: 0.58),
      (text: 'Baie de\nCocody',  top: 0.28, left: 0.80),
      (text: 'Lagune Ébrié',     top: 0.88, left: 0.32),
    ];

    return labels.map((l) {
      return Positioned(
        top: _pct(l.top, isTop: true),
        left: _pct(l.left, isTop: false),
        child: LayoutBuilder(
          builder: (context, _) => Text(
            l.text,
            textAlign: TextAlign.center,
            style: CliinAppTextStyles.bodySmall.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: l.text.contains('Baie') || l.text.contains('Lagune')
                  ? const Color(0xFF1E88E5)
                  : const Color(0xFF555555),
              letterSpacing: l.text == l.text.toUpperCase() ? 0.8 : 0,
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildMarkers() {
    return _markers.asMap().entries.map((entry) {
      final m = entry.value;
      return LayoutBuilder(
        builder: (context, constraints) {
          // Les positions sont calculées dans le Stack parent via Positioned
          return Positioned(
            top: _pct(m.top, isTop: true),
            left: _pct(m.left, isTop: false),
            child: m.isUserLocation
                ? _UserLocationMarker()
                : m.clusterCount != null
                    ? _ClusterMarker(color: m.color, count: m.clusterCount!)
                    : _ReportMarker(color: m.color),
          );
        },
      );
    }).toList();
  }

  // Helper pour convertir 0.0-1.0 en double — utilisé avec FractionallySizedBox
  // Ici on utilise des valeurs fixes basées sur la hauteur estimée de la carte
  double _pct(double ratio, {required bool isTop}) => ratio * 100;

  Widget _buildFloatingButton({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: CliinAppColors.textDark),
      ),
    );
  }
}

// ── Marqueur signalement ───────────────────────────────────────────
class _ReportMarker extends StatelessWidget {
  final Color color;
  const _ReportMarker({required this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.warning_amber_rounded,
      color: color,
      size: 32,
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}

// ── Cluster ────────────────────────────────────────────────────────
class _ClusterMarker extends StatelessWidget {
  final Color color;
  final int count;
  const _ClusterMarker({required this.color, required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          Icons.warning_amber_rounded,
          color: color,
          size: 38,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        Positioned(
          top: -4,
          right: -4,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Center(
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Position utilisateur ───────────────────────────────────────────
class _UserLocationMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.withValues(alpha: 0.15),
          ),
        ),
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.4),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Peintre de fond de carte ───────────────────────────────────────
class _MapBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Fond terre
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFE8F0E4),
    );

    final roadPaint = Paint()
      ..color = const Color(0xFFFFF9C4)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final roadPaintSmall = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final waterPaint = Paint()..color = const Color(0xFFB3E0F7);

    // Eau — baie droite
    final bayPath = Path()
      ..moveTo(size.width * 0.75, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.60)
      ..lineTo(size.width * 0.80, size.height * 0.55)
      ..lineTo(size.width * 0.75, size.height * 0.30)
      ..close();
    canvas.drawPath(bayPath, waterPaint);

    // Eau — lagune bas
    final lagunaPath = Path()
      ..moveTo(0, size.height * 0.82)
      ..lineTo(size.width * 0.70, size.height * 0.82)
      ..lineTo(size.width * 0.65, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(lagunaPath, waterPaint);

    // Routes principales
    // Axe horizontal principal
    canvas.drawLine(
      Offset(0, size.height * 0.50),
      Offset(size.width * 0.75, size.height * 0.45),
      roadPaint,
    );
    // Axe diagonal haut
    canvas.drawLine(
      Offset(size.width * 0.20, size.height * 0.20),
      Offset(size.width * 0.70, size.height * 0.35),
      roadPaint,
    );
    // Axe vertical centre
    canvas.drawLine(
      Offset(size.width * 0.45, 0),
      Offset(size.width * 0.40, size.height * 0.80),
      roadPaint,
    );
    // Axe diagonal bas
    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.55),
      Offset(size.width * 0.65, size.height * 0.78),
      roadPaint,
    );

    // Petites routes
    canvas.drawLine(
      Offset(size.width * 0.30, size.height * 0.35),
      Offset(size.width * 0.55, size.height * 0.60),
      roadPaintSmall,
    );
    canvas.drawLine(
      Offset(size.width * 0.55, size.height * 0.25),
      Offset(size.width * 0.60, size.height * 0.55),
      roadPaintSmall,
    );
  }

  @override
  bool shouldRepaint(_MapBackgroundPainter old) => false;
}