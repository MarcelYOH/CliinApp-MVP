// lib/shared/widgets/app_header.dart
// Header principal — CliinApp

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../models/user_model.dart';

class AppHeader extends StatefulWidget {
  final UserModel user;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;
  final ValueChanged<String>? onSearch;
  final String? greeting;
  final String? contextLine;

  const AppHeader({
    super.key,
    required this.user,
    this.onNotificationTap,
    this.onAvatarTap,
    this.onSearch,
    this.greeting,
    this.contextLine,
  });

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader>
    with SingleTickerProviderStateMixin {
  bool _searchOpen = false;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // ── Suggestions statiques MVP ──────────────────────────────────
  static const List<Map<String, dynamic>> _allSuggestions = [
    // San-Pedro en avant
    {'label': 'San-Pedro',           'type': 'ville',    'icon': Icons.location_city_rounded},
    {'label': 'San-Pedro Centre',    'type': 'quartier', 'icon': Icons.place_rounded},
    {'label': 'Bardot',              'type': 'quartier', 'icon': Icons.place_rounded},
    {'label': 'Balmer',              'type': 'quartier', 'icon': Icons.place_rounded},
    {'label': 'Lac',                 'type': 'quartier', 'icon': Icons.place_rounded},
    {'label': 'Cité',                'type': 'quartier', 'icon': Icons.place_rounded},
    // Abidjan communes
    {'label': 'Cocody',              'type': 'commune',  'icon': Icons.location_city_rounded},
    {'label': 'Yopougon',            'type': 'commune',  'icon': Icons.location_city_rounded},
    {'label': 'Abobo',               'type': 'commune',  'icon': Icons.location_city_rounded},
    {'label': 'Adjamé',              'type': 'commune',  'icon': Icons.location_city_rounded},
    {'label': 'Plateau',             'type': 'commune',  'icon': Icons.location_city_rounded},
    {'label': 'Marcory',             'type': 'commune',  'icon': Icons.location_city_rounded},
    {'label': 'Koumassi',            'type': 'commune',  'icon': Icons.location_city_rounded},
    {'label': 'Treichville',         'type': 'commune',  'icon': Icons.location_city_rounded},
    {'label': 'Port-Bouët',          'type': 'commune',  'icon': Icons.location_city_rounded},
    {'label': 'Attécoubé',           'type': 'commune',  'icon': Icons.location_city_rounded},
    // Quartiers
    {'label': 'Angré',               'type': 'quartier', 'icon': Icons.place_rounded},
    {'label': 'Riviera',             'type': 'quartier', 'icon': Icons.place_rounded},
    {'label': 'Zone 4',              'type': 'quartier', 'icon': Icons.place_rounded},
    {'label': 'Vridi',               'type': 'quartier', 'icon': Icons.place_rounded},
    {'label': 'Washington',          'type': 'quartier', 'icon': Icons.place_rounded},
    {'label': 'Kouté',               'type': 'quartier', 'icon': Icons.place_rounded},
    {'label': 'Williamsville',       'type': 'quartier', 'icon': Icons.place_rounded},
    {'label': 'Blockhauss',          'type': 'quartier', 'icon': Icons.place_rounded},
  ];

  List<Map<String, dynamic>> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final query = _controller.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    // Recherche par code identifiant
    if (query.startsWith('#') || RegExp(r'^cln').hasMatch(query)) {
      setState(() => _suggestions = [
        {'label': _controller.text.toUpperCase(), 'type': 'code', 'icon': Icons.tag_rounded},
      ]);
      return;
    }
    setState(() {
      _suggestions = _allSuggestions
          .where((s) =>
              (s['label'] as String).toLowerCase().contains(query))
          .take(5)
          .toList();
    });
  }

  void _openSearch() {
    setState(() => _searchOpen = true);
    _animController.forward();
    Future.delayed(const Duration(milliseconds: 50), () {
      _focusNode.requestFocus();
    });
  }

  void _closeSearch() {
    _focusNode.unfocus();
    _controller.clear();
    setState(() {
      _searchOpen = false;
      _suggestions = [];
    });
    _animController.reverse();
  }

  void _submitSearch(String value) {
    if (value.trim().isEmpty) return;
    _focusNode.unfocus();
    setState(() => _suggestions = []);
    widget.onSearch?.call(value.trim());
  }

  void _selectSuggestion(String label) {
    _controller.text = label;
    _submitSearch(label);
  }

