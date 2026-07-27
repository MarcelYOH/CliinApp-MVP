// lib/features/profile/pages/mes_favoris_page.dart
// Entrée "Mes favoris" du Profil — liste simple des éléments mis en favori
// par l'utilisateur. Pour l'instant, uniquement des actions terrain (seul
// module disposant d'un bouton Bookmark — Lot 2 Actions Terrain).

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/navigation/fast_page_route.dart';
import '../../../shared/store/action_store.dart';
import '../../../shared/store/auth_store.dart';
import '../../../shared/store/favorite_store.dart';
import '../../../shared/widgets/action_card.dart';
import '../../../shared/widgets/circle_icon_button.dart';
import '../../actions/models/action_model.dart';
import '../../actions/pages/action_detail_page.dart';

class MesFavorisPage extends StatefulWidget {
  const MesFavorisPage({super.key});

  @override
  State<MesFavorisPage> createState() => _MesFavorisPageState();
}

class _MesFavorisPageState extends State<MesFavorisPage> {
  List<ActionModel> get _favoriteActions {
    final userId = AuthStore.instance.currentUser?.id;
    if (userId == null) return const [];
    final ids = FavoriteStore.instance.favoriteActionIds(userId);
    return ids
        .map(ActionStore.instance.actionById)
        .whereType<ActionModel>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(
          [FavoriteStore.instance, ActionStore.instance, AuthStore.instance]),
      builder: (context, _) {
        final favorites = _favoriteActions;
        return Scaffold(
          backgroundColor: CliinAppColors.background,
          body: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: favorites.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            CliinAppConstants.pagePadding,
                            0,
                            CliinAppConstants.pagePadding,
                            MediaQuery.of(context).padding.bottom +
                                CliinAppConstants.spacingXL,
                          ),
                          itemCount: favorites.length,
                          separatorBuilder: (_, _) => const SizedBox(
                              height: CliinAppConstants.spacingM),
                          itemBuilder: (context, i) => ActionCard(
                            data: favorites[i],
                            onTap: () => Navigator.push(
                              context,
                              fastFadeRoute<void>(
                                  ActionDetailPage(data: favorites[i])),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 16, 16, 12),
      child: Row(
        children: [
          CircleIconButton.back(
            onTap: () => Navigator.pop(context),
            size: 36,
            iconSize: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Text('Mes favoris', style: CliinAppTextStyles.headingMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: CliinAppConstants.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bookmark_border_rounded,
                size: 56, color: CliinAppColors.textSecondary),
            const SizedBox(height: CliinAppConstants.spacingM),
            Text(
              'Vous n\'avez encore ajouté aucun favori. Appuyez sur '
              'l\'icône signet d\'une action pour la retrouver ici.',
              textAlign: TextAlign.center,
              style: CliinAppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
