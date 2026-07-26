// lib/features/profile/pages/public_profile_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/store/auth_store.dart';
import '../../../shared/store/report_store.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/navigation/tab_navigation.dart';
import '../../reports/pages/report_camera_page.dart';
import '../../../shared/navigation/fast_page_route.dart';
import '../../../shared/widgets/circle_icon_button.dart';

class PublicProfilePage extends StatelessWidget {
  // Correction 2 — userId/displayName/avatarPath permettent d'afficher le
  // profil public de N'IMPORTE QUEL utilisateur (auteur/intervenant tapé
  // ailleurs dans l'app), pas seulement l'utilisateur connecté. Omis (ou
  // égal à l'utilisateur connecté) : comportement inchangé, aperçu de son
  // propre profil tel que vu par les autres.
  final String? userId;
  final String? displayName;
  final String? avatarPath;

  const PublicProfilePage({
    super.key,
    this.userId,
    this.displayName,
    this.avatarPath,
  });

  bool get _isOwnProfile =>
      userId == null || userId == AuthStore.instance.currentUser?.id;

  String _formatDate(DateTime date) {
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Widget _buildAvatarContent(String? path, String username) {
    if (path != null && path.isNotEmpty) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildInitialsContent(username),
      );
    }
    return _buildInitialsContent(username);
  }

  Widget _buildInitialsContent(String username) {
    final parts = username.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : username.isEmpty
            ? '?'
            : username[0].toUpperCase();
    return Container(
      color: CliinAppColors.primaryLight,
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: CliinAppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 30,
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: CliinAppTextStyles.headingMedium.copyWith(fontSize: 22)),
          const SizedBox(height: 4),
          Text(label, style: CliinAppTextStyles.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final own = _isOwnProfile;
    final currentUser = AuthStore.instance.currentUser;
    final effectiveUserId = own ? currentUser?.id : userId;
    final effectiveUsername =
        own ? (currentUser?.username ?? 'Utilisateur') : (displayName ?? 'Utilisateur');
    final effectiveAvatarPath = own ? currentUser?.avatarPath : avatarPath;
    final effectiveZone = own ? (currentUser?.zone ?? '—') : '—';
    final joinedText = own && currentUser != null
        ? 'Citoyen actif depuis ${_formatDate(currentUser.createdAt)}'
        : null;

    final store = ReportStore.instance;
    final casPublies =
        effectiveUserId != null ? store.casPubliesCount(effectiveUserId) : 0;
    final prisEnCharge =
        effectiveUserId != null ? store.prisEnChargeCount(effectiveUserId) : 0;
    final casTraites =
        effectiveUserId != null ? store.casTraitesCount(effectiveUserId) : 0;

    return Scaffold(
      backgroundColor: CliinAppColors.background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(
                  16, MediaQuery.of(context).padding.top + 12, 16, 12),
              child: Row(
                children: [
                  CircleIconButton.back(onTap: () => Navigator.pop(context)),
                  Expanded(
                    child: Text(
                      'Profil public',
                      textAlign: TextAlign.center,
                      style: CliinAppTextStyles.headingSmall.copyWith(fontSize: 16),
                    ),
                  ),
                  const CircleIconButton.share(onTap: null),
                ],
              ),
            ),
            // Content
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  MediaQuery.of(context).padding.bottom + 80,
                ),
                children: [
                  Center(
                    child: ClipOval(
                      child: SizedBox(
                        width: 84,
                        height: 84,
                        child: _buildAvatarContent(
                            effectiveAvatarPath, effectiveUsername),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        effectiveUsername,
                        style: CliinAppTextStyles.headingMedium,
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.verified_rounded, color: Color(0xFF1565C0), size: 20),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: CliinAppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(effectiveZone, style: CliinAppTextStyles.bodyMedium),
                    ],
                  ),
                  if (joinedText != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: CliinAppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(joinedText, style: CliinAppTextStyles.bodyMedium),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (own) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: CliinAppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(
                              Icons.check_circle_outline_rounded,
                              color: CliinAppColors.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Seules les statistiques sont publiques. Vos informations personnelles restent privées.',
                              style: CliinAppTextStyles.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          _buildStatItem(
                            Icons.description_outlined,
                            '$casPublies',
                            'Cas publiés',
                            const Color(0xFF2DB84B),
                          ),
                          const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE0E0E0)),
                          _buildStatItem(
                            Icons.volunteer_activism_outlined,
                            '$prisEnCharge',
                            'Pris en charge',
                            const Color(0xFFFF9800),
                          ),
                          const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE0E0E0)),
                          _buildStatItem(
                            Icons.check_circle_outline_rounded,
                            '$casTraites',
                            'Cas traités',
                            const Color(0xFF1E88E5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (own) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Ceci est ce que les autres utilisateurs voient lorsqu\'ils consultent votre profil (par exemple depuis un cas signalé publié à votre nom).',
                      style: CliinAppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: -1,
        onTap: (index) =>
            navigateToTab(context, currentIndex: -1, targetIndex: index),
        onSignalerTap: () => Navigator.push(
          context,
          fastFadeRoute<void>(const ReportCameraPage()),
        ),
      ),
    );
  }
}
