// lib/features/home/widgets/home_groups.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/group_card.dart';
import '../models/group_model.dart';

class HomeGroups extends StatelessWidget {
  final List<GroupModel> groups;
  final VoidCallback? onVoirTout;
  final void Function(GroupModel)? onCardTap;

  const HomeGroups({
    super.key,
    required this.groups,
    this.onVoirTout,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final double cardWidth = MediaQuery.of(context).size.width * 0.62;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: CliinAppConstants.pagePadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Groupes actifs',
                  style: CliinAppTextStyles.headingMedium
                      .copyWith(color: const Color(0xFF1A1A1A))),
              GestureDetector(
                onTap: onVoirTout,
                child: Row(children: [
                  Text('Voir tout',
                      style: CliinAppTextStyles.link.copyWith(fontSize: 13)),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right,
                      color: CliinAppColors.primary, size: 18),
                ]),
              ),
            ],
          ),
        ),

        const SizedBox(height: CliinAppConstants.spacingM),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
              horizontal: CliinAppConstants.pagePadding),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(groups.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < groups.length - 1
                        ? CliinAppConstants.spacingM
                        : 0,
                  ),
                  child: GroupCard(
                    data: groups[index],
                    width: cardWidth,
                    onTap: () => onCardTap?.call(groups[index]),
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