// lib/features/reports/widgets/take_charge_flow.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/store/report_store.dart';
import '../../../../shared/store/auth_store.dart';
import '../../../../shared/store/group_store.dart';
import '../../../../features/home/models/home_report_model.dart';
import '../../../../shared/widgets/phone_country_field.dart';
import 'attribution_choice_sheet.dart';

// Correction 5 — cohérence entre les 3 actions principales (signaler,
// organiser une action, prendre en charge) : l'écran de choix d'attribution
// ("En mon nom" / "Au nom d'un groupe" / "Anonyme") est désormais
// EXACTEMENT le même composant déjà utilisé pour la création de
// signalement et l'organisation d'une action (showAttributionChoiceSheet),
// plutôt qu'un choix "Moi-même"/"Au nom d'un groupe" dupliqué localement
// sans option Anonyme. Demandé AVANT d'ouvrir l'assistant de prise en
// charge (même séquence que create_action_page.dart), qui démarre donc
// directement à l'ancienne étape 2 (coordonnées WhatsApp).
Future<void> showTakeChargeFlow({
  required BuildContext context,
  required HomeReportModel report,
  required void Function(HomeReportModel updated) onSuccess,
}) async {
  final attribution = await showAttributionChoiceSheet(context);
  if (!context.mounted) return;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
      ),
      child: _TakeChargeSheet(
        report: report,
        attribution: attribution,
        onSuccess: onSuccess,
      ),
    ),
  );
}

class _TakeChargeSheet extends StatefulWidget {
  final HomeReportModel report;
  final ReportAttribution attribution;
  final void Function(HomeReportModel updated) onSuccess;

  const _TakeChargeSheet({
    required this.report,
    required this.attribution,
    required this.onSuccess,
  });

  @override
  State<_TakeChargeSheet> createState() => _TakeChargeSheetState();
}

class _TakeChargeSheetState extends State<_TakeChargeSheet> {
  // Démarre directement à l'étape 2 (coordonnées WhatsApp) — l'ancienne
  // étape 1 (choix d'attribution) est désormais demandée AVANT l'ouverture
  // de ce sheet (voir showTakeChargeFlow ci-dessus), les numéros d'étape
  // 2/3 restent donc inchangés pour ne pas retoucher _Step2Sheet/
  // _Step3Sheet ni le reste de la logique de transition.
  int _step = 2;

  final TextEditingController _phoneController = TextEditingController();
  bool _whatsAppConsent = false;
  String? _errorMessage;
  HomeReportModel? _updatedReport;

  String _dialCode = '+225';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // L'attribution est déjà choisie avant l'ouverture de ce sheet (voir
  // showTakeChargeFlow) — il n'y a donc plus d'étape antérieure vers
  // laquelle revenir : "Retour" annule la prise en charge.
  void _back() => Navigator.pop(context);

  String get _fullPhoneNumber {
    final local = _phoneController.text.trim();
    if (local.isEmpty) return '';

    // Règle internationale du "trunk prefix 0" :
    // Certains pays (France +33, Belgique, UK...) utilisent un 0
    // en début de numéro local qu'il faut supprimer en format international.
    // D'autres (Côte d'Ivoire +225, Sénégal +221...) incluent le 0
    // dans le numéro international.
    //
    // Liste des pays qui suppriment le 0 en international :
    const removeTrunkZero = {'+33', '+32', '+44', '+31', '+39', '+34'};

    final shouldRemoveZero =
        local.startsWith('0') && removeTrunkZero.contains(_dialCode);

    final cleaned = shouldRemoveZero ? local.substring(1) : local;
    return '$_dialCode$cleaned';
  }

