// lib/features/actions/pages/action_detail_page.dart
// Page de détail d'une action — module Actions Terrain, Lot 2/3.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/models/report_category.dart';
import '../../../shared/navigation/fast_page_route.dart';
import '../../../shared/navigation/profile_navigation.dart';
import '../../../shared/navigation/tab_navigation.dart';
import '../../../shared/store/action_store.dart';
import '../../../shared/store/auth_store.dart';
import '../../../shared/store/favorite_store.dart';
import '../../../shared/store/group_store.dart';
import '../../../shared/store/report_store.dart';
import '../../../shared/widgets/action_card.dart'
    show formatActionDate, formatActionHeure;
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/circle_icon_button.dart';
import '../../../shared/widgets/report_card.dart'
    show buildReportImage, DynamicDistanceLabel, showFullAddressSheet;
import '../../../shared/widgets/report_stats_comments.dart';
import '../../auth/auth_guard.dart';
import '../../groups/models/group_model.dart';
import '../../groups/widgets/group_profile_widgets.dart' show GroupThemeSection;
import '../../reports/pages/report_camera_page.dart';
import '../models/action_model.dart';

class ActionDetailPage extends StatefulWidget {
  final ActionModel data;
  const ActionDetailPage({super.key, required this.data});

  @override
  State<ActionDetailPage> createState() => _ActionDetailPageState();
}

class _ActionDetailPageState extends State<ActionDetailPage> {
  // "Groupes" actif sur cette page (choix explicite du Lot 2), à la
  // différence de la page principale du module (ActionsPage, "Plus" actif).
  static const int _navIndex = 3;

  // Toujours relire la version à jour depuis ActionStore (par id) plutôt
  // que le snapshot capturé à la navigation — même principe que
  // ReportDetailPage._data.
  ActionModel get _data =>
      ActionStore.instance.actionById(widget.data.id) ?? widget.data;

