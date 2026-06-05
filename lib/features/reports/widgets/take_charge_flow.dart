// lib/features/reports/widgets/take_charge_flow.dart
// Flux prise en charge — 3 étapes — CliinApp

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/store/report_store.dart';
import '../../../../shared/data/dummy_user.dart';
import '../../../../features/home/models/report_model.dart';

Future<void> showTakeChargeFlow({
  required BuildContext context,
  required HomeReportModel report,
  required void Function(HomeReportModel updated) onSuccess,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TakeChargeSheet(
      report: report,
      onSuccess: onSuccess,
    ),
  );
}

class _TakeChargeSheet extends StatefulWidget {
  final HomeReportModel report;
  final void Function(HomeReportModel updated) onSuccess;

  const _TakeChargeSheet({
    required this.report,
    required this.onSuccess,
  });

  @override
  State<_TakeChargeSheet> createState() => _TakeChargeSheetState();
}

class _TakeChargeSheetState extends State<_TakeChargeSheet> {
  int _step = 1;

  bool _isSelf = true;
  String? _selectedGroup;

  final TextEditingController _phoneController = TextEditingController();
  bool _whatsAppConsent = true;

  bool _isLoading = false;
  String? _errorMessage; // ← affichage visuel de l'erreur dans le sheet
  HomeReportModel? _updatedReport;

