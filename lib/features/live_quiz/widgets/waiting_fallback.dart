import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/widgets/barav_button.dart';

class WaitingFallback extends StatelessWidget {
  const WaitingFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppStrings.quizPreparing, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            BaravButton(
              label: AppStrings.backToHome,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}
