import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/barav_button.dart';

/// پەڕەی دڵنیایی بۆ سڕینەوەی هەژمار.
Future<bool> showDeleteAccountSheet(BuildContext context) async {
  final colors = AppColors.of(context);
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: colors.background.withValues(alpha: 0.72),
    builder: (context) => const _DeleteAccountSheet(),
  );
  return result ?? false;
}

class _DeleteAccountSheet extends StatelessWidget {
  const _DeleteAccountSheet();

  @override
  Widget build(BuildContext context) {
    LocaleScope.of(context);
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        14,
        24,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: colors.stroke)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: colors.stroke,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 26),
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.32),
                ),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                size: 32,
                color: AppColors.danger,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppStrings.deleteAccountTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.deleteAccountBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 26),
          BaravOutlineButton(
            label: AppStrings.confirmDelete,
            icon: Icons.delete_forever_rounded,
            color: AppColors.danger,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: 10),
          BaravOutlineButton(
            label: AppStrings.cancel,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}