  static const List<String> _mockGroups = [
    'Clean Riviera',
    'Green City',
    'Eco Jeunes',
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _next() => setState(() => _step++);
  void _back() => setState(() {
    _step--;
    _errorMessage = null;
  });

  bool get _step1Valid =>
      _isSelf || (_selectedGroup != null && _selectedGroup!.isNotEmpty);

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = DummyUser.currentUser;

      final intervenant = IntervenantModel(
        id: user.id,
        name: _isSelf ? user.name : (_selectedGroup ?? user.name),
        whatsAppNumber:
            _whatsAppConsent && _phoneController.text.trim().isNotEmpty
                ? _phoneController.text.trim()
                : null,
        whatsAppVisible: _whatsAppConsent,
      );

      final updated = await ReportStore.instance.takeCharge(
        reportId: widget.report.id,
        intervenant: intervenant,
        whatsAppConsent: _whatsAppConsent,
        whatsAppNumber: _whatsAppConsent ? _phoneController.text.trim() : null,
      );

      if (mounted) {
        _updatedReport = updated;
        setState(() => _step = 3);
      }
    } catch (e) {
      // Affichage direct dans le sheet — visible sur mobile sans console
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur : ${e.toString()}';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onConfirmClose() {
    final updated = _updatedReport;
    Navigator.pop(context);
    if (updated != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onSuccess(updated);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: switch (_step) {
        1 => _Step1Sheet(
            key: const ValueKey(1),
            isSelf: _isSelf,
            selectedGroup: _selectedGroup,
            groups: _mockGroups,
            isValid: _step1Valid,
            onSelfSelected: () => setState(() {
              _isSelf = true;
              _selectedGroup = null;
            }),
            onGroupSelected: () => setState(() => _isSelf = false),
            onGroupChanged: (g) => setState(() => _selectedGroup = g),
            onCancel: () => Navigator.pop(context),
            onContinue: _next,
          ),
        2 => _Step2Sheet(
            key: const ValueKey(2),
            phoneController: _phoneController,
            consent: _whatsAppConsent,
            isLoading: _isLoading,
            errorMessage: _errorMessage,
            onConsentChanged: (v) => setState(() => _whatsAppConsent = v),
            onBack: _back,
            onContinue: _submit,
          ),
        _ => _Step3Sheet(
            key: const ValueKey(3),
            report: _updatedReport ?? widget.report,
            onClose: _onConfirmClose,
          ),
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// ÉTAPE 1
// ─────────────────────────────────────────────────────────────────
class _Step1Sheet extends StatelessWidget {
  final bool isSelf;
  final String? selectedGroup;
  final List<String> groups;
  final bool isValid;
  final VoidCallback onSelfSelected;
  final VoidCallback onGroupSelected;
  final void Function(String?) onGroupChanged;
  final VoidCallback onCancel;
  final VoidCallback onContinue;

  const _Step1Sheet({
    super.key,
    required this.isSelf,
    required this.selectedGroup,
    required this.groups,
    required this.isValid,
    required this.onSelfSelected,
    required this.onGroupSelected,
    required this.onGroupChanged,
    required this.onCancel,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return _SheetWrapper(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetHandle(),
          const SizedBox(height: CliinAppConstants.spacingL),
          Text('Prendre ce cas en charge',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CliinAppColors.textDark)),
          Text('Qui intervient sur ce signalement ?',
              style: GoogleFonts.inter(
                  fontSize: 13, color: CliinAppColors.textSecondary)),
          const SizedBox(height: CliinAppConstants.spacingL),
          _ChoiceCard(
            selected: isSelf,
            icon: Icons.person_rounded,
            title: 'Moi-même',
            subtitle: 'Je prends ce cas en charge en mon nom.',
            onTap: onSelfSelected,
          ),
          const SizedBox(height: CliinAppConstants.spacingM),
          _ChoiceCard(
            selected: !isSelf,
            icon: Icons.group_rounded,
            title: 'Au nom d\'un groupe',
            subtitle: 'Intervenir au nom d\'un groupe auquel j\'appartiens.',
            onTap: onGroupSelected,
          ),
          if (!isSelf) ...[
            const SizedBox(height: CliinAppConstants.spacingS),
            Container(
              padding: const EdgeInsets.all(CliinAppConstants.spacingM),
              decoration: BoxDecoration(
                color: CliinAppColors.primaryLight,
                borderRadius:
                    BorderRadius.circular(CliinAppConstants.radiusSmall),
              ),
              child: Row(children: [
                const Icon(Icons.shield_outlined,
                    color: CliinAppColors.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vous devez être administrateur ou responsable d\'un groupe pour intervenir en son nom.',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: CliinAppColors.textDark),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: CliinAppConstants.spacingM),
            Text('Sélectionner un groupe',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CliinAppColors.textDark)),
            const SizedBox(height: CliinAppConstants.spacingS),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: CliinAppColors.cardWhite,
                borderRadius:
                    BorderRadius.circular(CliinAppConstants.radiusSmall),
                border: Border.all(color: CliinAppColors.divider),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedGroup,
                  isExpanded: true,
                  hint: Text('Choisir un groupe',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: CliinAppColors.textSecondary)),
                  items: groups
                      .map((g) => DropdownMenuItem(
                            value: g,
                            child: Text(g,
                                style: GoogleFonts.inter(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: onGroupChanged,
                ),
              ),
            ),
          ],
          const SizedBox(height: CliinAppConstants.spacingXL),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: CliinAppColors.divider),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          CliinAppConstants.radiusMedium)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('Annuler',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CliinAppColors.textSecondary)),
              ),
            ),
            const SizedBox(width: CliinAppConstants.spacingM),
            Expanded(
              child: ElevatedButton(
                onPressed: isValid ? onContinue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CliinAppColors.primary,
                  disabledBackgroundColor: CliinAppColors.divider,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          CliinAppConstants.radiusMedium)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: Text('Continuer',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CliinAppColors.textWhite)),
              ),
            ),
          ]),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// ÉTAPE 2 — avec affichage erreur intégré
