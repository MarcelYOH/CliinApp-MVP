// lib/features/profile/pages/mes_cas_signales_page.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../home/data/home_dummy_data.dart';
import '../../home/models/home_report_model.dart';
import '../../reports/pages/report_detail_page.dart';
import '../../reports/pages/report_camera_page.dart';
import '../../../shared/widgets/app_bottom_nav.dart';

class MesCasSignalesPage extends StatefulWidget {
  const MesCasSignalesPage({super.key});

  @override
  State<MesCasSignalesPage> createState() => _MesCasSignalesPageState();
}

class _ProfileCas {
  final HomeReportModel report;
  final String displayDate;
  const _ProfileCas({required this.report, required this.displayDate});
}

class _FilterOption {
  final ReportStatus? status;
  final String label;
  const _FilterOption(this.status, this.label);
}

class _MesCasSignalesPageState extends State<MesCasSignalesPage> {
  static final List<_ProfileCas> _allCas = [
    _ProfileCas(
      report: HomeDummyData.nearbyReports[0],
      displayDate: '12 juin 2025 · 08h30',
    ),
    _ProfileCas(
      report: HomeDummyData.nearbyReports[1],
      displayDate: '10 juin 2025 · 14h15',
    ),
    _ProfileCas(
      report: HomeDummyData.nearbyReports[2],
      displayDate: '07 juin 2025 · 11h00',
    ),
    _ProfileCas(
      report: const HomeReportModel(
        id: 'CLN-4201',
        reference: '#CLN-4201',
        title: 'Bac/Poubelle saturée',
        location: 'Cocody, Angré 7e tranche',
        description: 'Bac débordant depuis 5 jours, déchets éparpillés sur la voie publique.',
        severity: ReportSeverity.eleve,
        category: ReportCategory.bacPoubelleSature,
        distance: '0 m',
        timeAgo: 'Il y a 5j',
        imageAsset: 'assets/images/depot.jpg',
        status: ReportStatus.disponible,
        views: 31,
        comments: 4,
        shares: 8,
      ),
      displayDate: '26 mai 2025 · 09h45',
    ),
  ];

  ReportStatus? _selectedFilter;

  List<_ProfileCas> get _filtered {
    if (_selectedFilter == null) return _allCas;
    return _allCas.where((c) => c.report.status == _selectedFilter).toList();
  }

  int _count(ReportStatus? status) {
    if (status == null) return _allCas.length;
    return _allCas.where((c) => c.report.status == status).length;
  }

  List<_FilterOption> get _filters => [
        _FilterOption(null, 'Tous (${_count(null)})'),
        _FilterOption(ReportStatus.disponible, 'Disponibles (${_count(ReportStatus.disponible)})'),
        _FilterOption(ReportStatus.enCours, 'En cours (${_count(ReportStatus.enCours)})'),
        _FilterOption(ReportStatus.traite, 'Traités (${_count(ReportStatus.traite)})'),
      ];

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
                'Retrouvez tous les cas d\'insalubrité que vous avez signalés.',
                style: CliinAppTextStyles.bodyMedium,
              ),
            ),
            _buildFilterRow(),
            const SizedBox(height: 12),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun cas dans cette catégorie.',
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
            child: Text('Mes cas signalés', style: CliinAppTextStyles.headingMedium),
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

  Widget _buildCard(BuildContext context, _ProfileCas item) {
    final report = item.report;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ReportDetailPage(data: report, isAuthor: true)),
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
                          _buildStatusBadge(report.status),
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
                          const Icon(Icons.access_time_rounded, size: 11, color: CliinAppColors.textSecondary),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              item.displayDate,
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

  Widget _buildStatusBadge(ReportStatus status) {
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