  Widget _buildGreetingSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CliinAppConstants.pagePadding,
        10,
        CliinAppConstants.pagePadding,
        14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.greeting!,
            style: CliinAppTextStyles.headingMedium.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: CliinAppColors.textDark,
              height: 1.2,
            ),
          ),
          if (widget.contextLine != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: CliinAppColors.primary,
                  size: 13,
                ),
                const SizedBox(width: 3),
                Text(
                  widget.contextLine!,
                  style: CliinAppTextStyles.bodySmall.copyWith(
                    fontSize: 12,
                    color: CliinAppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Zone blanche élevée : logo + actions + greeting ──
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Ligne 1 : logo + icônes ──
              Padding(
                padding: EdgeInsets.fromLTRB(
                  CliinAppConstants.pagePadding,
                  10 + MediaQuery.of(context).padding.top,
                  CliinAppConstants.pagePadding,
                  10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_searchOpen) _closeSearch();
                        },
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Image.asset(
                            'assets/images/cliinapp_logo.png',
                            fit: BoxFit.contain,
                            height: 34,
                          ),
                        ),
                      ),
                    ),
                    if (!_searchOpen) ...[
                      _buildIconButton(Icons.search, _openSearch),
                      const SizedBox(width: CliinAppConstants.spacingS),
                      _buildNotificationButton(),
                      const SizedBox(width: 10),
                      _buildAvatar(),
                    ] else ...[
                      Expanded(
                        flex: 2,
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: CliinAppColors.background,
                              borderRadius: BorderRadius.circular(
                                  CliinAppConstants.radiusLarge),
                            ),
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              onSubmitted: _submitSearch,
                              style: CliinAppTextStyles.bodyMedium.copyWith(
                                color: CliinAppColors.textDark,
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Ville, quartier, #CLN-...',
                                hintStyle:
                                    CliinAppTextStyles.bodyMedium.copyWith(
                                  color: CliinAppColors.textSecondary,
                                  fontSize: 13,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: CliinAppColors.textSecondary,
                                  size: 20,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: CliinAppConstants.spacingS),
                      GestureDetector(
                        onTap: _closeSearch,
                        child: Text(
                          'Annuler',
                          style: CliinAppTextStyles.button.copyWith(
                            color: CliinAppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // ── Séparateur gradient ──
              if (!_searchOpen && widget.greeting != null)
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(
                    horizontal: CliinAppConstants.pagePadding,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        CliinAppColors.divider,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              // ── Ligne 2 : greeting + contexte (masqué en mode recherche) ──
              if (!_searchOpen && widget.greeting != null)
                _buildGreetingSection(),
            ],
          ),
        ),
        // ── Suggestions de recherche ──
        if (_searchOpen && _suggestions.isNotEmpty)
          _buildSuggestions(),
      ],
    );
  }

  // ── Liste de suggestions ───────────────────────────────────────
  Widget _buildSuggestions() {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1, color: CliinAppColors.divider),
          ..._suggestions.map((s) => _buildSuggestionTile(s)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildSuggestionTile(Map<String, dynamic> s) {
    final isCode = s['type'] == 'code';
    return InkWell(
      onTap: () => _selectSuggestion(s['label'] as String),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CliinAppConstants.pagePadding,
          vertical: 10,
        ),
        child: Row(
          children: [
            Icon(
              s['icon'] as IconData,
              size: 16,
              color: isCode
                  ? CliinAppColors.primary
                  : CliinAppColors.textSecondary,
            ),
            const SizedBox(width: CliinAppConstants.spacingM),
            Expanded(
              child: Text(
                s['label'] as String,
                style: CliinAppTextStyles.bodyMedium.copyWith(
                  color: CliinAppColors.textDark,
                  fontSize: 13,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: CliinAppColors.background,
                borderRadius:
                    BorderRadius.circular(CliinAppConstants.radiusSmall),
              ),
              child: Text(
                s['type'] as String,
                style: CliinAppTextStyles.badge.copyWith(
                  color: CliinAppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bouton icône ───────────────────────────────────────────────
  Widget _buildIconButton(IconData icon, VoidCallback? onTap) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 21, color: Colors.black87),
      ),
    );
  }

  // ── Bouton notification + badge ───────────────────────────────
  Widget _buildNotificationButton() {
    return Stack(
      children: [
        _buildIconButton(
            Icons.notifications_none_rounded, widget.onNotificationTap),
        if (widget.user.notificationCount > 0)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: CliinAppColors.alertRed,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Center(
                child: Text(
                  '${widget.user.notificationCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Avatar ────────────────────────────────────────────────────
  Widget _buildAvatar() {
    return GestureDetector(
      onTap: widget.onAvatarTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: CliinAppColors.primary.withValues(alpha: 0.25),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            widget.user.avatarUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: Colors.grey.shade300,
              child: const Icon(Icons.person, color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}