// ─────────────────────────────────────────────────────────────────
class _Step2Sheet extends StatelessWidget {
  final TextEditingController phoneController;
  final bool consent;
  final bool isLoading;
  final String? errorMessage;
  final void Function(bool) onConsentChanged;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const _Step2Sheet({
    super.key,
    required this.phoneController,
    required this.consent,
    required this.isLoading,
    required this.errorMessage,
    required this.onConsentChanged,
    required this.onBack,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return _SheetWrapper(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetHandle(),
          const SizedBox(height: CliinAppConstants.spacingL),
          Text('Vos coordonnées',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CliinAppColors.textDark)),
          Text(
              'Renseignez votre numéro WhatsApp pour la prise en charge de ce cas.',
              style: GoogleFonts.inter(
                  fontSize: 13, color: CliinAppColors.textSecondary)),
          const SizedBox(height: CliinAppConstants.spacingL),
          Text('Numéro WhatsApp',
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CliinAppColors.textDark)),
          const SizedBox(height: CliinAppConstants.spacingS),
          Container(
            decoration: BoxDecoration(
              color: CliinAppColors.cardWhite,
              borderRadius:
                  BorderRadius.circular(CliinAppConstants.radiusSmall),
              border: Border.all(color: CliinAppColors.divider),
            ),
            child: Row(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: const Icon(Icons.phone_iphone_rounded,
                    color: Color(0xFF25D366), size: 22),
              ),
              Container(width: 1, height: 24, color: CliinAppColors.divider),
              Expanded(
                child: TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.inter(
                      fontSize: 14, color: CliinAppColors.textDark),
                  decoration: InputDecoration(
                    hintText: '+ 225 07 XX XX XX XX',
                    hintStyle: GoogleFonts.inter(
                        fontSize: 14, color: CliinAppColors.textSecondary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: CliinAppConstants.spacingL),
          Container(
            padding: const EdgeInsets.all(CliinAppConstants.spacingM),
            decoration: BoxDecoration(
              color: CliinAppColors.cardWhite,
              borderRadius:
                  BorderRadius.circular(CliinAppConstants.radiusSmall),
              border: Border.all(color: CliinAppColors.divider),
            ),
            child: Row(children: [
              const Icon(Icons.shield_outlined,
                  color: CliinAppColors.primary, size: 20),
              const SizedBox(width: CliinAppConstants.spacingM),
              Expanded(
                child: Text(
                  'J\'accepte d\'être contacté(e) via WhatsApp concernant ce signalement et son suivi.',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: CliinAppColors.textDark),
                ),
              ),
              Switch(
                value: consent,
                onChanged: onConsentChanged,
                activeThumbColor: CliinAppColors.primary,
              ),
            ]),
          ),
          const SizedBox(height: CliinAppConstants.spacingM),
          Row(children: [
            const Icon(Icons.lock_outline_rounded,
                size: 14, color: CliinAppColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Vos informations sont sécurisées et ne seront utilisées que dans le cadre du suivi de ce signalement.',
                style: GoogleFonts.inter(
                    fontSize: 11, color: CliinAppColors.textSecondary),
              ),
            ),
          ]),

          // ── Bloc erreur visible directement dans le sheet ────
          if (errorMessage != null) ...[
            const SizedBox(height: CliinAppConstants.spacingM),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(CliinAppConstants.spacingM),
              decoration: BoxDecoration(
                color: CliinAppColors.alertRedBg,
                borderRadius:
                    BorderRadius.circular(CliinAppConstants.radiusSmall),
                border: Border.all(color: CliinAppColors.alertRed),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline,
                      color: CliinAppColors.alertRed, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: CliinAppColors.alertRed),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: CliinAppConstants.spacingXL),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: CliinAppColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          CliinAppConstants.radiusMedium)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('Retour',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CliinAppColors.primary)),
              ),
            ),
            const SizedBox(width: CliinAppConstants.spacingM),
            Expanded(
              child: ElevatedButton(
                onPressed: isLoading ? null : onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CliinAppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          CliinAppConstants.radiusMedium)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: CliinAppColors.textWhite),
                      )
                    : Text('Continuer',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: CliinAppColors.textWhite)),
              ),
            ),
          ]),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// ÉTAPE 3 — Confirmation + 72h
// ─────────────────────────────────────────────────────────────────
class _Step3Sheet extends StatelessWidget {
  final HomeReportModel report;
  final VoidCallback onClose;

