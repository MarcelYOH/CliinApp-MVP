// lib/features/profile/pages/mes_prises_en_charge_page.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../home/models/home_report_model.dart';
import '../../../shared/store/report_store.dart';
import '../../../shared/store/auth_store.dart';
import '../../reports/pages/intervenant_detail_page.dart';
import '../../reports/pages/report_camera_page.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/navigation/tab_navigation.dart';
import '../../../shared/navigation/fast_page_route.dart';
import '../../../shared/widgets/report_card.dart' show buildReportImage;

enum _TakeoverStatus { enCours, traite, abandonne, rejete }

extension _TakeoverStatusExt on _TakeoverStatus {
  String get label {
    switch (this) {
      case _TakeoverStatus.enCours:    return 'En cours';
      case _TakeoverStatus.traite:     return 'Traité';
      case _TakeoverStatus.abandonne:  return 'Abandonné';
      case _TakeoverStatus.rejete:     return 'Rejeté';
    }
  }

  Color get color {
    switch (this) {
      case _TakeoverStatus.enCours:    return const Color(0xFFFF9800);
      case _TakeoverStatus.traite:     return const Color(0xFFE53935);
      case _TakeoverStatus.abandonne:  return const Color(0xFF9E9E9E);
      case _TakeoverStatus.rejete:     return const Color(0xFF9C27B0);
    }
  }

  Color get bgColor {
    switch (this) {
      case _TakeoverStatus.enCours:    return const Color(0xFFFFF3E0);
      case _TakeoverStatus.traite:     return const Color(0xFFFFEBEE);
      case _TakeoverStatus.abandonne:  return const Color(0xFFF5F5F5);
      case _TakeoverStatus.rejete:     return const Color(0xFFF3E5F5);
    }
  }
}

_TakeoverStatus _takeoverStatusOf(HomeReportModel r) {
  if (r.status == ReportStatus.traite) return _TakeoverStatus.traite;
  final outcome = r.intervenant?.outcome;
  if (outcome == InterventionOutcome.abandoned) return _TakeoverStatus.abandonne;
  if (outcome == InterventionOutcome.rejected) return _TakeoverStatus.rejete;
  return _TakeoverStatus.enCours;
}

class _FilterOption {
  final _TakeoverStatus? status;
  final String label;
  const _FilterOption(this.status, this.label);
}

class MesPrisesEnChargePage extends StatefulWidget {
  const MesPrisesEnChargePage({super.key});

  @override
  State<MesPrisesEnChargePage> createState() => _MesPrisesEnChargePageState();
}

class _MesPrisesEnChargePageState extends State<MesPrisesEnChargePage> {
  // Hauteur fixe de carte — indépendante des dimensions de la photo ou de
  // la longueur du texte (titre/description tronqués via maxLines/ellipsis).
  static const double _kCardHeight = 152.0;

  _TakeoverStatus? _selectedFilter;

  List<HomeReportModel> get _myTakeovers {
    final userId = AuthStore.instance.currentUser?.id;
    if (userId == null) return const [];
    return ReportStore.instance.reports
        .where((r) => r.intervenant?.id == userId)
        .toList();
  }

  List<HomeReportModel> _filtered(List<HomeReportModel> myTakeovers) {
    if (_selectedFilter == null) return myTakeovers;
    return myTakeovers
        .where((r) => _takeoverStatusOf(r) == _selectedFilter)
        .toList();
  }

  int _count(List<HomeReportModel> myTakeovers, _TakeoverStatus? status) {
    if (status == null) return myTakeovers.length;
    return myTakeovers.where((r) => _takeoverStatusOf(r) == status).length;
  }

  List<_FilterOption> _filters(List<HomeReportModel> myTakeovers) => [
        _FilterOption(null, 'Tous (${_count(myTakeovers, null)})'),
        _FilterOption(_TakeoverStatus.enCours,
            'En cours (${_count(myTakeovers, _TakeoverStatus.enCours)})'),
        _FilterOption(_TakeoverStatus.traite,
            'Traités (${_count(myTakeovers, _TakeoverStatus.traite)})'),
        _FilterOption(_TakeoverStatus.abandonne,
            'Abandonnés (${_count(myTakeovers, _TakeoverStatus.abandonne)})'),
        _FilterOption(_TakeoverStatus.rejete,
            'Rejetés (${_count(myTakeovers, _TakeoverStatus.rejete)})'),
      ];

  String _formatTakenAt(DateTime? date) {
    if (date == null) return '—';
    const months = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
    ];
    return 'Pris en charge le ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String? _formatDeadline(DateTime? deadline) {
    if (deadline == null) return null;
    final remaining = deadline.difference(DateTime.now());
    if (remaining.isNegative) return 'Délai expiré';
    if (remaining.inDays >= 1) return '${remaining.inDays}j restant${remaining.inDays > 1 ? 's' : ''}';
    if (remaining.inHours >= 1) return '${remaining.inHours}h restante${remaining.inHours > 1 ? 's' : ''}';
    return '${remaining.inMinutes}min restantes';
  }

  bool _isDeadlineUrgent(DateTime? deadline) {
    if (deadline == null) return false;
    return deadline.difference(DateTime.now()).inHours < 24;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ReportStore.instance,
      builder: (context, _) {
        final myTakeovers = _myTakeovers;
        final filtered = _filtered(myTakeovers);
        return Scaffold(
          backgroundColor: CliinAppColors.background,
          body: SafeArea(
            top: true,
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    'Suivez tous les cas que vous avez pris en charge.',
                    style: CliinAppTextStyles.bodyMedium,
                  ),
                ),
                _buildFilterRow(myTakeovers),
                const SizedBox(height: 12),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            myTakeovers.isEmpty
                                ? 'Vous n\'avez pas encore de prises en charge'
                                : 'Aucune prise en charge dans cette catégorie.',
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
            child: Text('Mes prises en charge', style: CliinAppTextStyles.headingMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(List<HomeReportModel> myTakeovers) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _filters(myTakeovers).map((f) {
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
    final takeoverStatus = _takeoverStatusOf(report);
    final takenAt = report.intervenant?.takenAt;
    final deadline = takeoverStatus == _TakeoverStatus.enCours && takenAt != null
        ? takenAt.add(const Duration(hours: 72))
        : null;
    final deadlineText = _formatDeadline(deadline);
    final deadlineUrgent = _isDeadlineUrgent(deadline);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        fastFadeRoute<void>(IntervenantDetailPage(report: report)),
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
                      // Title + status/deadline column
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildStatusBadge(takeoverStatus),
                              if (takeoverStatus == _TakeoverStatus.enCours &&
                                  deadlineText != null) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: deadlineUrgent
                                        ? const Color(0xFFFFEBEE)
                                        : const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    deadlineText,
                                    style: TextStyle(
                                      color: deadlineUrgent
                                          ? CliinAppColors.alertRed
                                          : CliinAppColors.alertOrange,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
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
                          const Icon(Icons.volunteer_activism_outlined, size: 11, color: CliinAppColors.textSecondary),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              _formatTakenAt(takenAt),
                              style: CliinAppTextStyles.bodySmall.copyWith(fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
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

  Widget _buildStatusBadge(_TakeoverStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: status.bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
