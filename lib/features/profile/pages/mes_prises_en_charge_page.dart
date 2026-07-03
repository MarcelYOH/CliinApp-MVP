// lib/features/profile/pages/mes_prises_en_charge_page.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../home/models/home_report_model.dart';
import '../../reports/pages/intervenant_detail_page.dart';
import '../../reports/pages/report_camera_page.dart';
import '../../../shared/widgets/app_bottom_nav.dart';

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

class _PriseEnCharge {
  final HomeReportModel report;
  final _TakeoverStatus takeoverStatus;
  final DateTime takenAt;
  final DateTime? deadline;

  const _PriseEnCharge({
    required this.report,
    required this.takeoverStatus,
    required this.takenAt,
    this.deadline,
  });
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
  static final DateTime _takenAt1 = DateTime.now().subtract(const Duration(hours: 36));

  static final List<_PriseEnCharge> _allItems = [
    _PriseEnCharge(
      report: HomeReportModel(
        id: 'CLN-2810',
        reference: '#CLN-2810',
        title: 'Caniveaux bouchés',
        location: 'Cocody, Angré 8e tranche',
        description: 'Eaux stagnantes, odeurs nauséabondes et risque sanitaire élevé.',
        severity: ReportSeverity.eleve,
        category: ReportCategory.caniveauxBouches,
        distance: '400 m',
        timeAgo: 'Il y a 1j',
        imageAsset: 'assets/images/caniveau.jpg',
        status: ReportStatus.enCours,
        intervenant: IntervenantModel(
          id: 'current-user',
          name: 'Vous',
          takenAgo: 'Il y a 36h',
          takenAt: _takenAt1,
        ),
        views: 18,
        comments: 3,
        shares: 7,
      ),
      takeoverStatus: _TakeoverStatus.enCours,
      takenAt: _takenAt1,
      deadline: _takenAt1.add(const Duration(hours: 72)),
    ),
    _PriseEnCharge(
      report: HomeReportModel(
        id: 'CLN-3102',
        reference: '#CLN-3102',
        title: 'Eaux usées',
        location: 'Abobo, PK18',
        description: 'Risque sanitaire élevé pour les habitants du quartier.',
        severity: ReportSeverity.eleve,
        category: ReportCategory.eauxUsees,
        distance: '650 m',
        timeAgo: 'Il y a 2j',
        imageAsset: 'assets/images/depot.jpg',
        status: ReportStatus.traite,
        intervenant: IntervenantModel(
          id: 'current-user',
          name: 'Vous',
          takenAt: DateTime(2025, 5, 10, 10, 30),
          treatedAt: DateTime(2025, 5, 12, 14, 45),
        ),
        views: 15,
        comments: 2,
        shares: 6,
      ),
      takeoverStatus: _TakeoverStatus.traite,
      takenAt: DateTime(2025, 5, 10, 10, 30),
    ),
    _PriseEnCharge(
      report: HomeReportModel(
        id: 'CLN-1845',
        reference: '#CLN-1845',
        title: 'Dépôts sauvages',
        location: 'Yopougon, Sicogi',
        description: 'Accumulation importante d\'ordures ménagères non collectées.',
        severity: ReportSeverity.critique,
        category: ReportCategory.depotsSauvages,
        distance: '800 m',
        timeAgo: 'Il y a 7j',
        imageAsset: 'assets/images/depot.jpg',
        status: ReportStatus.disponible,
        intervenant: IntervenantModel(
          id: 'current-user',
          name: 'Vous',
          takenAt: DateTime(2025, 4, 28, 9, 0),
          outcome: InterventionOutcome.abandoned,
        ),
        history: [
          ReportHistoryEntry(
              type: HistoryEventType.signalementCree,
              dateTime: DateTime(2025, 4, 27, 8, 0)),
          ReportHistoryEntry(
              type: HistoryEventType.prisEnCharge,
              dateTime: DateTime(2025, 4, 28, 9, 0),
              actorName: 'Vous'),
          ReportHistoryEntry(
              type: HistoryEventType.abandonne,
              dateTime: DateTime(2025, 5, 1, 9, 0),
              isCurrentStep: true),
        ],
        views: 42,
        comments: 6,
        shares: 11,
      ),
      takeoverStatus: _TakeoverStatus.abandonne,
      takenAt: DateTime(2025, 4, 28, 9, 0),
    ),
    _PriseEnCharge(
      report: HomeReportModel(
        id: 'CLN-2201',
        reference: '#CLN-2201',
        title: 'Zone insalubre',
        location: 'Marcory, Zone 4',
        description: 'Zone de décharge illicite avec accumulation de déchets divers.',
        severity: ReportSeverity.eleve,
        category: ReportCategory.zoneInsalubre,
        distance: '1.2 km',
        timeAgo: 'Il y a 14j',
        imageAsset: 'assets/images/caniveau.jpg',
        status: ReportStatus.disponible,
        intervenant: IntervenantModel(
          id: 'current-user',
          name: 'Vous',
          takenAt: DateTime(2025, 4, 17, 11, 0),
          outcome: InterventionOutcome.rejected,
        ),
        history: [
          ReportHistoryEntry(
              type: HistoryEventType.signalementCree,
              dateTime: DateTime(2025, 4, 16, 8, 0)),
          ReportHistoryEntry(
              type: HistoryEventType.prisEnCharge,
              dateTime: DateTime(2025, 4, 17, 11, 0),
              actorName: 'Vous'),
          ReportHistoryEntry(
              type: HistoryEventType.rejete,
              dateTime: DateTime(2025, 4, 19, 15, 30),
              isCurrentStep: true),
        ],
        views: 29,
        comments: 4,
        shares: 9,
      ),
      takeoverStatus: _TakeoverStatus.rejete,
      takenAt: DateTime(2025, 4, 17, 11, 0),
    ),
  ];

