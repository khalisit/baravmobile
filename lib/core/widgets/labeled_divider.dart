import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// هێڵێکی جیاکەرەوە لەگەڵ دەقێک لە ناوەڕاستیدا.
class LabeledDivider extends StatelessWidget {
  const LabeledDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Row(
      children: [
        Expanded(child: Divider(color: colors.stroke)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textFaint,
                ),
          ),
        ),
        Expanded(child: Divider(color: colors.stroke)),
      ],
    );
  }
}