  @override
  void initState() {
    super.initState();
    // Une vue n'est comptée que pour un utilisateur AUTRE que l'organisateur,
    // une seule fois par utilisateur (viewedByUserIds gère l'anti-abus côté
    // repository) — même logique que ReportDetailPage.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserId = AuthStore.instance.currentUser?.id;
      if (currentUserId != null && currentUserId != _data.organisateurId) {
        ActionStore.instance
            .recordView(actionId: _data.id, userId: currentUserId);
      }
    });
  }

  Future<void> _onShare() async {
    await Share.share(
      'Rejoignez cette action de ${_data.type.label.toLowerCase()} '
      'organisée à ${_data.lieu} sur CliinApp — '
      'https://cliinapp.app/action/${_data.id}',
      subject: _data.type.label,
    );
    ActionStore.instance.recordShare(_data.id);
  }

  void _onMore() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Bientôt disponible'),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 2),
    ));
  }

  Future<void> _onToggleFavorite() async {
    if (!await requireAuth(context)) return;
    final userId = AuthStore.instance.currentUser!.id;
    FavoriteStore.instance.toggleActionFavorite(userId, _data.id);
  }

  // "Participer" est une simple annonce de présence (comme un événement
  // Facebook) — n'engage aucune prise en charge de cas, aucune logique de
  // gestion. Reste totalement indépendant du système de prise en charge des
  // signalements.
  Future<void> _onToggleParticipation() async {
    if (!await requireAuth(context)) return;
    final userId = AuthStore.instance.currentUser!.id;
    if (ActionStore.instance.isParticipant(_data.id, userId)) {
      await ActionStore.instance.leaveAction(_data.id, userId);
    } else {
      await ActionStore.instance.joinAction(_data.id, userId);
    }
  }

  void _onOrganisateurTap() {
    if (_data.isAnonyme) return;
    openActionOrganisateurProfile(context, _data);
  }

  bool get _hasDescription =>
      _data.description != null && _data.description!.trim().isNotEmpty;

  bool get _hasBesoins {
    final a = _data;
    return (a.besoinCommunication?.trim().isNotEmpty ?? false) ||
        (a.besoinBenevoles?.trim().isNotEmpty ?? false) ||
        (a.besoinFinancement?.trim().isNotEmpty ?? false) ||
        (a.besoinMateriel?.trim().isNotEmpty ?? false);
  }

  @override
  Widget build(BuildContext context) {
    // Écoute ActionStore/FavoriteStore/AuthStore pour refléter
    // automatiquement toute modification (participation, favori,
    // commentaire...) sans devoir rouvrir la page.
    return ListenableBuilder(
      listenable: Listenable.merge([
        ActionStore.instance,
        FavoriteStore.instance,
        AuthStore.instance,
      ]),
      builder: (context, _) => _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final userId = AuthStore.instance.currentUser?.id;
    final isParticipant = userId != null &&
        ActionStore.instance.isParticipant(_data.id, userId);

    return Scaffold(
      backgroundColor: CliinAppColors.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        CliinAppConstants.pagePadding,
                        0,
                        CliinAppConstants.pagePadding,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPhoto(),
                          const SizedBox(height: CliinAppConstants.spacingL),
                          _buildTitreStatutRow(),
                          const SizedBox(height: CliinAppConstants.spacingL),
                          _buildInfosCles(),
                          if (_hasDescription) ...[
                            const SizedBox(height: CliinAppConstants.spacingL),
                            _buildDescription(),
                          ],
                          if (_hasBesoins) ...[
                            const SizedBox(height: CliinAppConstants.spacingL),
                            _buildBesoins(),
                          ],
                          if (_data.casPrisEnChargeIds.isNotEmpty) ...[
                            const SizedBox(height: CliinAppConstants.spacingL),
                            _buildCasPrisEnCharge(),
                          ],
                          const SizedBox(height: CliinAppConstants.spacingL),
                          _buildParticipants(),
                          const SizedBox(height: CliinAppConstants.spacingL),
                          _buildOrganisePar(),
                          const SizedBox(height: CliinAppConstants.spacingXL),
                          ReportStatsRow(
                            views: _data.viewsCount,
                            comments: _data.commentsCount,
                            shares: _data.sharesCount,
                          ),
                          const SizedBox(height: CliinAppConstants.spacingL),
                          ReportCommentsSection(
                            count: _data.commentsCount,
                            comments: _data.commentsList,
                            onEdit: (commentId, newText) =>
                                ActionStore.instance.editComment(
                              actionId: _data.id,
                              commentId: commentId,
                              newText: newText,
                            ),
                            onDelete: (commentId) =>
                                ActionStore.instance.deleteComment(
                              actionId: _data.id,
                              commentId: commentId,
                            ),
                          ),
                          // Réserve la place occupée par la barre de
                          // commentaire (~64) + le bouton Participer (~92) +
                          // la nav du bas (80 + inset réel, non retiré) en
                          // overlay (Positioned) plutôt qu'intégrés au flux
                          // — même principe que ReportDetailPage, marge de
                          // sécurité incluse.
                          SizedBox(
                              height: MediaQuery.of(context).padding.bottom +
                                  260),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 100),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MediaQuery.removePadding(
                      context: context,
                      removeBottom: true,
                      child: ReportCommentBar(
                        onSubmit: (text) => ActionStore.instance.addComment(
                          actionId: _data.id,
                          comment: buildCommentFromCurrentUser(text),
                        ),
                      ),
                    ),
                    _buildParticiperButton(isParticipant),
                    AppBottomNav(
                      currentIndex: _navIndex,
                      onTap: (index) => navigateToTab(
                        context,
                        currentIndex: _navIndex,
                        targetIndex: index,
                      ),
                      onSignalerTap: () => Navigator.push(
                        context,
                        fastFadeRoute<void>(const ReportCameraPage()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 1. Header ──────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        CliinAppConstants.pagePadding,
        MediaQuery.of(context).padding.top + 12,
        CliinAppConstants.pagePadding,
        12,
      ),
      child: SizedBox(
        height: 36,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Text(
                'Détails de l\'action',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: CliinAppColors.textDark,
                ),
              ),
            ),
            Positioned(
              left: 0,
              child: CircleIconButton.back(
                onTap: () => Navigator.pop(context),
                size: 36,
                iconSize: 18,
              ),
            ),
            Positioned(
              right: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleIconButton.share(
                    onTap: _onShare,
                    size: 36,
                    iconSize: 18,
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: _onMore,
                    child: const Icon(Icons.more_vert_rounded,
                        color: CliinAppColors.textDark, size: 22),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 2. Photo principale — UNE SEULE IMAGE, pas de carrousel ─────
  Widget _buildPhoto() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
      child: SizedBox(
        height: 180,
        width: double.infinity,
        child: _data.photoPath != null
            ? buildReportImage(
                _data.photoPath!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _photoFallback(),
              )
            : _photoFallback(),
      ),
    );
  }

  Widget _photoFallback() => Container(
        color: CliinAppColors.background,
        child: Center(
          child: Icon(Icons.image_outlined,
              color: CliinAppColors.textSecondary, size: 40),
        ),
      );

  // ── 3. Titre + statut + favori ───────────────────────────────────
  Widget _buildTitreStatutRow() {
    final action = _data;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: action.type.color, shape: BoxShape.circle),
          child: Icon(action.type.icon, color: CliinAppColors.textWhite, size: 20),
        ),
        const SizedBox(width: CliinAppConstants.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                action.type.label,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: CliinAppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: action.statut.bgColor,
                  borderRadius:
                      BorderRadius.circular(CliinAppConstants.radiusMedium),
                ),
                child: Text(
                  'Action ${action.statut.label.toLowerCase()}',
                  style: CliinAppTextStyles.badge.copyWith(
                      color: action.statut.color, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: CliinAppConstants.spacingS),
        _buildBookmarkButton(),
      ],
    );
  }

  Widget _buildBookmarkButton() {
    final userId = AuthStore.instance.currentUser?.id;
    final isFavorite =
        userId != null && FavoriteStore.instance.isActionFavorite(userId, _data.id);
    return GestureDetector(
      onTap: _onToggleFavorite,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: CliinAppColors.cardWhite,
          shape: BoxShape.circle,
          border: Border.all(color: CliinAppColors.divider),
        ),
        child: Icon(
          isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          color: isFavorite ? CliinAppColors.primary : CliinAppColors.textSecondary,
          size: 20,
        ),
      ),
    );
  }

  // ── 4. Infos clés — grille 4 colonnes ─────────────────────────────
  Widget _buildInfosCles() {
    final action = _data;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          vertical: CliinAppConstants.spacingM,
          horizontal: CliinAppConstants.spacingS),
      decoration: BoxDecoration(
        color: CliinAppColors.cardWhite,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        border: Border.all(color: CliinAppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: _infoTile(
              icon: Icons.calendar_today_rounded,
              value: formatActionDate(action.date),
              label: 'Date',
            ),
          ),
          Expanded(
            child: _infoTile(
              icon: Icons.access_time_rounded,
              value: formatActionHeure(action.date),
              label: 'Heure',
            ),
          ),
          Expanded(
            child: _infoTile(
              icon: Icons.location_on_rounded,
              value: action.lieu,
              label: 'Lieu',
              onTap: () =>
                  showFullAddressSheet(context, address: action.lieu),
            ),
          ),
          Expanded(child: _infoTileDistance(action)),
        ],
      ),
    );
  }

  Widget _infoTile(
      {required IconData icon,
      required String value,
      required String label,
      VoidCallback? onTap}) {
    final content = Column(
      children: [
        Icon(icon, color: CliinAppColors.primary, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: CliinAppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700, fontSize: 12, color: CliinAppColors.textDark),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(label,
            style: CliinAppTextStyles.bodySmall
                .copyWith(fontSize: 10, color: CliinAppColors.textSecondary)),
      ],
    );
    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }

  Widget _infoTileDistance(ActionModel action) {
    return Column(
      children: [
        const Icon(Icons.near_me_rounded, color: CliinAppColors.primary, size: 20),
        const SizedBox(height: 6),
        DynamicDistanceLabel(
          latitude: action.latitude,
          longitude: action.longitude,
          style: CliinAppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700, fontSize: 12, color: CliinAppColors.textDark),
        ),
        const SizedBox(height: 2),
        Text('Distance',
            style: CliinAppTextStyles.bodySmall
                .copyWith(fontSize: 10, color: CliinAppColors.textSecondary)),
      ],
    );
  }

  // ── 5. Description — absente si nulle/vide ────────────────────────
  Widget _buildDescription() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(CliinAppConstants.spacingM),
      decoration: BoxDecoration(
        color: CliinAppColors.cardWhite,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        border: Border.all(color: CliinAppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Description',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.bold, color: CliinAppColors.textDark)),
          const SizedBox(height: CliinAppConstants.spacingS),
          Text(
            _data.description!,
            style: CliinAppTextStyles.bodySmall
                .copyWith(color: CliinAppColors.textDark, fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }

  // ── 6. Besoins pour cette action — entièrement conditionnel ───────
  Widget _buildBesoins() {
    final a = _data;
    final rows = <Widget>[];
    void addRow(String emoji, String label, String? value) {
      if (value == null || value.trim().isEmpty) return;
      if (rows.isNotEmpty) {
        rows.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: CliinAppConstants.spacingM),
          child: Divider(height: 1, color: CliinAppColors.primary),
        ));
      }
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w700, color: CliinAppColors.textDark)),
                const SizedBox(height: 4),
                Text(value,
                    style: CliinAppTextStyles.bodySmall
                        .copyWith(fontSize: 12, color: CliinAppColors.textDark, height: 1.4)),
              ],
            ),
          ),
        ],
      ));
    }

    addRow('📢', 'Communication', a.besoinCommunication);
    addRow('🙋', 'Bénévoles', a.besoinBenevoles);
    addRow('💰', 'Financement', a.besoinFinancement);
    addRow('🧰', 'Matériel', a.besoinMateriel);

    return GroupThemeSection(
      title: 'Besoins pour cette action',
      accentColor: CliinAppColors.primary,
      backgroundColor: CliinAppColors.primaryLight,
      borderColor: CliinAppColors.primary,
      children: rows,
    );
  }

  // ── 7. Cas d'insalubrité pris en charge — entièrement conditionnel ─
  Widget _buildCasPrisEnCharge() {
    final counts = <ReportCategory, int>{};
    for (final id in _data.casPrisEnChargeIds) {
      final report = ReportStore.instance.reportById(id);
      if (report == null) continue;
      counts[report.category] = (counts[report.category] ?? 0) + 1;
    }
    if (counts.isEmpty) return const SizedBox.shrink();
    final entries = counts.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cas d\'insalubrité pris en charge',
            style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w800, color: CliinAppColors.textDark)),
        const SizedBox(height: CliinAppConstants.spacingM),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) => _CategoryMiniCard(
              category: entries[i].key,
              count: entries[i].value,
            ),
          ),
        ),
      ],
    );
  }

  // ── 8. Participants ────────────────────────────────────────────────
  Widget _buildParticipants() {
    final count = _data.participantsCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.people_alt_rounded, color: CliinAppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text('$count',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w800, color: CliinAppColors.primary)),
            const SizedBox(width: 6),
            Text(count > 1 ? 'participants' : 'participant',
                style: CliinAppTextStyles.bodyMedium.copyWith(fontSize: 13)),
          ],
        ),
        if (count > 0) ...[
          const SizedBox(height: CliinAppConstants.spacingM),
          _ParticipantsAvatars(count: count),
        ],
      ],
    );
  }

  // ── 9. Organisé par ────────────────────────────────────────────────
  Widget _buildOrganisePar() {
    final action = _data;
    final GroupModel? group =
        action.organisateurEstGroupe ? GroupStore.instance.groupById(action.organisateurId) : null;
    final canTap = !action.isAnonyme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Organisé par',
            style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w800, color: CliinAppColors.textDark)),
        const SizedBox(height: CliinAppConstants.spacingM),
        GestureDetector(
          onTap: canTap ? _onOrganisateurTap : null,
          child: Row(
            children: [
              _buildOrganisateurAvatar(action, group),
              const SizedBox(width: CliinAppConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.isAnonyme ? 'Anonyme' : action.organisateurNom,
                      style: CliinAppTextStyles.headingSmall.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (group != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${group.sympathisantsCount} membres · '
                        '${group.actionsCount} actions réalisées',
                        style: CliinAppTextStyles.bodySmall.copyWith(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (canTap)
                Text(
                  action.organisateurEstGroupe ? 'Voir le groupe' : 'Voir le profil',
                  style: CliinAppTextStyles.link.copyWith(fontSize: 12),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrganisateurAvatar(ActionModel action, GroupModel? group) {
    const size = 44.0;
    if (action.isAnonyme) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: CliinAppColors.primaryDark, shape: BoxShape.circle),
        child: const Icon(Icons.person_rounded, color: CliinAppColors.textWhite, size: 22),
      );
    }
    if (group != null && group.photoPath != null) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: ClipOval(
          child: buildReportImage(
            group.photoPath!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _initialsAvatar(action.organisateurNom, size),
          ),
        ),
      );
    }
    return _initialsAvatar(action.organisateurNom, size);
  }

  Widget _initialsAvatar(String nom, double size) {
    final initials = nom.trim().isEmpty ? '?' : nom.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: CliinAppColors.primaryDark, shape: BoxShape.circle),
      child: Center(
        child: Text(initials,
            style: TextStyle(
                color: CliinAppColors.textWhite, fontSize: size * 0.36, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ── 10. Bouton Participer — fixe en bas ────────────────────────────
  Widget _buildParticiperButton(bool isParticipant) {
    return Container(
      width: double.infinity,
      color: CliinAppColors.cardWhite,
      // AppBottomNav réserve déjà lui-même l'inset système bas (voir
      // AppBottomNav — SizedBox(height: MediaQuery.of(context).padding.bottom)
      // après son Divider) : l'ajouter aussi ici comptait l'inset deux fois
      // et créait un grand vide entre ce bouton et la bottom bar.
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: GestureDetector(
        onTap: _onToggleParticipation,
        child: Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: isParticipant ? CliinAppColors.primaryLight : CliinAppColors.primary,
            borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
            border: isParticipant
                ? Border.all(color: CliinAppColors.primary, width: 1.5)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isParticipant ? Icons.check_rounded : Icons.people_alt_rounded,
                color: isParticipant ? CliinAppColors.primary : CliinAppColors.textWhite,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isParticipant ? 'Vous participez' : 'Participer à cette action',
                style: CliinAppTextStyles.button.copyWith(
                    color: isParticipant ? CliinAppColors.primary : CliinAppColors.textWhite,
                    fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Mini-carte catégorie — largeur fixe, scroll horizontal (point 7)
// ─────────────────────────────────────────────────────────────────
class _CategoryMiniCard extends StatelessWidget {
  final ReportCategory category;
  final int count;
  const _CategoryMiniCard({required this.category, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      padding: const EdgeInsets.all(CliinAppConstants.spacingM),
      decoration: BoxDecoration(
        color: CliinAppColors.cardWhite,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        border: Border.all(color: CliinAppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration:
                BoxDecoration(color: category.color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(category.icon, color: category.color, size: 16),
          ),
          const SizedBox(height: 8),
          Text('$count',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w800, color: CliinAppColors.textDark)),
          const SizedBox(height: 2),
          Text(category.label,
              style: CliinAppTextStyles.bodySmall
                  .copyWith(fontSize: 11, color: CliinAppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Avatars empilés — silhouettes génériques (aucune identité réelle des
// participants n'est stockée dans le modèle pour l'instant, voir Lot 2).
// ─────────────────────────────────────────────────────────────────
class _ParticipantsAvatars extends StatelessWidget {
  final int count;
  const _ParticipantsAvatars({required this.count});

  static const double _size = 36;
  static const double _overlap = 10;

  @override
  Widget build(BuildContext context) {
    final visible = count > 5 ? 5 : count;
    final overflow = count - visible;
    final slots = visible + (overflow > 0 ? 1 : 0);
    const step = _size - _overlap;
    return SizedBox(
      width: _size + (slots - 1) * step,
      height: _size,
      child: Stack(
        children: [
          for (int i = 0; i < visible; i++)
            Positioned(left: i * step, child: _silhouette()),
          if (overflow > 0) Positioned(left: visible * step, child: _overflowBadge(overflow)),
        ],
      ),
    );
  }

  Widget _silhouette() {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: CliinAppColors.primaryLight,
        shape: BoxShape.circle,
        border: Border.all(color: CliinAppColors.cardWhite, width: 2),
      ),
      child: const Icon(Icons.person_rounded, color: CliinAppColors.primary, size: 18),
    );
  }

  Widget _overflowBadge(int overflow) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: CliinAppColors.background,
        shape: BoxShape.circle,
        border: Border.all(color: CliinAppColors.cardWhite, width: 2),
      ),
      child: Center(
        child: Text('+$overflow',
            style: CliinAppTextStyles.badge
                .copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: CliinAppColors.textDark)),
      ),
    );
  }
}
