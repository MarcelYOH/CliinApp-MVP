import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../data/report_dummy_data.dart';
import '../widgets/report_stepper.dart';
import '../widgets/report_image_view.dart';
import 'report_form_page.dart';

// ─────────────────────────────────────────
// Page — ReportPreviewPage
// Aperçu de la photo avant validation (étape 2)
// ─────────────────────────────────────────
class ReportPreviewPage extends StatefulWidget {
  final String imagePath;
  final String address;
  // Mode remplacement de photo : "Continuer" renvoie le chemin de la
  // photo à l'appelant au lieu d'enchaîner sur un nouveau signalement.
  final bool replaceMode;
  // Photo de profil (pas un signalement) : masque la position GPS et
  // les textes propres à un cas d'insalubrité.
  final bool isAvatarMode;

  const ReportPreviewPage({
    super.key,
    required this.imagePath,
    required this.address,
    this.replaceMode = false,
    this.isAvatarMode = false,
  });

  @override
  State<ReportPreviewPage> createState() => _ReportPreviewPageState();
}

class _ReportPreviewPageState extends State<ReportPreviewPage> {
  // Adresse affichée — peut être modifiée manuellement
  late String _currentAddress;

  @override
  void initState() {
    super.initState();
    _currentAddress = widget.address;
  }

