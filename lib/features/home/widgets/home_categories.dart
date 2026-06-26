// lib/features/home/widgets/home_categories.dart
// Bloc "Catégories" — scroll horizontal — CliinApp

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/category_model.dart';

class HomeCategories extends StatelessWidget {
  final List<CategoryModel> categories;
  final VoidCallback? onVoirTout;
  final void Function(CategoryModel)? onCardTap;

  const HomeCategories({
    super.key,
    required this.categories,
    this.onVoirTout,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── En-tête section ──
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CliinAppConstants.pagePadding,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Catégories',
                style: CliinAppTextStyles.headingMedium.copyWith(
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              GestureDetector(
                onTap: onVoirTout,
                child: Row(
                  children: [
                    Text(
                      'Voir tout',
                      style: CliinAppTextStyles.link.copyWith(fontSize: 13),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right,
                      color: CliinAppColors.primary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: CliinAppConstants.spacingM),

        // ── Scroll horizontal ──
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: CliinAppConstants.pagePadding,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(categories.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < categories.length - 1
                        ? CliinAppConstants.spacingM
                        : 0,
                  ),
                  child: _CategoryCard(
                    data: categories[index],
                    onTap: () => onCardTap?.call(categories[index]),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Carte catégorie ───────────────────────────────
class _CategoryCard extends StatelessWidget {
  final CategoryModel data;
  final VoidCallback? onTap;

  const _CategoryCard({required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(
          horizontal: CliinAppConstants.spacingM,
          vertical: CliinAppConstants.spacingL,
        ),
        decoration: BoxDecoration(
          color: CliinAppColors.cardWhite,
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cercle icône
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                data.icon,
                color: data.color,
                size: 30,
              ),
            ),

            const SizedBox(height: CliinAppConstants.spacingM),

            // Label
            Text(
              data.label,
              textAlign: TextAlign.center,
              style: CliinAppTextStyles.bodySmall.copyWith(
                fontSize: 12,
                color: const Color(0xFF1A1A1A),
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: CliinAppConstants.spacingM),

            // Mini-pill compteur
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(
                  CliinAppConstants.radiusLarge,
                ),
              ),
              child: Text(
                '${data.count} cas',
                style: CliinAppTextStyles.badge.copyWith(
                  color: data.color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}