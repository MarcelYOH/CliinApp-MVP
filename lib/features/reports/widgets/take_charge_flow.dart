// lib/features/reports/widgets/take_charge_flow.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/store/report_store.dart';
import '../../../../shared/store/auth_store.dart';
import '../../../../shared/store/group_store.dart';
import '../../../../features/home/models/home_report_model.dart';

// ── Modèle indicatif téléphonique — extensible ───────────────────
class _CountryCode {
  final String flag;
  final String name;
  final String code;
  const _CountryCode({required this.flag, required this.name, required this.code});
}

const List<_CountryCode> _kCountryCodes = [
  _CountryCode(flag: '🇨🇮', name: 'Côte d\'Ivoire', code: '+225'),
  _CountryCode(flag: '🇸🇳', name: 'Sénégal',        code: '+221'),
  _CountryCode(flag: '🇧🇫', name: 'Burkina Faso',   code: '+226'),
  _CountryCode(flag: '🇲🇱', name: 'Mali',           code: '+223'),
  _CountryCode(flag: '🇬🇳', name: 'Guinée',         code: '+224'),
  _CountryCode(flag: '🇬🇭', name: 'Ghana',          code: '+233'),
  _CountryCode(flag: '🇧🇯', name: 'Bénin',          code: '+229'),
  _CountryCode(flag: '🇹🇬', name: 'Togo',           code: '+228'),
  _CountryCode(flag: '🇳🇬', name: 'Nigeria',        code: '+234'),
  _CountryCode(flag: '🇫🇷', name: 'France',         code: '+33'),
];