  Future<void> _submit() async {
    // Passer à l'étape 3 IMMÉDIATEMENT — pas d'attente visible
    setState(() {
      _errorMessage = null;
      _step = 3;
    });

    // Traitement async en arrière-plan
    try {
      final user = AuthStore.instance.currentUser!;
      final fullNumber = _whatsAppConsent ? _fullPhoneNumber : null;
      final attribution = widget.attribution;
      // "Au nom d'un groupe" et "Anonyme" sont mutuellement exclusifs dans
      // l'écran de choix réutilisé (attribution_choice_sheet.dart) — comme
      // pour un signalement/une action, groupId est toujours null quand
      // isAnonyme est vrai.
      final groupName = attribution.groupId != null
          ? GroupStore.instance.groupById(attribution.groupId!)?.nom
          : null;

      final intervenant = IntervenantModel(
        id: user.id,
        // Même convention que HomeReportModel.signalePar : le nom affiché
        // porte déjà 'Anonyme', id reste le vrai utilisateur (flux de
        // gestion strictement inchangé — délai 72h, abandon, historique
        // privé, notifications, cf. Correction 5).
        name: attribution.isAnonyme ? 'Anonyme' : user.username,
        logoAsset: null,
        whatsAppNumber: fullNumber?.isNotEmpty == true ? fullNumber : null,
        whatsAppVisible: _whatsAppConsent,
        isAnonyme: attribution.isAnonyme,
      );

      final updated = await ReportStore.instance.takeCharge(
        reportId: widget.report.id,
        intervenant: intervenant,
        whatsAppConsent: _whatsAppConsent,
        whatsAppNumber: fullNumber?.isNotEmpty == true ? fullNumber : null,
        groupName: groupName,
      );

      if (mounted) {
        _updatedReport = updated;
        // Pas besoin de setState — on est déjà à l'étape 3
        // _updatedReport sera utilisé par _onConfirmClose
      }
    } catch (e) {
      // En cas d'erreur : revenir à l'étape 2 avec le message
      if (mounted) {
        setState(() {
          _step = 2;
          _errorMessage = 'Erreur : ${e.toString()}';
        });
      }
    }
  }

  // CORRECTION POINT 4 : navigation directe sans postFrameCallback
  // pour éviter le flash visuel
  void _onConfirmClose() {
    final updated = _updatedReport;
    if (updated != null) {
      Navigator.pop(context);
      widget.onSuccess(updated);
    } else {
      Navigator.pop(context);
    }
  }

  void _onGoHome() {
    Navigator.pop(context);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    // Pas d'AnimatedSwitcher — la transition animée cause un flash noir
    // Pour Step3 : on force viewInsets à zéro pour éviter l'espace résiduel du clavier
    if (_step >= 3) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero),
        child: _Step3Sheet(
          key: const ValueKey(3),
          report: _updatedReport ?? widget.report,
          onClose: _onConfirmClose,
          onGoHome: _onGoHome,
        ),
      );
    }

    return switch (_step) {
        2 => _Step2Sheet(
            key: const ValueKey(2),
            phoneController: _phoneController,
            dialCode: _dialCode,
            consent: _whatsAppConsent,
            isLoading: false, // jamais en loading — transition immédiate
            errorMessage: _errorMessage,
            onDialCodeChanged: (c) => setState(() => _dialCode = c),
            onConsentChanged: (v) => setState(() => _whatsAppConsent = v),
            onBack: _back,
            onContinue: _submit,
          ),
        _ => _Step3Sheet(
            key: const ValueKey(3),
            report: _updatedReport ?? widget.report,
            onClose: _onConfirmClose,
            onGoHome: _onGoHome,
          ),
    };
  }
}

// ─────────────────────────────────────────────────────────────────
// ÉTAPE 2
// ─────────────────────────────────────────────────────────────────
class _Step2Sheet extends StatelessWidget {
  final TextEditingController phoneController;
  final String dialCode;
  final bool consent;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<String> onDialCodeChanged;
  final void Function(bool) onConsentChanged;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const _Step2Sheet({
    super.key,
    required this.phoneController,
    required this.dialCode,
    required this.consent,
    required this.isLoading,
    required this.errorMessage,
    required this.onDialCodeChanged,
    required this.onConsentChanged,
    required this.onBack,
    required this.onContinue,
  });

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
      padding: const EdgeInsets.symmetric(
          horizontal: CliinAppConstants.pagePadding),
      child: SingleChildScrollView(
        reverse: true, // scroll vers le champ actif quand clavier ouvert
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHandle(),
            const SizedBox(height: CliinAppConstants.spacingL),
            Text('Vos coordonnées',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold,
                    color: CliinAppColors.textDark)),
            Text('Souhaitez-vous être contacté(e) pour le suivi de ce cas ?',
                style: GoogleFonts.inter(
                    fontSize: 13, color: CliinAppColors.textSecondary)),
            const SizedBox(height: CliinAppConstants.spacingL),

