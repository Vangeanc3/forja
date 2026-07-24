import 'package:flutter/material.dart';

import '../../core/theme.dart';

class EmberCard extends StatelessWidget {
  const EmberCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ForjaColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ForjaColors.divider),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
