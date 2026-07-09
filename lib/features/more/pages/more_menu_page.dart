// lib/features/more/pages/more_menu_page.dart
// Page "Plus" — menu de navigation vers les autres modules de l'app.
// Remplace l'ancienne bottom sheet (more_menu_sheet.dart) : "Plus" est un
// onglet de la bottom bar au même titre qu'Accueil ou Carte, il doit donc
// être une page à part entière, cohérente avec le reste du design system.
//
// Structure pensée pour accueillir d'autres entrées futures (Marketplace,
// E-learning, ...) sans réécriture : il suffit d'ajouter un _MoreMenuEntry
// à la liste dans _buildMenuCard().

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/navigation/tab_navigation.dart';
import '../../reports/pages/report_camera_page.dart';

class MoreMenuPage extends StatelessWidget {
  const MoreMenuPage({super.key});

  static const int _navIndex = 4;

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bientôt disponible'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CliinAppColors.background,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  MediaQuery.of(context).padding.bottom + 80,
                ),
                children: [
                  _buildMenuCard(context),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _navIndex,
        onTap: (index) => navigateToTab(
          context,
          currentIndex: _navIndex,
          targetIndex: index,
        ),
        onSignalerTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportCameraPage()),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Plus', style: CliinAppTextStyles.headingLarge),
          const SizedBox(height: 4),
          Text(
            'Les autres fonctionnalités de CliinApp',
            style: CliinAppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            context: context,
            icon: Icons.bolt_rounded,
            iconColor: CliinAppColors.primary,
            title: 'Actions Terrains',
            subtitle: 'Opérations et interventions collectives sur le terrain',
            onTap: () => _showComingSoon(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: CliinAppTextStyles.headingSmall),
                  const SizedBox(height: 2),
                  Text(subtitle, style: CliinAppTextStyles.bodySmall, maxLines: 2),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: CliinAppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
