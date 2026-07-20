// lib/features/groups/pages/group_photo_adjust_page.dart
// Recadrage simple (repositionnement vertical) d'une photo de groupe —
// logo (cercle) ou photo de couverture (rectangle) — juste après la prise
// ou la sélection, avant validation finale. Pas de recadrage pixel (pas de
// réencodage de fichier) : seul un point d'alignement vertical est choisi
// et appliqué ensuite partout où la photo est affichée en BoxFit.cover
// (voir GroupModel.photoAlignY/bannerAlignY, buildReportImage).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/report_card.dart' show buildReportImage;

class GroupPhotoAdjustPage extends StatefulWidget {
  final String imagePath;
  final bool isCircular;
  final double initialAlignY;

  const GroupPhotoAdjustPage({
    super.key,
    required this.imagePath,
    required this.isCircular,
    this.initialAlignY = 0.0,
  });

  @override
  State<GroupPhotoAdjustPage> createState() => _GroupPhotoAdjustPageState();
}

class _GroupPhotoAdjustPageState extends State<GroupPhotoAdjustPage> {
  late double _alignY = widget.initialAlignY;

  static const double _frameHeight = 260;
  static const double _frameWidthRect = double.infinity;

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _alignY =
          (_alignY - details.delta.dy / (_frameHeight / 2)).clamp(-1.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CliinAppColors.background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: CliinAppConstants.spacingM),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: CliinAppConstants.pagePadding),
              child: Text(
                'Faites glisser la photo pour la repositionner.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: CliinAppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: CliinAppConstants.spacingL),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onVerticalDragUpdate: _onDragUpdate,
                  child: ClipRRect(
                    borderRadius: widget.isCircular
                        ? BorderRadius.circular(999)
                        : BorderRadius.circular(CliinAppConstants.radiusMedium),
                    child: SizedBox(
                      width: widget.isCircular ? _frameHeight : _frameWidthRect,
                      height: _frameHeight,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          buildReportImage(
                            widget.imagePath,
                            fit: BoxFit.cover,
                            alignment: Alignment(0, _alignY),
                          ),
                          IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: CliinAppColors.primary,
                                  width: 2,
                                ),
                                borderRadius: widget.isCircular
                                    ? BorderRadius.circular(999)
                                    : BorderRadius.circular(
                                        CliinAppConstants.radiusMedium),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: CliinAppConstants.spacingL),
            Center(
              child: GestureDetector(
                onTap: () => setState(() => _alignY = 0.0),
                child: Text(
                  'Recentrer',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CliinAppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                CliinAppConstants.pagePadding,
                CliinAppConstants.spacingL,
                CliinAppConstants.pagePadding,
                MediaQuery.of(context).padding.bottom +
                    CliinAppConstants.spacingL,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _alignY),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CliinAppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(CliinAppConstants.radiusMedium),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Valider',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CliinAppColors.textWhite,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        CliinAppConstants.pagePadding,
        MediaQuery.of(context).padding.top + CliinAppConstants.spacingM,
        CliinAppConstants.pagePadding,
        0,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context, widget.initialAlignY),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: CliinAppColors.primaryLight,
                borderRadius:
                    BorderRadius.circular(CliinAppConstants.radiusMedium),
              ),
              child: const Icon(Icons.arrow_back,
                  color: CliinAppColors.primary, size: 20),
            ),
          ),
          Expanded(
            child: Text(
              widget.isCircular ? 'Ajuster le logo' : 'Ajuster la couverture',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: CliinAppColors.textDark,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}