  _TakeoverStatus? _selectedFilter;

  List<_PriseEnCharge> get _filtered {
    if (_selectedFilter == null) return _allItems;
    return _allItems.where((i) => i.takeoverStatus == _selectedFilter).toList();
  }

  int _count(_TakeoverStatus? status) {
    if (status == null) return _allItems.length;
    return _allItems.where((i) => i.takeoverStatus == status).length;
  }

  List<_FilterOption> get _filters => [
        _FilterOption(null, 'Tous (${_count(null)})'),
        _FilterOption(_TakeoverStatus.enCours, 'En cours (${_count(_TakeoverStatus.enCours)})'),
        _FilterOption(_TakeoverStatus.traite, 'Traités (${_count(_TakeoverStatus.traite)})'),
        _FilterOption(_TakeoverStatus.abandonne, 'Abandonnés (${_count(_TakeoverStatus.abandonne)})'),
        _FilterOption(_TakeoverStatus.rejete, 'Rejetés (${_count(_TakeoverStatus.rejete)})'),
      ];

  String _formatTakenAt(DateTime date) {
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
            _buildFilterRow(),
            const SizedBox(height: 12),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(
                        'Aucune prise en charge dans cette catégorie.',
                        style: CliinAppTextStyles.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                          16, 0, 16, MediaQuery.of(context).padding.bottom + 80),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => _buildCard(context, _filtered[i]),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 4,
        onTap: (index) {
          if (index != 4) {
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        },
        onSignalerTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportCameraPage()),
        ),
      ),
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

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _filters.map((f) {
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

  Widget _buildCard(BuildContext context, _PriseEnCharge item) {
    final report = item.report;
    final deadlineText = _formatDeadline(item.deadline);
    final deadlineUrgent = _isDeadlineUrgent(item.deadline);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => IntervenantDetailPage(report: report)),
      ),
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
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 104,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      report.imageAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: CliinAppColors.background,
                        child: const Icon(Icons.image_outlined, color: Colors.grey, size: 32),
                      ),
                    ),
                    if (report.severity == ReportSeverity.critique ||
                        report.severity == ReportSeverity.eleve)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _buildUrgencyBadge(report.severity),
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
                              _buildStatusBadge(item.takeoverStatus),
                              if (item.takeoverStatus == _TakeoverStatus.enCours &&
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
                              _formatTakenAt(item.takenAt),
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

  Widget _buildUrgencyBadge(ReportSeverity severity) {
    final isUrgent = severity == ReportSeverity.critique;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isUrgent ? CliinAppColors.alertRed : CliinAppColors.alertOrange,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isUrgent ? 'Urgent' : 'Élevé',
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
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
