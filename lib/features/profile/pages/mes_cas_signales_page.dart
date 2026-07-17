// lib/features/profile/pages/mes_cas_signales_page.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../home/models/home_report_model.dart';
import '../../../shared/store/report_store.dart';
import '../../../shared/store/auth_store.dart';
import '../../reports/pages/report_detail_page.dart';
import '../../reports/pages/report_camera_page.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/navigation/tab_navigation.dart';
import '../../../shared/navigation/fast_page_route.dart';
import '../../../shared/widgets/report_card.dart' show buildReportImage;
import '../../../shared/utils/report_search.dart';
import '../../../core/constants/app_constants.dart';

class MesCasSignalesPage extends StatefulWidget {
  const MesCasSignalesPage({super.key});

  @override
  State<MesCasSignalesPage> createState() => _MesCasSignalesPageState();
}

// Statut affiché dans "Mes cas signalés" — distinct de ReportStatus car un
// cas Abandonné/Rejeté redevient "Disponible" publiquement (cf.
// mock_report_repository), mais l'auteur doit pouvoir retrouver ce résidu
// privé dans son propre filtre plutôt que le voir se fondre dans
// "Disponibles".
enum _CaseFilterStatus { disponible, enCours, traite, abandonne, rejete }

_CaseFilterStatus _caseFilterStatusOf(HomeReportModel r) {
  if (r.status == ReportStatus.enCours) return _CaseFilterStatus.enCours;
  if (r.status == ReportStatus.traite) return _CaseFilterStatus.traite;
  final outcome = r.intervenant?.outcome;
  if (outcome == InterventionOutcome.abandoned) {
    return _CaseFilterStatus.abandonne;
  }
  if (outcome == InterventionOutcome.rejected) {
    return _CaseFilterStatus.rejete;
  }
  return _CaseFilterStatus.disponible;
}

class _FilterOption {
  final _CaseFilterStatus? status;
  final String label;
  const _FilterOption(this.status, this.label);
}

class _MesCasSignalesPageState extends State<MesCasSignalesPage> {
  // Hauteur fixe de carte — indépendante des dimensions de la photo ou de
  // la longueur du texte (titre/description tronqués via maxLines/ellipsis).
  static const double _kCardHeight = 152.0;

  _CaseFilterStatus? _selectedFilter;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HomeReportModel> get _myCas {
    final userId = AuthStore.instance.currentUser?.id;
    if (userId == null) return const [];
    return ReportStore.instance.reports
        .where((r) => r.signaleParId == userId)
        .toList();
  }

