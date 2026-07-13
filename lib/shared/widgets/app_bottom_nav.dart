// lib/shared/widgets/app_bottom_nav.dart
// Bottom Navigation Bar — réutilisable — CliinApp

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'more_menu_sheet.dart';

class AppBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onSignalerTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onSignalerTap,
  });

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> {
  static const Color _kGreen = CliinAppColors.primary;
  static const Color _kGrey  = Color(0xFF6B7280);

  // "Plus" ouvre un bottom sheet plutôt que de naviguer vers une page —
  // aucune page parente ne peut donc refléter "onglet actif = Plus" via
  // son propre currentIndex. Gérée ici, localement, pour que l'icône
  // passe en vert pendant que LE sheet de CETTE bottom bar est ouvert,
  // peu importe la page qui l'héberge.
  bool _isMoreMenuOpen = false;

  Future<void> _handleTap(int index) async {
    if (index == 4) {
      setState(() => _isMoreMenuOpen = true);
      await showMoreMenuSheet(context);
      if (mounted) setState(() => _isMoreMenuOpen = false);
      return;
    }
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Accueil',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.location_on_outlined,
                activeIcon: Icons.location_on_rounded,
                label: 'Carte',
              ),
              _buildSignalerButton(),
              _buildNavItem(
                index: 3,
                icon: Icons.group_outlined,
                activeIcon: Icons.group_rounded,
                label: 'Groupes',
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.more_horiz_rounded,
                activeIcon: Icons.more_horiz_rounded,
                label: 'Plus',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool isActive =
        index == 4 ? _isMoreMenuOpen : widget.currentIndex == index;
    return GestureDetector(
      onTap: () => _handleTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? _kGreen : _kGrey,
              size: 26,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: CliinAppTextStyles.bodySmall.copyWith(
                fontSize: 11,
                color: isActive ? _kGreen : _kGrey,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalerButton() {
    return GestureDetector(
      onTap: widget.onSignalerTap,
      child: SizedBox(
        width: 72,
        height: 80,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Halo + cercle — positionnés en haut, dépassent hors de la barre
            Positioned(
              top: -22,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Halo extérieur
                  Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: CliinAppColors.primaryLight,
                    ),
                  ),
                  // Cercle vert dégradé
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF4CAF50),
                          Color(0xFF1A6B2F),
                        ],
                      ),
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: _kGreen.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),

            // Label "Signaler" — ancré en bas
            Positioned(
              bottom: 10,
              child: Text(
                'Signaler',
                style: CliinAppTextStyles.bodySmall.copyWith(
                  fontSize: 11,
                  color: const Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}