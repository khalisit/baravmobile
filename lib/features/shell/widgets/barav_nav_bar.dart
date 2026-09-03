import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class BaravNavItem {
  const BaravNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// ناڤیگەیشنی خوارەوە — نیشاندەرێکی نەوشەیی بە نەرمی لەژێر تابەکاندا دەخلیسکێت.
class BaravNavBar extends StatelessWidget {
  const BaravNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onChanged,
  });

  final List<BaravNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        16 + MediaQuery.paddingOf(context).bottom * 0.35,
      ),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.stroke),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isLight ? 0.12 : 0.45),
              blurRadius: 28,
              offset: const Offset(0, 12),
              spreadRadius: -6,
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / items.length;
            return Stack(
              children: [
                AnimatedPositionedDirectional(
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  start: itemWidth * currentIndex,
                  top: 0,
                  bottom: 0,
                  width: itemWidth,
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.purpleGradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purple.withValues(alpha: 0.45),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                            spreadRadius: -4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _NavCell(
                          item: items[i],
                          selected: i == currentIndex,
                          onTap: () => onChanged(i),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavCell extends StatelessWidget {
  const _NavCell({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final BaravNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 320);
    const selectedColor = Color(0xFFF5F5F7);
    final color =
        selected ? selectedColor : AppColors.of(context).textMuted;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: selected ? 1.1 : 1,
              duration: duration,
              curve: Curves.easeOutBack,
              child: AnimatedSwitcher(
                duration: duration,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: Icon(
                  selected ? item.activeIcon : item.icon,
                  key: ValueKey<bool>(selected),
                  size: 21,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 9),
            AnimatedDefaultTextStyle(
              duration: duration,
              curve: Curves.easeOut,
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                color: color,
                fontSize: selected ? 14 : 13,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}
