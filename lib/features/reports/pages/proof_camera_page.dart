// lib/features/reports/pages/proof_camera_page.dart
// Caméra preuve d'intervention (APRÈS)
// Réutilise les mêmes composants visuels que ReportCameraPage — sans galerie

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../features/home/models/home_report_model.dart';
import '../widgets/report_camera_header.dart';
import '../widgets/report_camera_tip_banner.dart';
import '../widgets/report_camera_side_controls.dart';
import '../widgets/report_camera_position_chip.dart';
import '../widgets/report_camera_bottom_bar.dart';
import '../widgets/report_camera_viewfinder_corners.dart';
import 'proof_preview_page.dart';

class ProofCameraPage extends StatefulWidget {
  final HomeReportModel report;
  const ProofCameraPage({super.key, required this.report});

  @override
  State<ProofCameraPage> createState() => _ProofCameraPageState();
}

class _ProofCameraPageState extends State<ProofCameraPage>
    with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _currentCameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;
  bool _isCapturing = false;
  bool _isCameraReady = false;

  String _address = 'Détection en cours...';
  bool _isLoadingLocation = true;
  double? _latitude;
  double? _longitude;

  // Fallback Web/navigateur : utilisé quand le plugin camera natif
  // n'arrive pas à s'initialiser (contexte non sécurisé, http via IP locale,
  // permissions navigateur, etc.)
  bool _useWebFallback = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initCamera();
    _detectLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Voir ReportCameraPage._didChangeAppLifecycleState — Android efface le
    // mode immersif (barre de statut réapparaît par-dessus le header) dès
    // qu'un dialogue système (permission caméra/localisation) est affiché ;
    // il faut le réappliquer à chaque retour au premier plan.
    if (state == AppLifecycleState.resumed) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras().timeout(
        const Duration(seconds: 5),
        onTimeout: () => [],
      );
      if (_cameras.isEmpty) {
        _activateWebFallback();
        return;
      }

      await _controller?.dispose();

      final controller = CameraController(
        _cameras[_currentCameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _controller = controller;

      // Timeout sur l'initialisation : si le navigateur/contexte bloque
      // l'accès caméra (http via IP locale, permissions refusées
      // silencieusement, etc.), on bascule sur image_picker au lieu
      // de laisser le loader tourner indéfiniment.
      await controller.initialize().timeout(
        const Duration(seconds: 6),
        onTimeout: () {
          throw TimeoutException('Caméra non disponible — bascule fallback');
        },
      );
      await controller.setFlashMode(_flashMode);

      if (!mounted) return;
      setState(() => _isCameraReady = true);
    } catch (e) {
      debugPrint('Erreur init caméra preuve: $e — activation fallback');
      _activateWebFallback();
    }
  }

  // ── Fallback : ouvre directement la caméra native via image_picker
  // Utilisé quand le plugin camera ne peut pas s'initialiser
  // (contexte web non sécurisé, permissions, etc.)
  void _activateWebFallback() {
    if (!mounted) return;
    setState(() {
      _useWebFallback = true;
    });
  }

  Future<void> _captureViaImagePicker() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 90,
      );

      if (photo == null) {
        if (mounted) setState(() => _isCapturing = false);
        return;
      }
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProofPreviewPage(
            report: widget.report,
            imagePath: photo.path,
            address: _address,
            proofLatitude: _latitude ?? widget.report.latitude ?? 0.0,
            proofLongitude: _longitude ?? widget.report.longitude ?? 0.0,
          ),
        ),
      ).then((_) {
        if (mounted) setState(() => _isCapturing = false);
      });
    } catch (e) {
      debugPrint('Erreur capture fallback: $e');
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _detectLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _address = widget.report.location;
          _latitude = widget.report.latitude;
          _longitude = widget.report.longitude;
          _isLoadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      _latitude = position.latitude;
      _longitude = position.longitude;

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[];
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          parts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          parts.add(place.locality!);
        }
        setState(() {
          _address = parts.isNotEmpty
              ? parts.join(', ')
              : widget.report.location;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur GPS preuve: $e');
      setState(() {
        _address = widget.report.location;
        _latitude = widget.report.latitude;
        _longitude = widget.report.longitude;
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _takePhoto() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final XFile photo = await _controller!.takePicture();
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProofPreviewPage(
            report: widget.report,
            imagePath: photo.path,
            address: _address,
            proofLatitude: _latitude ?? widget.report.latitude ?? 0.0,
            proofLongitude: _longitude ?? widget.report.longitude ?? 0.0,
          ),
        ),
      ).then((_) {
        if (mounted) setState(() => _isCapturing = false);
      });
    } catch (e) {
      debugPrint('Erreur capture preuve: $e');
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final next = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    await _controller!.setFlashMode(next);
    setState(() => _flashMode = next);
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    setState(() => _isCameraReady = false);
    await _initCamera();
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        ),
        title: const Text('Aide — Photo preuve'),
        content: const Text(
          'Prenez une photo claire du lieu après intervention, pour prouver '
          'que le problème a bien été traité.\n\n'
          '• Cadrez le même endroit que la photo initiale\n'
          '• Assurez-vous d\'un bon éclairage\n'
          '• Évitez les photos floues',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Compris',
              style: TextStyle(color: CliinAppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            ReportCameraHeader(
              onBackTap: () => Navigator.pop(context),
              onHelpTap: _showHelpDialog,
              title: 'Preuve d\'intervention',
              subtitle: 'Photo APRÈS — ${widget.report.reference}',
            ),

            // ── Preview + overlays ───────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  _buildCameraPreview(),

                  // Bannière info APRÈS
                  Positioned(
                    top: CliinAppConstants.spacingM,
                    left: 0,
                    right: 0,
                    child: const ReportCameraTipBanner(
                      text:
                          'Prenez une photo APRÈS intervention pour prouver le traitement.',
                      highlightWord: 'photo APRÈS',
                    ),
                  ),

                  // Coins viewfinder
                  const Positioned.fill(child: ReportCameraViewfinderCorners()),

                  // Contrôles latéraux (flash + flip) — sans galerie
                  if (!_useWebFallback)
                    Positioned(
                      right: CliinAppConstants.pagePadding,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: ReportCameraSideControls(
                          flashMode: _flashMode,
                          onFlashTap: _toggleFlash,
                          onFlipTap: _flipCamera,
                        ),
                      ),
                    ),

                  // Chip position GPS
                  Positioned(
                    bottom: CliinAppConstants.spacingL,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: ReportCameraPositionChip(
                        address: _address,
                        isLoading: _isLoadingLocation,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Barre de capture ─────────────────────────────────
            Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(
                vertical: CliinAppConstants.spacingXL,
              ),
              child: ReportCameraBottomBar(
                onShutterTap: _useWebFallback
                    ? _captureViaImagePicker
                    : _takePhoto,
                isCapturing: _isCapturing,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    // Mode fallback : caméra native indisponible (Web via IP locale, etc.)
    // On affiche un état clair invitant à appuyer sur le bouton de capture
    if (_useWebFallback) {
      return Container(
        color: const Color(0xFF1A1A1A),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white54,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Appuyez sur le bouton ci-dessous\npour prendre la photo',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isCameraReady || _controller == null) {
      return Container(
        color: const Color(0xFF1A1A1A),
        child: const Center(
          child: CircularProgressIndicator(color: CliinAppColors.primary),
        ),
      );
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.previewSize!.height,
          height: _controller!.value.previewSize!.width,
          child: CameraPreview(_controller!),
        ),
      ),
    );
  }
}
