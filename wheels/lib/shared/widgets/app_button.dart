import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.fullWidth = true,
    this.isPrimary = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final style = ElevatedButton.styleFrom(
      backgroundColor: isPrimary
          ? colorScheme.primary
          : colorScheme.secondaryContainer,
      foregroundColor: isPrimary
          ? colorScheme.onPrimary
          : colorScheme.onSecondaryContainer,
      minimumSize: fullWidth ? const Size(double.infinity, 48) : null,
    );

    return ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: Text(label),
    );
  }
}
