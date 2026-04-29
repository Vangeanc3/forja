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
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: ForjaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ForjaColors.divider),
      ),
      child: child,
    );
  }
}
