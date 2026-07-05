// lib/features/profile/pages/public_profile_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/store/auth_store.dart';
import '../../../shared/store/report_store.dart';
import '../../../shared/models/auth_user_model.dart';

class PublicProfilePage extends StatelessWidget {
  const PublicProfilePage({super.key});

  String _formatDate(DateTime date) {
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Widget _buildAvatarContent(AuthUser? user) {
    if (user == null) {
      return Container(
        color: Colors.grey.shade200,
        child: Icon(Icons.person_rounded, color: Colors.grey.shade500, size: 36),
      );
    }
    if (user.avatarPath != null && user.avatarPath!.isNotEmpty) {
      return Image.file(
        File(user.avatarPath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildInitialsContent(user.username),
      );
    }
    return _buildInitialsContent(user.username);
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
    final user = AuthStore.instance.currentUser;
    final store = ReportStore.instance;
    final casPublies = user != null ? store.casPubliesCount(user.id) : 0;
    final prisEnCharge = user != null ? store.prisEnChargeCount(user.id) : 0;
    final casTraites = user != null ? store.casTraitesCount(user.id) : 0;

    return Scaffold(
      backgroundColor: CliinAppColors.background,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: CliinAppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: CliinAppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Profil public',
                      textAlign: TextAlign.center,
                      style: CliinAppTextStyles.headingSmall.copyWith(fontSize: 16),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: CliinAppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.share_outlined,
                      color: CliinAppColors.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  Center(
                    child: ClipOval(
                      child: SizedBox(
                        width: 84,
                        height: 84,
                        child: _buildAvatarContent(user),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user?.username ?? 'Utilisateur',
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
                      Text(user?.zone ?? '—', style: CliinAppTextStyles.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: CliinAppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        user != null
                            ? 'Citoyen actif depuis ${_formatDate(user.createdAt)}'
                            : '—',
                        style: CliinAppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  Text(
                    'Ceci est ce que les autres utilisateurs voient lorsqu\'ils consultent votre profil (par exemple depuis un cas signalé publié à votre nom).',
                    style: CliinAppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
