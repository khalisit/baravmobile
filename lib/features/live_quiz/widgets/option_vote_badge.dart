import 'package:flutter/material.dart';

import '../../../core/utils/kurdish_format.dart';

class OptionVoteBadge extends StatelessWidget {
  const OptionVoteBadge({
    super.key,
    required this.count,
    required this.color,
    required this.theme,
  });

  final int count;
  final Color color;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.how_to_vote_outlined, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            KurdishFormat.digits(count),
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