  // Filtre de statut ET recherche texte se combinent — jamais l'un à la
  // place de l'autre.
  List<HomeReportModel> _filtered(List<HomeReportModel> myCas) {
    var result = myCas;
    if (_selectedFilter != null) {
      result =
          result.where((r) => _caseFilterStatusOf(r) == _selectedFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      result = result.where((r) => matchesReportSearch(r, _searchQuery)).toList();
    }
    return result;
  }

  int _count(List<HomeReportModel> myCas, _CaseFilterStatus? status) {
    if (status == null) return myCas.length;
    return myCas.where((r) => _caseFilterStatusOf(r) == status).length;
  }

  List<_FilterOption> _filters(List<HomeReportModel> myCas) => [
        _FilterOption(null, 'Tous (${_count(myCas, null)})'),
        _FilterOption(_CaseFilterStatus.disponible,
            'Disponibles (${_count(myCas, _CaseFilterStatus.disponible)})'),
        _FilterOption(_CaseFilterStatus.enCours,
            'En cours (${_count(myCas, _CaseFilterStatus.enCours)})'),
        _FilterOption(_CaseFilterStatus.traite,
            'Traités (${_count(myCas, _CaseFilterStatus.traite)})'),
        _FilterOption(_CaseFilterStatus.abandonne,
            'Abandonnés (${_count(myCas, _CaseFilterStatus.abandonne)})'),
        _FilterOption(_CaseFilterStatus.rejete,
            'Rejetés (${_count(myCas, _CaseFilterStatus.rejete)})'),
      ];

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    const mois = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
    ];
    return '${date.day} ${mois[date.month - 1]} ${date.year} · '
        '${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ReportStore.instance,
      builder: (context, _) {
        final myCas = _myCas;
        final filtered = _filtered(myCas);
        return Scaffold(
          backgroundColor: CliinAppColors.background,
          body: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    'Retrouvez tous les cas d\'insalubrité que vous avez signalés.',
                    style: CliinAppTextStyles.bodyMedium,
                  ),
                ),
                _buildSearchBar(),
                const SizedBox(height: 12),
                _buildFilterRow(myCas),
                const SizedBox(height: 12),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            myCas.isEmpty
                                ? 'Vous n\'avez pas encore de cas signalés'
                                : 'Aucun cas dans cette catégorie.',
                            style: CliinAppTextStyles.bodyMedium,
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(16, 0, 16,
                              MediaQuery.of(context).padding.bottom + 80),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, i) =>
                              _buildCard(context, filtered[i]),
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
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 16, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: CliinAppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_rounded, color: CliinAppColors.primary, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Mes cas signalés', style: CliinAppTextStyles.headingMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          style: CliinAppTextStyles.bodyMedium.copyWith(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Code, catégorie, lieu, description...',
            hintStyle: CliinAppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
              color: CliinAppColors.textSecondary,
            ),
            prefixIcon: const Icon(Icons.search_rounded,
                color: CliinAppColors.textSecondary, size: 20),
            suffixIcon: _searchQuery.isEmpty
                ? null
                : GestureDetector(
                    onTap: () => setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    }),
                    child: const Icon(Icons.close_rounded,
                        color: CliinAppColors.textSecondary, size: 18),
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow(List<HomeReportModel> myCas) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _filters(myCas).map((f) {
          final isSelected = _selectedFilter == f.status;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f.status),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? CliinAppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? CliinAppColors.primary : const Color(0xFFE0E0E0),
                ),
              ),
              child: Text(
                f.label,
                style: CliinAppTextStyles.bodySmall.copyWith(
                  color: isSelected ? Colors.white : CliinAppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCard(BuildContext context, HomeReportModel report) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        fastFadeRoute<void>(ReportDetailPage(data: report, isAuthor: true)),
      ),
      child: SizedBox(
        height: _kCardHeight,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 104,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    buildReportImage(
                      report.imageAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: CliinAppColors.background,
                        child: const Icon(Icons.image_outlined, color: Colors.grey, size: 32),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildSeverityBadge(report.severity),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              report.title,
                              style: CliinAppTextStyles.headingSmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(_caseFilterStatusOf(report)),
                        ],
                      ),
                      if (_caseFilterStatusOf(report) ==
                              _CaseFilterStatus.abandonne ||
                          _caseFilterStatusOf(report) ==
                              _CaseFilterStatus.rejete) ...[
                        const SizedBox(height: 4),
                        Text(
                          _caseFilterStatusOf(report) ==
                                  _CaseFilterStatus.abandonne
                              ? 'Délai de 72h dépassé sans soumission de preuve'
                              : 'Preuve non conforme — écart de position GPS '
                                  'trop important',
                          style: CliinAppTextStyles.bodySmall.copyWith(
                            fontSize: 10,
                            color: CliinAppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 12, color: CliinAppColors.textSecondary),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              report.location,
                              style: CliinAppTextStyles.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.description,
                        style: CliinAppTextStyles.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 11, color: CliinAppColors.textSecondary),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              _formatDate(report.createdAt),
                              style: CliinAppTextStyles.bodySmall.copyWith(fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.visibility_outlined, size: 11, color: CliinAppColors.textSecondary),
                          const SizedBox(width: 2),
                          Text(
                            '${report.views}',
                            style: CliinAppTextStyles.bodySmall.copyWith(fontSize: 10),
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: CliinAppColors.textSecondary),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityBadge(ReportSeverity severity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: severity.color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(severity.icon, color: Colors.white, size: 10),
          const SizedBox(width: 3),
          Text(
            severity.label,
            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(_CaseFilterStatus status) {
    final (label, color, bg) = switch (status) {
      _CaseFilterStatus.disponible => (
          ReportStatus.disponible.label,
          ReportStatus.disponible.color,
          ReportStatus.disponible.bgColor,
        ),
      _CaseFilterStatus.enCours => (
          ReportStatus.enCours.label,
          ReportStatus.enCours.color,
          ReportStatus.enCours.bgColor,
        ),
      _CaseFilterStatus.traite => (
          ReportStatus.traite.label,
          ReportStatus.traite.color,
          ReportStatus.traite.bgColor,
        ),
      _CaseFilterStatus.abandonne => (
          'Abandonné',
          const Color(0xFF6B7280),
          const Color(0xFFF5F5F5),
        ),
      _CaseFilterStatus.rejete => (
          'Rejeté',
          const Color(0xFF9C27B0),
          const Color(0xFFF3E5F5),
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
