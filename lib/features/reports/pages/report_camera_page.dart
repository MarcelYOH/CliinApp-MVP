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
import 'report_preview_page.dart';

// ─────────────────────────────────────────
// Page — ReportCameraPage
// ─────────────────────────────────────────
class ReportCameraPage extends StatefulWidget {
  const ReportCameraPage({super.key});

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
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      await _controller?.dispose();

      final controller = CameraController(
        _cameras[_currentCameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _controller = controller;
      await controller.initialize();
      await controller.setFlashMode(_flashMode);

      if (!mounted) return;
      setState(() => _isCameraReady = true);
    } catch (e) {
      debugPrint('Erreur init caméra: $e');
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

      // ✅ Fix : utiliser LocationSettings au lieu de desiredAccuracy
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ReportPreviewPage(imagePath: imagePath, address: _address),
      ),
    ).then((_) {
      if (mounted) setState(() => _isCapturing = false);
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
                  const Positioned.fill(child: _ViewfinderCorners()),
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
                onShutterTap: _takePhoto,
                isCapturing: _isCapturing,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
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
// Coins viewfinder
// ─────────────────────────────────────────
class _ViewfinderCorners extends StatelessWidget {
  const _ViewfinderCorners();

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