  const _Step3Sheet({
    super.key,
    required this.report,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return _SheetWrapper(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHandle(),
          const SizedBox(height: CliinAppConstants.spacingXL),
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: CliinAppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: CliinAppColors.textWhite, size: 40),
          ),
          const SizedBox(height: CliinAppConstants.spacingL),
          Text('Prise en charge\nconfirmée !',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: CliinAppColors.textDark)),
          const SizedBox(height: CliinAppConstants.spacingS),
          Text('Vous avez pris ce cas en charge.',
              style: GoogleFonts.inter(
                  fontSize: 13, color: CliinAppColors.textSecondary)),
          const SizedBox(height: CliinAppConstants.spacingXL),
          Container(
            padding: const EdgeInsets.all(CliinAppConstants.spacingL),
            decoration: BoxDecoration(
              color: CliinAppColors.primaryLight,
              borderRadius:
                  BorderRadius.circular(CliinAppConstants.radiusMedium),
            ),
            child: Row(children: [
              const Icon(Icons.access_time_rounded,
                  color: CliinAppColors.primary, size: 28),
              const SizedBox(width: CliinAppConstants.spacingM),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                        fontSize: 13, color: CliinAppColors.textDark),
                    children: [
                      const TextSpan(text: 'Vous disposez de '),
                      TextSpan(
                        text: '72 heures',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: CliinAppColors.primary),
                      ),
                      const TextSpan(
                          text:
                              ' pour intervenir et publier une preuve de traitement (photo).'),
                    ],
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: CliinAppConstants.spacingM),
          Container(
            padding: const EdgeInsets.all(CliinAppConstants.spacingL),
            decoration: BoxDecoration(
              color: CliinAppColors.cardWhite,
              borderRadius:
                  BorderRadius.circular(CliinAppConstants.radiusMedium),
              border: Border.all(color: CliinAppColors.divider),
            ),
            child: Row(children: [
              const Icon(Icons.notifications_outlined,
                  color: CliinAppColors.textSecondary, size: 22),
              const SizedBox(width: CliinAppConstants.spacingM),
              Expanded(
                child: Text(
                  'Des rappels vous seront envoyés automatiquement jusqu\'à la fin du délai.',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: CliinAppColors.textSecondary),
                ),
              ),
            ]),
          ),
          const SizedBox(height: CliinAppConstants.spacingXL),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: CliinAppColors.primaryDark,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        CliinAppConstants.radiusMedium)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: Text('Accéder à mon tableau de bord',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: CliinAppColors.textWhite)),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// WIDGETS INTERNES
// ─────────────────────────────────────────────────────────────────
class _SheetWrapper extends StatelessWidget {
  final Widget child;
  const _SheetWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CliinAppColors.cardWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(CliinAppConstants.radiusLarge),
          topRight: Radius.circular(CliinAppConstants.radiusLarge),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        CliinAppConstants.pagePadding,
        0,
        CliinAppConstants.pagePadding,
        0,
      ),
      child: SingleChildScrollView(child: child),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          margin: const EdgeInsets.only(top: CliinAppConstants.spacingM),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: CliinAppColors.divider,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

class _ChoiceCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(CliinAppConstants.spacingL),
        decoration: BoxDecoration(
          color: selected
              ? CliinAppColors.primaryLight
              : CliinAppColors.cardWhite,
          borderRadius:
              BorderRadius.circular(CliinAppConstants.radiusMedium),
          border: Border.all(
            color: selected ? CliinAppColors.primary : CliinAppColors.divider,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: selected
                  ? CliinAppColors.primary
                  : CliinAppColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: selected
                    ? CliinAppColors.textWhite
                    : CliinAppColors.textSecondary,
                size: 20),
          ),
          const SizedBox(width: CliinAppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CliinAppColors.textDark)),
                Text(subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: CliinAppColors.textSecondary)),
              ],
            ),
          ),
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            color: selected
                ? CliinAppColors.primary
                : CliinAppColors.textSecondary,
          ),
        ]),
      ),
    );
  }
}