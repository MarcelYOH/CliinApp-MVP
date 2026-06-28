// lib/features/reports/pages/report_form_page.dart
// Page formulaire — étape 3 — CliinApp

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/user_location_service.dart';
import '../models/report_model.dart';
import '../../../../shared/models/report_category.dart';
import '../data/report_dummy_data.dart';
import '../widgets/report_stepper.dart';
import '../widgets/report_image_view.dart';
import 'report_upload_page.dart';

String _generateReportCode() {
  final n = 1000 + Random().nextInt(8999);
  return '#CLN-$n';
}

class ReportFormPage extends StatefulWidget {
  final String imagePath;
  final String address;

  const ReportFormPage({
    super.key,
    required this.imagePath,
    required this.address,
  });

  @override
  State<ReportFormPage> createState() => _ReportFormPageState();
}

class _ReportFormPageState extends State<ReportFormPage> {
  ReportCategory _selectedCategory = ReportCategory.depotsSauvages;
  ReportOrigin _selectedOrigin = ReportOrigin.espacePublic;
  ReportSeverity? _selectedSeverity;
  final TextEditingController _descController = TextEditingController();
  late TextEditingController _addressController;
  bool _isEditingAddress = false;
  double? _latitude;
  double? _longitude;
  bool _isRefreshingLocation = false;
  bool _gpsFailed = false;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.address);
    // Valeurs de repli en attendant la vraie position GPS ci-dessous.
    _latitude = ReportDummyData.detectedLatitude;
    _longitude = ReportDummyData.detectedLongitude;
    // addPostFrameCallback : évite "setState() called during build" car _refreshLocation appelle setState avant son premier await.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshLocation();
    });
  }

  @override
  void dispose() {
    _descController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _refreshLocation() async {
    setState(() {
      _isRefreshingLocation = true;
      _gpsFailed = false;
    });
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      final placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[];
        if (place.subLocality?.isNotEmpty == true) parts.add(place.subLocality!);
        if (place.locality?.isNotEmpty == true) parts.add(place.locality!);
        setState(() {
          _addressController.text =
              parts.isNotEmpty ? parts.join(', ') : widget.address;
          _latitude = position.latitude;
          _longitude = position.longitude;
          _isEditingAddress = false;
          _gpsFailed = false;
        });
        UserLocationService.instance.setKnownPosition(position);
      }
    } catch (e) {
      debugPrint('Erreur refresh GPS: $e');
      setState(() {
        _gpsFailed = true;
        _latitude = null;
        _longitude = null;
        _isEditingAddress = true;
      });
    } finally {
      setState(() => _isRefreshingLocation = false);
    }
  }

  void _publish() {
    if (_selectedSeverity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez sélectionner un niveau d\'urgence',
              style: GoogleFonts.inter()),
          backgroundColor: CliinAppColors.alertRed,
        ),
      );
      return;
    }
    final report = ReportModel(
      imagePath: widget.imagePath,
      reportCode: _generateReportCode(),
      title: _selectedCategory.label,
      category: _selectedCategory,
      severity: _selectedSeverity,
      origin: _selectedOrigin,
      description: _descController.text.trim(),
      address: _addressController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      createdAt: DateTime.now(),
    );
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => ReportUploadPage(report: report)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CliinAppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: CliinAppConstants.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: CliinAppConstants.spacingS),
                    const ReportStepper(currentStep: 3),
                    const SizedBox(height: CliinAppConstants.spacingM),
                    // ── Photo + Adresse sur la même ligne ──
                    _buildPhotoAndLocationRow(context),
                    const SizedBox(height: CliinAppConstants.spacingL),
                    // ── Catégorie ──
                    _buildCategorySection(),
                    const SizedBox(height: CliinAppConstants.spacingL),
                    // ── Provenance ──
                    _buildOriginSection(),
                    const SizedBox(height: CliinAppConstants.spacingL),
                    // ── Gravité ──
                    _buildSeveritySection(),
                    const SizedBox(height: CliinAppConstants.spacingL),
                    // ── Description ──
                    _buildDescriptionSection(),
                    const SizedBox(height: CliinAppConstants.spacingL),
                    // ── Bouton publier ──
                    _buildPublishButton(),
                    const SizedBox(height: CliinAppConstants.spacingXL),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: CliinAppConstants.pagePadding,
          vertical: CliinAppConstants.spacingS),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: CliinAppColors.primaryLight,
                borderRadius:
                    BorderRadius.circular(CliinAppConstants.radiusMedium),
              ),
              child: const Icon(Icons.arrow_back,
                  color: CliinAppColors.primary, size: 18),
            ),
          ),
          Expanded(
            child: Text(
              'Nouveau signalement',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: CliinAppColors.textDark),
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: CliinAppColors.primaryLight,
              shape: BoxShape.circle,
              border: Border.all(color: CliinAppColors.primary, width: 1),
            ),
            child: const Icon(Icons.question_mark_rounded,
                color: CliinAppColors.primary, size: 16),
          ),
        ],
      ),
    );
  }

  // ── Photo + Adresse côte à côte ────────────────────────────────
  Widget _buildPhotoAndLocationRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Photo
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Photo',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CliinAppColors.textDark)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(CliinAppConstants.radiusSmall),
              child: ReportImageView(
                imagePath: widget.imagePath,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text('Changer',
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CliinAppColors.primary)),
            ),
          ],
        ),

        const SizedBox(width: CliinAppConstants.spacingM),

        // Adresse
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Localisation',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CliinAppColors.textDark)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(CliinAppConstants.spacingS),
                decoration: BoxDecoration(
                  color: CliinAppColors.cardWhite,
                  borderRadius:
                      BorderRadius.circular(CliinAppConstants.radiusSmall),
                  border: Border.all(color: CliinAppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: CliinAppColors.primary, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _isEditingAddress
                              ? TextField(
                                  controller: _addressController,
                                  autofocus: true,
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: CliinAppColors.textDark),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    border: InputBorder.none,
                                  ),
                                  onSubmitted: (_) => setState(
                                      () => _isEditingAddress = false),
                                )
                              : Text(
                                  _addressController.text,
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: CliinAppColors.textDark),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                        GestureDetector(
                          onTap: () => setState(
                              () => _isEditingAddress = !_isEditingAddress),
                          child: Icon(
                            _isEditingAddress
                                ? Icons.check_circle
                                : Icons.edit_outlined,
                            color: CliinAppColors.primary,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                    if (_latitude != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${_latitude!.toStringAsFixed(3)}°N  ${_longitude!.toStringAsFixed(3)}°W',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            color: CliinAppColors.textSecondary),
                      ),
                    ] else if (_gpsFailed) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_off_rounded,
                              color: CliinAppColors.alertOrange, size: 12),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'GPS indisponible — vérifiez/corrigez l\'adresse ci-dessus',
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: CliinAppColors.alertOrange),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _isRefreshingLocation ? null : _refreshLocation,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _isRefreshingLocation
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: CliinAppColors.primary),
                                )
                              : const Icon(Icons.refresh,
                                  color: CliinAppColors.primary, size: 12),
                          const SizedBox(width: 3),
                          Text('Actualiser GPS',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: CliinAppColors.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Catégorie — chips scrollables horizontalement ───────────────
  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CliinAppColors.textDark),
            children: const [
              TextSpan(text: 'Catégorie '),
              TextSpan(
                  text: '*',
                  style: TextStyle(color: CliinAppColors.alertRed)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 72,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: ReportCategory.values.map((cat) {
              final isSelected = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cat.color.withValues(alpha: 0.10)
                        : CliinAppColors.cardWhite,
                    borderRadius:
                        BorderRadius.circular(CliinAppConstants.radiusSmall),
                    border: Border.all(
                      color:
                          isSelected ? cat.color : CliinAppColors.divider,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cat.icon,
                          color: isSelected
                              ? cat.color
                              : CliinAppColors.textSecondary,
                          size: 20),
                      const SizedBox(height: 4),
                      Text(
                        cat.label,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isSelected
                              ? cat.color
                              : CliinAppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Provenance — chips scrollables, pré-sélection espacePublic ─
  Widget _buildOriginSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Provenance',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CliinAppColors.textDark)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: CliinAppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('pré-sélectionné',
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: CliinAppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 72,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: ReportOrigin.values.map((origin) {
              final isSelected = _selectedOrigin == origin;
              return GestureDetector(
                onTap: () => setState(() => _selectedOrigin = origin),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? CliinAppColors.primary.withValues(alpha: 0.10)
                        : CliinAppColors.cardWhite,
                    borderRadius:
                        BorderRadius.circular(CliinAppConstants.radiusSmall),
                    border: Border.all(
                      color: isSelected
                          ? CliinAppColors.primary
                          : CliinAppColors.divider,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(origin.icon,
                          color: isSelected
                              ? CliinAppColors.primary
                              : CliinAppColors.textSecondary,
                          size: 20),
                      const SizedBox(height: 4),
                      Text(
                        origin.label,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isSelected
                              ? CliinAppColors.primary
                              : CliinAppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        Text('Déjà rempli — modifiable en 1 tap si besoin, sinon rien à faire.',
            style: GoogleFonts.inter(
                fontSize: 11, color: CliinAppColors.textSecondary)),
      ],
    );
  }

  // ── Gravité — 4 boutons compacts ───────────────────────────────
  Widget _buildSeveritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CliinAppColors.textDark),
            children: const [
              TextSpan(text: 'Niveau d\'urgence '),
              TextSpan(
                  text: '*',
                  style: TextStyle(color: CliinAppColors.alertRed)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: ReportSeverity.values.map((sev) {
            final isSelected = _selectedSeverity == sev;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedSeverity = sev),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: EdgeInsets.only(
                      right: sev != ReportSeverity.critique ? 6 : 0),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? sev.bgColor
                        : CliinAppColors.cardWhite,
                    borderRadius:
                        BorderRadius.circular(CliinAppConstants.radiusSmall),
                    border: Border.all(
                      color:
                          isSelected ? sev.color : CliinAppColors.divider,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(sev.icon, color: sev.color, size: 18),
                      const SizedBox(height: 3),
                      Text(sev.label,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isSelected
                                ? sev.color
                                : CliinAppColors.textSecondary,
                          )),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Description — compacte ─────────────────────────────────────
  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Description (facultatif)',
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CliinAppColors.textDark)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: CliinAppColors.cardWhite,
            borderRadius:
                BorderRadius.circular(CliinAppConstants.radiusSmall),
            border: Border.all(color: CliinAppColors.divider),
          ),
          child: TextField(
            controller: _descController,
            maxLines: 3,
            maxLength: ReportDummyData.formDescriptionMaxLength,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.inter(
                fontSize: 13, color: CliinAppColors.textDark),
            decoration: InputDecoration(
              hintText: ReportDummyData.formDescriptionHint,
              hintStyle: GoogleFonts.inter(
                  fontSize: 13, color: CliinAppColors.textSecondary),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.all(CliinAppConstants.spacingM),
              counterStyle: GoogleFonts.inter(
                  fontSize: 10, color: CliinAppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  // ── Bouton publier ─────────────────────────────────────────────
  Widget _buildPublishButton() {
    return GestureDetector(
      onTap: _publish,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: CliinAppColors.primary,
          borderRadius:
              BorderRadius.circular(CliinAppConstants.radiusMedium),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.send,
                color: CliinAppColors.textWhite, size: 18),
            const SizedBox(width: CliinAppConstants.spacingM),
            Text('Publier le cas',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CliinAppColors.textWhite)),
          ],
        ),
      ),
    );
  }
}