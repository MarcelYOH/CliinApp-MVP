// lib/features/reports/pages/proof_camera_page.dart
// Caméra preuve d'intervention (APRÈS)
// Design identique à ReportCameraPage — sans galerie

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
          _address = parts.isNotEmpty ? parts.join(', ') : widget.report.location;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            _buildHeader(),

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
                    child: _buildTipBanner(),
                  ),

                  // Coins viewfinder
                  const Positioned.fill(child: _ViewfinderCorners()),

                  // Contrôles latéraux (flash + flip) — sans galerie
                  Positioned(
                    right: CliinAppConstants.pagePadding,
                    top: 0,
                    bottom: 0,
                    child: Center(child: _buildSideControls()),
                  ),

                  // Chip position GPS
                  Positioned(
                    bottom: CliinAppConstants.spacingL,
                    left: 0,
                    right: 0,
                    child: Center(child: _buildPositionChip()),
                  ),
                ],
              ),
            ),

            // ── Barre de capture ─────────────────────────────────
            Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(
                  vertical: CliinAppConstants.spacingXL),
              child: _buildBottomBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(
          horizontal: CliinAppConstants.pagePadding,
          vertical: CliinAppConstants.spacingM),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: CliinAppConstants.spacingM),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Preuve d\'intervention',
                style: TextStyle(color: Colors.white,
                    fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Photo APRÈS — ${widget.report.reference}',
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildTipBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: CliinAppConstants.pagePadding),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        ),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: CliinAppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.camera_alt_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Prenez une ',
                style: TextStyle(color: Colors.white, fontSize: 12),
                children: [
                  TextSpan(
                    text: 'photo APRÈS',
                    style: TextStyle(
                        color: CliinAppColors.primary,
                        fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ' intervention pour prouver le traitement.'),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildSideControls() {
    // En mode fallback (image_picker), flash et changement de caméra
    // sont gérés par l'interface native du téléphone — on les masque ici.
    if (_useWebFallback) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Flash
        _SideButton(
          icon: _flashMode == FlashMode.off
              ? Icons.flash_off_rounded
              : Icons.flash_on_rounded,
          label: 'Flash',
          onTap: _toggleFlash,
          active: _flashMode != FlashMode.off,
        ),
        const SizedBox(height: CliinAppConstants.spacingL),
        // Changer caméra
        _SideButton(
          icon: Icons.flip_camera_ios_rounded,
          label: 'Changer\ncaméra',
          onTap: _flipCamera,
        ),
        // Pas de bouton galerie — galerie désactivée pour les preuves
      ],
    );
  }

  Widget _buildPositionChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.location_on_rounded,
            color: CliinAppColors.primary, size: 16),
        const SizedBox(width: 6),
        _isLoadingLocation
            ? const SizedBox(
                width: 12, height: 12,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: CliinAppColors.primary))
            : Text(_address,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildBottomBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Placeholder gauche — symétrie visuelle
        const SizedBox(width: 72),
        const SizedBox(width: 48),

        // Bouton capture
        GestureDetector(
          onTap: _isCapturing
              ? null
              : (_useWebFallback ? _captureViaImagePicker : _takePhoto),
          child: Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              color: _isCapturing
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.15),
            ),
            child: _isCapturing
                ? const CircularProgressIndicator(
                    color: CliinAppColors.primary, strokeWidth: 3)
                : const Icon(Icons.camera_alt_rounded,
                    color: Colors.white, size: 32),
          ),
        ),

        const SizedBox(width: 48),
        const SizedBox(width: 72),
      ],
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
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_outlined,
                    color: Colors.white54, size: 36),
              ),
              const SizedBox(height: 20),
              const Text('Appuyez sur le bouton ci-dessous\npour prendre la photo',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
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

// ─────────────────────────────────────────
// Bouton latéral réutilisable
// ─────────────────────────────────────────
class _SideButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _SideButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: active
              ? CliinAppColors.primary.withValues(alpha: 0.9)
              : Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
      const SizedBox(height: 4),
      Text(label,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
    ]),
  );
}

// ─────────────────────────────────────────
// Coins viewfinder — identique à ReportCameraPage
// ─────────────────────────────────────────
class _ViewfinderCorners extends StatelessWidget {
  const _ViewfinderCorners();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(CliinAppConstants.spacingXL),
      child: Stack(children: [
        Positioned(top: 0, left: 0, child: _Corner(topLeft: true)),
        Positioned(top: 0, right: 0, child: _Corner(topRight: true)),
        Positioned(bottom: 0, left: 0, child: _Corner(bottomLeft: true)),
        Positioned(bottom: 0, right: 0, child: _Corner(bottomRight: true)),
      ]),
    );
  }
}

class _Corner extends StatelessWidget {
  final bool topLeft, topRight, bottomLeft, bottomRight;
  const _Corner({
    this.topLeft = false, this.topRight = false,
    this.bottomLeft = false, this.bottomRight = false,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 24, height: 24,
    child: CustomPaint(painter: _CornerPainter(
      topLeft: topLeft, topRight: topRight,
      bottomLeft: bottomLeft, bottomRight: bottomRight,
    )),
  );
}

class _CornerPainter extends CustomPainter {
  final bool topLeft, topRight, bottomLeft, bottomRight;
  _CornerPainter({
    required this.topLeft, required this.topRight,
    required this.bottomLeft, required this.bottomRight,
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
      canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height), paint);
    }
    if (bottomLeft) {
      canvas.drawLine(Offset.zero, Offset(0, size.height), paint);
      canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), paint);
    }
    if (bottomRight) {
      canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height), paint);
      canvas.drawLine(Offset(size.width, size.height), Offset(0, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}