Future<void> showTakeChargeFlow({
  required BuildContext context,
  required HomeReportModel report,
  required void Function(HomeReportModel updated) onSuccess,
}) async {
  debugPrint('[ATTRIBUTION-DEBUG] showTakeChargeFlow: entrée dans la fonction pour report ${report.id}');
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
        onSuccess: onSuccess,
      ),
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
  bool _whatsAppConsent = false;
  String? _errorMessage;
  HomeReportModel? _updatedReport;

  _CountryCode _selectedCountry = _kCountryCodes.first;

  // Vrais groupes dont l'utilisateur connecté est administrateur — jamais
  // une liste factice (voir GroupStore.adminGroups).
  List<String> get _myGroups {
    final userId = AuthStore.instance.currentUser?.id;
    if (userId == null) return const [];
    return GroupStore.instance.adminGroups(userId).map((g) => g.nom).toList();
  }

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
        local.startsWith('0') &&
        removeTrunkZero.contains(_selectedCountry.code);

    final cleaned = shouldRemoveZero ? local.substring(1) : local;
    return '${_selectedCountry.code}$cleaned';
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

      final intervenant = IntervenantModel(
        id: user.id,
        name: user.username,
        logoAsset: null,
        whatsAppNumber: fullNumber?.isNotEmpty == true ? fullNumber : null,
        whatsAppVisible: _whatsAppConsent,
      );

      final updated = await ReportStore.instance.takeCharge(
        reportId: widget.report.id,
        intervenant: intervenant,
        whatsAppConsent: _whatsAppConsent,
        whatsAppNumber: fullNumber?.isNotEmpty == true ? fullNumber : null,
        groupName: _isSelf ? null : _selectedGroup,
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

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      // isScrollControlled pour que le sheet puisse prendre plus de hauteur
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(CliinAppConstants.radiusLarge)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            // Handle + titre — fixes
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  CliinAppConstants.pagePadding,
                  CliinAppConstants.spacingM,
                  CliinAppConstants.pagePadding,
                  CliinAppConstants.spacingM),
              child: Column(children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: CliinAppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: CliinAppConstants.spacingM),
                Text('Sélectionner un pays',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.bold,
                        color: CliinAppColors.textDark)),
              ]),
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            // Liste scrollable
            Expanded(
              child: ListView(
                controller: scrollController,
                children: _kCountryCodes.map((country) => ListTile(
                  // Remplacement des emojis par des indicateurs colorés
                  // pour éviter le délai de rendu Flutter Web
                  leading: Container(
                    width: 40, height: 28,
                    decoration: BoxDecoration(
                      color: _countryColor(country.code),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        country.code.replaceAll('+', ''),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  title: Text(country.name,
                      style: GoogleFonts.inter(
                          fontSize: 14, color: CliinAppColors.textDark)),
                  trailing: Text(country.code,
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: _selectedCountry.code == country.code
                              ? CliinAppColors.primary
                              : CliinAppColors.textSecondary)),
                  selected: _selectedCountry.code == country.code,
                  selectedTileColor: CliinAppColors.primaryLight,
                  onTap: () {
                    setState(() => _selectedCountry = country);
                    Navigator.pop(context);
                  },
                )).toList(),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  // Couleur associée à chaque indicatif — rendu immédiat sans emoji
  Color _countryColor(String code) {
    switch (code) {
      case '+225': return const Color(0xFF009A44);  // Côte d'Ivoire — vert
      case '+221': return const Color(0xFF00853F);  // Sénégal — vert
      case '+226': return const Color(0xFFEF2B2D);  // Burkina — rouge
      case '+223': return const Color(0xFF009A44);  // Mali — vert
      case '+224': return const Color(0xFFCE1126);  // Guinée — rouge
      case '+233': return const Color(0xFF006B3F);  // Ghana — vert
      case '+229': return const Color(0xFF008751);  // Bénin — vert
      case '+228': return const Color(0xFF006A4E);  // Togo — vert
      case '+234': return const Color(0xFF008751);  // Nigeria — vert
      case '+33':  return const Color(0xFF002395);  // France — bleu
      default:     return CliinAppColors.primary;
    }
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
        1 => _Step1Sheet(
            key: const ValueKey(1),
            isSelf: _isSelf,
            selectedGroup: _selectedGroup,
            groups: _myGroups,
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
            selectedCountry: _selectedCountry,
            consent: _whatsAppConsent,
            isLoading: false, // jamais en loading — transition immédiate
            errorMessage: _errorMessage,
            onCountryTap: _showCountryPicker,
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
    debugPrint('[ATTRIBUTION-DEBUG] _Step1Sheet.build: rendu à l\'écran, groups.length=${groups.length}, isSelf=$isSelf');
    return _SheetWrapper(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetHandle(),
          const SizedBox(height: CliinAppConstants.spacingL),
          Text('Prendre ce cas en charge',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold,
                  color: CliinAppColors.textDark)),
          Text('Qui intervient sur ce cas signalé ?',
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
          if (groups.isNotEmpty) ...[
            const SizedBox(height: CliinAppConstants.spacingM),
            _ChoiceCard(
              selected: !isSelf,
              icon: Icons.group_rounded,
              title: 'Au nom d\'un groupe',
              subtitle: 'Intervenir au nom d\'un groupe auquel j\'appartiens.',
              onTap: onGroupSelected,
            ),
          ],
          if (!isSelf && groups.isNotEmpty) ...[
            const SizedBox(height: CliinAppConstants.spacingS),
            Container(
              padding: const EdgeInsets.all(CliinAppConstants.spacingM),
              decoration: BoxDecoration(
                color: CliinAppColors.primaryLight,
                borderRadius: BorderRadius.circular(CliinAppConstants.radiusSmall),
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
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: CliinAppColors.textDark)),
            const SizedBox(height: CliinAppConstants.spacingS),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: CliinAppColors.cardWhite,
                borderRadius: BorderRadius.circular(CliinAppConstants.radiusSmall),
                border: Border.all(color: CliinAppColors.divider),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedGroup,
                  isExpanded: true,
                  hint: Text('Choisir un groupe',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: CliinAppColors.textSecondary)),
                  items: groups.map((g) => DropdownMenuItem(
                    value: g,
                    child: Text(g, style: GoogleFonts.inter(fontSize: 13)),
                  )).toList(),
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
                      borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('Annuler',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600,
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
                      borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: Text('Continuer',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600,
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
// ÉTAPE 2
// ─────────────────────────────────────────────────────────────────
class _Step2Sheet extends StatelessWidget {
  final TextEditingController phoneController;
  final _CountryCode selectedCountry;
  final bool consent;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onCountryTap;
  final void Function(bool) onConsentChanged;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const _Step2Sheet({
    super.key,
    required this.phoneController,
    required this.selectedCountry,
    required this.consent,
    required this.isLoading,
    required this.errorMessage,
    required this.onCountryTap,
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

              // CORRECTION POINT 1 : indicatif avec largeur fixe
              // pour éviter la cassure au chargement du drapeau
              Container(
                decoration: BoxDecoration(
                  color: CliinAppColors.cardWhite,
                  borderRadius: BorderRadius.circular(CliinAppConstants.radiusSmall),
                  border: Border.all(color: CliinAppColors.divider),
                ),
                child: Row(children: [
                  // Bouton indicatif — largeur fixe pour stabilité
                  GestureDetector(
                    onTap: onCountryTap,
                    child: Container(
                      width: 80, // largeur fixe
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 14),
                      decoration: BoxDecoration(
                        color: CliinAppColors.background,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(CliinAppConstants.radiusSmall),
                          bottomLeft: Radius.circular(CliinAppConstants.radiusSmall),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Indicatif seul — pas d'emoji pour éviter
                          // le délai de rendu Flutter Web
                          Text(selectedCountry.code,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: CliinAppColors.primary)),
                          const Icon(Icons.keyboard_arrow_down_rounded,
                              size: 14, color: CliinAppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      autofocus: true,
                      style: GoogleFonts.inter(
                          fontSize: 14, color: CliinAppColors.textDark),
                      decoration: InputDecoration(
                        hintText: '07 XX XX XX XX',
                        hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: CliinAppColors.textSecondary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                      ),
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: CliinAppConstants.spacingS),
              Row(children: [
                const Icon(Icons.info_outline_rounded,
                    size: 12, color: CliinAppColors.textSecondary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Numéro complet : ${selectedCountry.code} ${phoneController.text.trim().isEmpty ? "XX XX XX XX XX" : phoneController.text.trim()}',
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

class _ChoiceCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.selected, required this.icon,
    required this.title, required this.subtitle, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(CliinAppConstants.spacingL),
      decoration: BoxDecoration(
        color: selected ? CliinAppColors.primaryLight : CliinAppColors.cardWhite,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        border: Border.all(
          color: selected ? CliinAppColors.primary : CliinAppColors.divider,
          width: selected ? 1.5 : 1.0,
        ),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: selected ? CliinAppColors.primary : CliinAppColors.background,
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              color: selected ? CliinAppColors.textWhite : CliinAppColors.textSecondary,
              size: 20),
        ),
        const SizedBox(width: CliinAppConstants.spacingM),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: CliinAppColors.textDark)),
            Text(subtitle,
                style: GoogleFonts.inter(
                    fontSize: 12, color: CliinAppColors.textSecondary)),
          ]),
        ),
        Icon(
          selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
          color: selected ? CliinAppColors.primary : CliinAppColors.textSecondary,
        ),
      ]),
    ),
  );
}