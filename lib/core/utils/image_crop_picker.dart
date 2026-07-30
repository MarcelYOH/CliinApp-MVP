// lib/core/utils/image_crop_picker.dart
// Sélection directe depuis la galerie + recadrage fiable (image_cropper) —
// utilisé pour les photos de profil/couverture (Groupes) et la photo
// d'action (Actions Terrain) UNIQUEMENT. Ne concerne jamais la prise de
// photo d'un signalement (caméra dédiée, module distinct et inchangé).

import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';

// Ouvre directement la galerie (jamais l'appareil photo), puis recadre via
// un package standard et éprouvé — remplace l'ancien recadrage maison
// (repositionnement vertical uniquement, comportement instable).
// Retourne le chemin de l'image recadrée, ou null si l'utilisateur annule
// à n'importe quelle étape.
Future<String?> pickAndCropImage({required bool isCircular}) async {
  // maxWidth/maxHeight forcent un redimensionnement à la décodification
  // (côté plateforme, avant que l'image n'atteigne l'écran de recadrage) —
  // sans ça, une photo de galerie haute résolution (12+ Mpx, courant sur
  // smartphone récent) peut saturer la mémoire de l'écran de recadrage sur
  // un appareil peu puissant et provoquer la fermeture de l'application.
  final picked = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    imageQuality: 90,
    maxWidth: 1920,
    maxHeight: 1920,
  );
  if (picked == null) return null;

  final cropStyle = isCircular ? CropStyle.circle : CropStyle.rectangle;
  final cropped = await ImageCropper().cropImage(
    sourcePath: picked.path,
    aspectRatio: isCircular
        ? const CropAspectRatio(ratioX: 1, ratioY: 1)
        : const CropAspectRatio(ratioX: 16, ratioY: 9),
    compressFormat: ImageCompressFormat.jpg,
    compressQuality: 90,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Ajuster la photo',
        toolbarColor: CliinAppColors.primary,
        toolbarWidgetColor: CliinAppColors.textWhite,
        backgroundColor: CliinAppColors.background,
        lockAspectRatio: true,
        cropStyle: cropStyle,
      ),
      IOSUiSettings(
        title: 'Ajuster la photo',
        aspectRatioLockEnabled: true,
        cropStyle: cropStyle,
      ),
    ],
  );
  return cropped?.path;
}
