import 'package:flutter/material.dart';

/// دەست لێدان لە دەرەوەی خانەی نووسین → داخستنی کیبۆرد (بۆ iOS و ئەندرۆید).
class DismissKeyboard extends StatelessWidget {
  const DismissKeyboard({super.key, required this.child});

  final Widget child;

  static void unfocus(BuildContext context) {
    final focus = FocusScope.of(context);
    if (!focus.hasPrimaryFocus) {
      focus.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => unfocus(context),
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