            // ── Toggle consentement EN PREMIER ────────────────
            Container(
              padding: const EdgeInsets.all(CliinAppConstants.spacingM),
              decoration: BoxDecoration(
                color: CliinAppColors.cardWhite,
                borderRadius: BorderRadius.circular(CliinAppConstants.radiusSmall),
                border: Border.all(color: CliinAppColors.divider),
              ),
              child: Row(children: [
                const Icon(Icons.shield_outlined,
                    color: CliinAppColors.primary, size: 20),
                const SizedBox(width: CliinAppConstants.spacingM),
                Expanded(
                  child: Text(
                    "J'accepte d'être contacté(e) via WhatsApp concernant ce cas signalé et son suivi.",
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

            // ── Champ numéro conditionnel ─────────────────────
            if (consent) ...[
              const SizedBox(height: CliinAppConstants.spacingL),
              Text('Numéro WhatsApp',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: CliinAppColors.textDark)),
              const SizedBox(height: CliinAppConstants.spacingS),

              Container(
                decoration: BoxDecoration(
                  color: CliinAppColors.cardWhite,
                  borderRadius: BorderRadius.circular(CliinAppConstants.radiusSmall),
                  border: Border.all(color: CliinAppColors.divider),
                ),
                child: PhoneCountryField(
                  phoneController: phoneController,
                  onDialCodeChanged: onDialCodeChanged,
                  hintText: '07 XX XX XX XX',
                  autofocus: true,
                ),
              ),

              const SizedBox(height: CliinAppConstants.spacingS),
              Row(children: [
                const Icon(Icons.info_outline_rounded,
                    size: 12, color: CliinAppColors.textSecondary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Numéro complet : $dialCode ${phoneController.text.trim().isEmpty ? "XX XX XX XX XX" : phoneController.text.trim()}',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: CliinAppColors.textSecondary),
                  ),
                ),
              ]),
            ], // fin if (consent)

            const SizedBox(height: CliinAppConstants.spacingM),
            Row(children: [
              const Icon(Icons.lock_outline_rounded,
                  size: 14, color: CliinAppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Vos informations sont sécurisées et ne seront utilisées que dans le cadre du suivi de ce cas signalé.',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: CliinAppColors.textSecondary),
                ),
              ),
            ]),

            if (errorMessage != null) ...[
              const SizedBox(height: CliinAppConstants.spacingM),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(CliinAppConstants.spacingM),
                decoration: BoxDecoration(
                  color: CliinAppColors.alertRedBg,
                  borderRadius: BorderRadius.circular(CliinAppConstants.radiusSmall),
                  border: Border.all(color: CliinAppColors.alertRed),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline,
                        color: CliinAppColors.alertRed, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(errorMessage!,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: CliinAppColors.alertRed)),
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
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: CliinAppColors.primary)),
                ),
              ),
              const SizedBox(width: CliinAppConstants.spacingM),
              Expanded(
                child: ElevatedButton(
                  onPressed: isLoading ? null : onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CliinAppColors.primary,
                    disabledBackgroundColor: CliinAppColors.primary,
                    disabledForegroundColor: CliinAppColors.textWhite,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            CliinAppConstants.radiusMedium)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: Text('Confirmer',
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: CliinAppColors.textWhite)),
                ),
              ),
            ]),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// ÉTAPE 3 — Confirmation
// ─────────────────────────────────────────────────────────────────
class _Step3Sheet extends StatelessWidget {
  final HomeReportModel report;
  final VoidCallback onClose;
  final VoidCallback onGoHome;

  const _Step3Sheet({
    super.key,
    required this.report,
    required this.onClose,
    required this.onGoHome,
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
            width: 72, height: 72,
            decoration: const BoxDecoration(
                color: CliinAppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded,
                color: CliinAppColors.textWhite, size: 40),
          ),
          const SizedBox(height: CliinAppConstants.spacingL),
          Text('Prise en charge\nconfirmée !',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.bold,
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
              borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
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
                            fontSize: 16, fontWeight: FontWeight.bold,
                            color: CliinAppColors.primary),
                      ),
                      const TextSpan(
                          text: ' pour intervenir et publier une preuve de traitement (photo).'),
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
              borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
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
                    borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: Text('Voir ma prise en charge',
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600,
                      color: CliinAppColors.textWhite)),
            ),
          ),
          const SizedBox(height: CliinAppConstants.spacingM),
          Center(
            child: GestureDetector(
              onTap: onGoHome,
              child: Text('Retour à l\'accueil',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: CliinAppColors.textSecondary,
                      decoration: TextDecoration.underline,
                      decorationColor: CliinAppColors.textSecondary)),
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
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: CliinAppColors.cardWhite,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(CliinAppConstants.radiusLarge),
        topRight: Radius.circular(CliinAppConstants.radiusLarge),
      ),
    ),
    padding: const EdgeInsets.fromLTRB(
      CliinAppConstants.pagePadding, 0,
      CliinAppConstants.pagePadding, 0,
    ),
    child: SingleChildScrollView(child: child),
  );
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.only(top: CliinAppConstants.spacingM),
      width: 40, height: 4,
      decoration: BoxDecoration(
        color: CliinAppColors.divider,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}
