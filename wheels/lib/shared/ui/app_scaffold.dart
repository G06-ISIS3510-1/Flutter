import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.title,
    required this.child,
    this.actions,
    this.padding,
    this.bottomNavigationBar,
    super.key,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final EdgeInsets? padding;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        child: Padding(
          padding: padding ?? AppSpacing.screenPadding,
          child: child,
        ),
      ),
    );
  }
}
