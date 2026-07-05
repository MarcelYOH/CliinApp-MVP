import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../data/report_dummy_data.dart';
import '../widgets/report_camera_header.dart';
import '../widgets/report_camera_tip_banner.dart';
import '../widgets/report_camera_side_controls.dart';
import '../widgets/report_camera_position_chip.dart';
import '../widgets/report_camera_bottom_bar.dart';
import '../widgets/report_camera_viewfinder_corners.dart';
import 'report_preview_page.dart';

// ─────────────────────────────────────────
// Page — ReportCameraPage
// ─────────────────────────────────────────
class ReportCameraPage extends StatefulWidget {
  // Mode remplacement de photo (édition d'un cas existant) : au lieu
  // d'enchaîner sur un nouveau signalement, la page renvoie le chemin
  // de la photo prise à l'appelant via Navigator.pop.
  final bool replaceMode;

  const ReportCameraPage({super.key, this.replaceMode = false});

  @override
  State<ReportCameraPage> createState() => _ReportCameraPageState();
}

class _ReportCameraPageState extends State<ReportCameraPage>
    with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _currentCameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;
  bool _isCapturing = false;
  bool _isCameraReady = false;

  String _address = 'Détection en cours...';
  bool _isLoadingLocation = true;

  // Fallback : utilisé quand le plugin camera natif n'arrive pas à
  // s'initialiser (contexte non sécurisé, http via IP locale,
  // permissions navigateur bloquées silencieusement, etc.)
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

  // ─────────────────────────────────────────
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
      // l'accès caméra, on bascule sur image_picker au lieu de laisser
      // le loader tourner indéfiniment.
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
      debugPrint('Erreur init caméra: $e — activation fallback');
      _activateWebFallback();
    }
  }

  // ── Fallback : ouvre directement la caméra native via image_picker ──
  void _activateWebFallback() {
    if (!mounted) return;
    setState(() => _useWebFallback = true);
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
      _navigateToPreview(photo.path);
    } catch (e) {
      debugPrint('Erreur capture fallback: $e');
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  // ─────────────────────────────────────────
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
          _address = ReportDummyData.detectedAddress;
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
              : ReportDummyData.detectedAddress;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur GPS: $e');
      setState(() {
        _address = ReportDummyData.detectedAddress;
        _isLoadingLocation = false;
      });
    }
  }

  // ─────────────────────────────────────────
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
      _navigateToPreview(photo.path);
    } catch (e) {
      debugPrint('Erreur prise de photo: $e');
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

  Future<void> _openGallery() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (image != null && mounted) {
      _navigateToPreview(image.path);
    }
  }

  void _navigateToPreview(String imagePath) {
    Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => ReportPreviewPage(
          imagePath: imagePath,
          address: _address,
          replaceMode: widget.replaceMode,
        ),
      ),
    ).then((result) {
      if (!mounted) return;
      if (widget.replaceMode && result != null) {
        Navigator.pop(context, result);
        return;
      }
      setState(() => _isCapturing = false);
    });
  }

  // ─────────────────────────────────────────
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
            ),
            Expanded(
              child: Stack(
                children: [
                  _buildCameraPreview(),
                  Positioned(
                    top: CliinAppConstants.spacingM,
                    left: 0,
                    right: 0,
                    child: ReportCameraTipBanner(
                      text: ReportDummyData.cameraTipText,
                      highlightWord: ReportDummyData.cameraHighlightWord,
                    ),
                  ),
                  const Positioned.fill(child: ReportCameraViewfinderCorners()),
                  // Contrôles latéraux masqués en mode fallback :
                  // flash et changement de caméra sont gérés par
                  // l'app caméra native du téléphone dans ce mode.
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
                          onGalleryTap: _openGallery,
                        ),
                      ),
                    ),
                  // En mode fallback, on garde quand même l'accès galerie
                  if (_useWebFallback)
                    Positioned(
                      right: CliinAppConstants.pagePadding,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _FallbackGalleryButton(onTap: _openGallery),
                      ),
                    ),
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
            Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(
                vertical: CliinAppConstants.spacingXL,
              ),
              child: ReportCameraBottomBar(
                onShutterTap:
                    _useWebFallback ? _captureViaImagePicker : _takePhoto,
                isCapturing: _isCapturing,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    // Mode fallback : caméra native indisponible — état clair
    // invitant à appuyer sur le bouton de capture
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
                child: const Icon(Icons.camera_alt_outlined,
                    color: Colors.white54, size: 36),
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

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        ),
        title: const Text('Aide — Photo'),
        content: const Text(
          'Prenez une photo claire et nette du problème d\'insalubrité.\n\n'
          '• Cadrez bien le problème\n'
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
}

// ─────────────────────────────────────────
// Bouton galerie — affiché seul en mode fallback
// ─────────────────────────────────────────
class _FallbackGalleryButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FallbackGalleryButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.photo_library_outlined,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(height: 4),
            const Text(
              'Galerie',
              style: TextStyle(
                  color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
}