  // ─────────────────────────────────────────
  // Dialog de modification manuelle de l'adresse
  // ─────────────────────────────────────────
  void _showModifyAddressDialog() {
    final TextEditingController controller =
        TextEditingController(text: _currentAddress);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        ),
        title: Row(
          children: [
            const Icon(Icons.edit_location_alt_outlined,
                color: CliinAppColors.primary, size: 22),
            const SizedBox(width: CliinAppConstants.spacingS),
            Text(
              'Modifier l\'adresse',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: CliinAppColors.textDark,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Les coordonnées GPS restent celles détectées automatiquement. Seul le libellé d\'adresse sera modifié.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: CliinAppColors.textSecondary,
              ),
            ),
            const SizedBox(height: CliinAppConstants.spacingL),
            // Champ de saisie
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: CliinAppColors.textDark,
              ),
              decoration: InputDecoration(
                labelText: 'Adresse',
                labelStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: CliinAppColors.textSecondary,
                ),
                hintText: 'Ex: Cocody, Angré 8e tranche',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: CliinAppColors.textSecondary,
                ),
                prefixIcon: const Icon(Icons.location_on_outlined,
                    color: CliinAppColors.primary, size: 20),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(CliinAppConstants.radiusSmall),
                  borderSide: const BorderSide(color: CliinAppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(CliinAppConstants.radiusSmall),
                  borderSide: const BorderSide(
                      color: CliinAppColors.primary, width: 1.5),
                ),
                filled: true,
                fillColor: CliinAppColors.primaryLight,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: CliinAppConstants.spacingM,
                  vertical: CliinAppConstants.spacingM,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Annuler
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Annuler',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: CliinAppColors.textSecondary,
              ),
            ),
          ),
          // Confirmer
          ElevatedButton(
            onPressed: () {
              final newAddress = controller.text.trim();
              if (newAddress.isNotEmpty) {
                setState(() => _currentAddress = newAddress);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CliinAppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(CliinAppConstants.radiusSmall),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: CliinAppConstants.spacingL,
                vertical: CliinAppConstants.spacingM,
              ),
            ),
            child: Text(
              'Confirmer',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CliinAppColors.textWhite,
              ),
            ),
          ),
        ],
      ),
    );
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
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  CliinAppConstants.pagePadding,
                  0,
                  CliinAppConstants.pagePadding,
                  MediaQuery.of(context).padding.bottom +
                      CliinAppConstants.spacingXL,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: CliinAppConstants.spacingM),
                    if (!widget.isAvatarMode) ...[
                      const ReportStepper(currentStep: 2),
                      const SizedBox(height: CliinAppConstants.spacingL),
                    ],
                    _buildVerifyBanner(),
                    const SizedBox(height: CliinAppConstants.spacingL),
                    _buildPhotoPreview(),
                    if (!widget.isAvatarMode) ...[
                      const SizedBox(height: CliinAppConstants.spacingL),
                      _buildPositionRow(),
                    ],
                  ],
                ),
              ),
            ),
            _buildBottomSection(context),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        CliinAppConstants.pagePadding,
        MediaQuery.of(context).padding.top + CliinAppConstants.spacingM,
        CliinAppConstants.pagePadding,
        CliinAppConstants.spacingM,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
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
              widget.isAvatarMode ? 'Aperçu de la photo' : 'Aperçu du signalement',
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

  // ─────────────────────────────────────────
  Widget _buildVerifyBanner() {
    return Container(
      padding: const EdgeInsets.all(CliinAppConstants.spacingL),
      decoration: BoxDecoration(
        color: CliinAppColors.primaryLight,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: CliinAppColors.primary,
              borderRadius:
                  BorderRadius.circular(CliinAppConstants.radiusSmall),
            ),
            child: const Icon(Icons.verified_outlined,
                color: CliinAppColors.textWhite, size: 20),
          ),
          const SizedBox(width: CliinAppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ReportDummyData.previewVerifyTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CliinAppColors.textDark,
                  ),
                ),
                Text(
                  widget.isAvatarMode
                      ? 'Assurez-vous que votre visage est bien visible.'
                      : ReportDummyData.previewVerifySubtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CliinAppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  Widget _buildPhotoPreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: ReportImageView(
          imagePath: widget.imagePath,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  Widget _buildPositionRow() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CliinAppConstants.spacingL,
        vertical: CliinAppConstants.spacingM,
      ),
      decoration: BoxDecoration(
        color: CliinAppColors.cardWhite,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        border: Border.all(color: CliinAppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on,
              color: CliinAppColors.primary, size: 20),
          const SizedBox(width: CliinAppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Position détectée',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: CliinAppColors.textSecondary,
                  ),
                ),
                Text(
                  _currentAddress,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CliinAppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          // ✅ Bouton Modifier — ouvre le dialog de saisie
          GestureDetector(
            onTap: _showModifyAddressDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: CliinAppConstants.spacingM,
                vertical: CliinAppConstants.spacingXS,
              ),
              decoration: BoxDecoration(
                color: CliinAppColors.primaryLight,
                borderRadius:
                    BorderRadius.circular(CliinAppConstants.radiusSmall),
                border: Border.all(color: CliinAppColors.primary),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_outlined,
                      color: CliinAppColors.primary, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Modifier',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CliinAppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  Widget _buildBottomSection(BuildContext context) {
    return Container(
      color: CliinAppColors.background,
      padding: const EdgeInsets.fromLTRB(
        CliinAppConstants.pagePadding,
        CliinAppConstants.spacingM,
        CliinAppConstants.pagePadding,
        CliinAppConstants.spacingL,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Reprendre la photo
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: CliinAppColors.cardWhite,
                      borderRadius: BorderRadius.circular(
                          CliinAppConstants.radiusMedium),
                      border: Border.all(color: CliinAppColors.primary),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt_outlined,
                            color: CliinAppColors.primary, size: 18),
                        const SizedBox(width: CliinAppConstants.spacingS),
                        Text(
                          'Reprendre',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: CliinAppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: CliinAppConstants.spacingM),

              // Continuer — passe l'adresse potentiellement modifiée
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (widget.replaceMode) {
                      Navigator.pop(context, widget.imagePath);
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportFormPage(
                          imagePath: widget.imagePath,
                          address: _currentAddress, // ✅ adresse modifiée
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: CliinAppColors.primary,
                      borderRadius: BorderRadius.circular(
                          CliinAppConstants.radiusMedium),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continuer',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: CliinAppColors.textWhite,
                          ),
                        ),
                        const SizedBox(width: CliinAppConstants.spacingS),
                        const Icon(Icons.arrow_forward,
                            color: CliinAppColors.textWhite, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: CliinAppConstants.spacingM),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_outlined,
                  color: CliinAppColors.primary, size: 16),
              const SizedBox(width: CliinAppConstants.spacingS),
              Flexible(
                child: Text(
                  widget.isAvatarMode
                      ? 'Votre photo de profil aide la communauté à vous reconnaître.'
                      : ReportDummyData.previewBottomText,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CliinAppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}