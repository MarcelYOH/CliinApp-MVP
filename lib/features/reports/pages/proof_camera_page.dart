// lib/features/reports/pages/proof_camera_page.dart
// Caméra dédiée à la preuve d'intervention (APRÈS)
// Galerie désactivée — photo obligatoire en temps réel
// GPS automatique après capture

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../features/home/models/report_model.dart';
import 'proof_upload_page.dart';

class ProofCameraPage extends StatefulWidget {
  final HomeReportModel report;

  const ProofCameraPage({super.key, required this.report});

  @override
  State<ProofCameraPage> createState() => _ProofCameraPageState();
}

class _ProofCameraPageState extends State<ProofCameraPage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _isFetchingGps = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _errorMessage = 'Aucune caméra disponible.');
        return;
      }
      final controller = CameraController(
        _cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _isInitialized = true;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Erreur caméra : ${e.toString()}');
    }
  }

  // ── Capture + GPS ─────────────────────────────────────────────
  Future<void> _capture() async {
    if (_controller == null || !_isInitialized || _isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      // 1. Prendre la photo
      final file = await _controller!.takePicture();

      // 2. Récupérer le GPS automatiquement
      setState(() => _isFetchingGps = true);
      double? latitude;
      double? longitude;

      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
        latitude = position.latitude;
        longitude = position.longitude;
      } catch (_) {
        // GPS indisponible → on utilise les coords du signalement
        // pour le MVP — sera détecté comme "non conforme" si différent
        latitude = widget.report.latitude;
        longitude = widget.report.longitude;
      }

      if (!mounted) return;

      // 3. Naviguer vers la page upload preuve
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProofUploadPage(
            report: widget.report,
            imagePath: file.path,
            proofLatitude: latitude ?? 0.0,
            proofLongitude: longitude ?? 0.0,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur capture : ${e.toString()}'),
          backgroundColor: CliinAppColors.alertRed,
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _isFetchingGps = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Prévisualisation caméra ───────────────────────
            if (_isInitialized && _controller != null)
              Positioned.fill(
                child: CameraPreview(_controller!),
              )
            else if (_errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(CliinAppConstants.pagePadding),
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.inter(
                        color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(
                    color: CliinAppColors.primary),
              ),

            // ── Header ────────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildHeader(),
            ),

            // ── Bannière info (galerie désactivée) ────────────
            Positioned(
              top: 72,
              left: CliinAppConstants.pagePadding,
              right: CliinAppConstants.pagePadding,
              child: _buildInfoBanner(),
            ),

            // ── Contrôles bas ─────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomControls(),
            ),

            // ── Overlay GPS en cours ──────────────────────────
            if (_isFetchingGps)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                          color: CliinAppColors.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Détection GPS en cours...',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: CliinAppConstants.pagePadding,
          vertical: CliinAppConstants.spacingM),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius:
                  BorderRadius.circular(CliinAppConstants.radiusMedium),
            ),
            child: const Icon(Icons.arrow_back,
                color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: CliinAppConstants.spacingM),
        Expanded(
          child: Text(
            'Preuve d\'intervention',
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
        ),
        // Référence du cas
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius:
                BorderRadius.circular(CliinAppConstants.radiusSmall),
          ),
          child: Text(
            widget.report.reference,
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ),
      ]),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius:
            BorderRadius.circular(CliinAppConstants.radiusMedium),
      ),
      child: Row(children: [
        const Icon(Icons.camera_alt_rounded,
            color: CliinAppColors.primary, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Prenez une photo APRÈS intervention. '
            'L\'importation depuis la galerie est désactivée.',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
          ),
        ),
      ]),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.fromLTRB(
          CliinAppConstants.pagePadding,
          CliinAppConstants.spacingL,
          CliinAppConstants.pagePadding,
          CliinAppConstants.spacingXL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Placeholder gauche (galerie désactivée — grisé)
          Opacity(
            opacity: 0.3,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius:
                    BorderRadius.circular(CliinAppConstants.radiusSmall),
              ),
              child: const Icon(Icons.photo_library_outlined,
                  color: Colors.white, size: 24),
            ),
          ),

          // Bouton capture
          GestureDetector(
            onTap: _isCapturing ? null : _capture,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                color: _isCapturing ? Colors.white38 : Colors.white24,
              ),
              child: _isCapturing
                  ? const CircularProgressIndicator(
                      color: CliinAppColors.primary, strokeWidth: 3)
                  : const Icon(Icons.camera_alt_rounded,
                      color: Colors.white, size: 32),
            ),
          ),

          // Bouton retourner caméra
          GestureDetector(
            onTap: () async {
              if (_cameras.length < 2) return;
              final current = _controller!.description;
              final next = _cameras.firstWhere(
                  (c) => c.lensDirection != current.lensDirection,
                  orElse: () => _cameras.first);
              await _controller!.dispose();
              final newController = CameraController(
                  next, ResolutionPreset.high, enableAudio: false);
              await newController.initialize();
              if (mounted) {
                setState(() => _controller = newController);
              }
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flip_camera_ios_outlined,
                  color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}