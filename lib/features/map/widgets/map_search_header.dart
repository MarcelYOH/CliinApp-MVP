// lib/features/map/widgets/map_search_header.dart
// Barre de recherche + bouton Ma position — Page Carte — CliinApp

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';

class MapSearchHeader extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onMyLocationTap;
  final ValueChanged<String>? onSearch;

  const MapSearchHeader({
    super.key,
    required this.controller,
    this.onMyLocationTap,
    this.onSearch,
  });

  @override
  State<MapSearchHeader> createState() => _MapSearchHeaderState();
}

class _MapSearchHeaderState extends State<MapSearchHeader> {
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> _suggestions = [];

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

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final query = widget.controller.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    // Recherche par code identifiant
    if (query.startsWith('#') || RegExp(r'^cln').hasMatch(query)) {
      setState(() => _suggestions = [
        {
          'label': widget.controller.text.toUpperCase(),
          'type': 'code',
          'icon': Icons.tag_rounded,
        },
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

  void _submitSearch(String value) {
    if (value.trim().isEmpty) return;
    _focusNode.unfocus();
    setState(() => _suggestions = []);
    widget.onSearch?.call(value.trim());
  }

  void _selectSuggestion(String label) {
    widget.controller.text = label;
    _submitSearch(label);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CliinAppConstants.pagePadding,
            CliinAppConstants.spacingM,
            CliinAppConstants.pagePadding,
            CliinAppConstants.spacingM,
          ),
          child: Row(
            children: [
              // ── Search Bar ──────────────────────────────
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                        CliinAppConstants.radiusLarge),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    onSubmitted: _submitSearch,
                    style: CliinAppTextStyles.bodyMedium.copyWith(
                      color: CliinAppColors.textDark,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ville, quartier, #CLN-...',
                      hintStyle: CliinAppTextStyles.bodyMedium.copyWith(
                        color: CliinAppColors.textSecondary,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: CliinAppColors.textSecondary,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: CliinAppConstants.spacingS),

              // ── Bouton Ma position ──────────────────────
              GestureDetector(
                onTap: widget.onMyLocationTap,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(
                    horizontal: CliinAppConstants.spacingM,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                        CliinAppConstants.radiusLarge),
                    border: Border.all(
                      color: CliinAppColors.primary,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.my_location_rounded,
                        color: CliinAppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Ma position',
                        style: CliinAppTextStyles.button.copyWith(
                          color: CliinAppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Suggestions ──
        if (_suggestions.isNotEmpty)
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
}