import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.title,
    required this.child,
    this.actions,
    this.padding,
    super.key,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      body: SafeArea(
        child: Padding(
          padding: padding ?? AppSpacing.screenPadding,
          child: child,
        ),
      ),
    );
  }
}
