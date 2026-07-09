// lib/features/profile/pages/profile_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/store/auth_store.dart';
import '../../../shared/store/report_store.dart';
import '../../../shared/models/auth_user_model.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/navigation/tab_navigation.dart';
import '../../reports/pages/report_camera_page.dart';
import '../widgets/edit_profile_sheet.dart';
import 'public_profile_page.dart';
import 'mes_cas_signales_page.dart';
import 'mes_prises_en_charge_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickAvatarPhoto() async {
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );
      if (photo == null) return;
      await AuthStore.instance.updateProfile(avatarPath: photo.path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'accéder à la caméra.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    AuthStore.instance.addListener(_onAuthChange);
  }

  @override
  void dispose() {
    AuthStore.instance.removeListener(_onAuthChange);
    super.dispose();
  }

  void _onAuthChange() {
    if (!AuthStore.instance.isAuthenticated && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _signOut() async {
    await AuthStore.instance.signOut();
    // _onAuthChange gère le Navigator.pop
  }

  String _formatMemberSince(DateTime date) {
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
        child: Icon(Icons.person_rounded, color: Colors.grey.shade500, size: 32),
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
            fontSize: 26,
          ),
        ),
      ),
    );
  }

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
        child: ListenableBuilder(
          listenable: Listenable.merge([AuthStore.instance, ReportStore.instance]),
          builder: (ctx, _) {
            final user = AuthStore.instance.currentUser;
            return Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      _buildIdentityCard(context, user),
                      const SizedBox(height: 16),
                      _buildStatsCard(user?.id),
                      const SizedBox(height: 16),
                      _buildMenuCard(context, user),
                      const SizedBox(height: 16),
                      _buildImpactBanner(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: -1,
        onTap: (index) =>
            navigateToTab(context, currentIndex: -1, targetIndex: index),
        onSignalerTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportCameraPage()),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profil',
                  style: CliinAppTextStyles.headingLarge.copyWith(fontSize: 26),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gérez votre compte et suivez votre impact',
                  style: CliinAppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 26),
                color: CliinAppColors.textDark,
                onPressed: () => _showComingSoon(context),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: CliinAppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityCard(BuildContext context, AuthUser? user) {
    return Container(
      decoration: BoxDecoration(
        color: CliinAppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _pickAvatarPhoto,
                child: Stack(
                  children: [
                    ClipOval(
                      child: SizedBox(
                        width: 76,
                        height: 76,
                        child: _buildAvatarContent(user),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: CliinAppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user?.username ?? 'Utilisateur',
                            style: CliinAppTextStyles.headingMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, color: Color(0xFF1565C0), size: 18),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: CliinAppColors.textSecondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            user?.zone ?? '—',
                            style: CliinAppTextStyles.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: CliinAppColors.textSecondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            user != null
                                ? 'Membre depuis ${_formatMemberSince(user.createdAt)}'
                                : '—',
                            style: CliinAppTextStyles.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PublicProfilePage()),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Voir profil public',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF1B4332)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String? userId) {
    final store = ReportStore.instance;
    final casPublies = userId != null ? store.casPubliesCount(userId) : 0;
    final prisEnCharge = userId != null ? store.prisEnChargeCount(userId) : 0;
    final casTraites = userId != null ? store.casTraitesCount(userId) : 0;
    return Container(
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

  Widget _buildMenuCard(BuildContext context, AuthUser? user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            context: context,
            icon: Icons.description_outlined,
            iconColor: const Color(0xFF2DB84B),
            title: 'Mes cas signalés',
            subtitle: 'Consultez tous les cas d\'insalubrité que vous avez signalés',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MesCasSignalesPage()),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildMenuItem(
            context: context,
            icon: Icons.volunteer_activism_outlined,
            iconColor: const Color(0xFFFF9800),
            title: 'Mes prises en charge',
            subtitle: 'Suivez les cas que vous avez pris en charge',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MesPrisesEnChargePage()),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildMenuItem(
            context: context,
            icon: Icons.group_outlined,
            iconColor: const Color(0xFF9C27B0),
            title: 'Mes groupes',
            subtitle: 'Vos groupes et communautés',
            onTap: () => _showComingSoon(context),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildMenuItem(
            context: context,
            icon: Icons.notifications_none_rounded,
            iconColor: const Color(0xFF2DB84B),
            title: 'Cas suivis',
            subtitle: 'Cas dont vous suivez l\'évolution',
            onTap: () => _showComingSoon(context),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildMenuItem(
            context: context,
            icon: Icons.settings_outlined,
            iconColor: const Color(0xFF1E88E5),
            title: 'Paramètres du compte',
            subtitle: 'Informations personnelles et sécurité',
            onTap: user != null
                ? () => showEditProfileSheet(context, user)
                : () => _showComingSoon(context),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildMenuItem(
            context: context,
            icon: Icons.notifications_outlined,
            iconColor: const Color(0xFFFF9800),
            title: 'Notifications',
            subtitle: 'Gérez vos préférences de notifications',
            onTap: () => _showComingSoon(context),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildMenuItem(
            context: context,
            icon: Icons.help_outline_rounded,
            iconColor: const Color(0xFF2DB84B),
            title: 'Aide et support',
            subtitle: 'FAQ, guides et contactez-nous',
            onTap: () => _showComingSoon(context),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildMenuItem(
            context: context,
            icon: Icons.logout_rounded,
            iconColor: CliinAppColors.alertRed,
            title: 'Se déconnecter',
            subtitle: 'Quitter votre compte CliinApp',
            onTap: _signOut,
            isDestructive: true,
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
    bool isDestructive = false,
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
                  Text(
                    title,
                    style: CliinAppTextStyles.headingSmall.copyWith(
                      color: isDestructive ? CliinAppColors.alertRed : CliinAppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: CliinAppTextStyles.bodySmall,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: isDestructive ? CliinAppColors.alertRed : CliinAppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactBanner() {
    return Container(
      decoration: BoxDecoration(
        color: CliinAppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.workspace_premium_rounded, color: CliinAppColors.primary, size: 26),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Votre impact compte !',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF1B4332),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Merci de contribuer à rendre votre communauté plus propre et plus sûre.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
