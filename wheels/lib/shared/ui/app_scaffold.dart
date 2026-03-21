import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_theme_palette.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.title,
    required this.child,
    this.actions,
    this.padding,
    this.bottomNavigationBar,
    this.showAppBar = true,
    this.backgroundColor,
    this.scrollableHeader,
    this.maxScrollableWidth,
    this.drawer,
    super.key,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final EdgeInsets? padding;
  final Widget? bottomNavigationBar;
  final bool showAppBar;
  final Color? backgroundColor;
  final Widget? scrollableHeader;
  final double? maxScrollableWidth;
  final Widget? drawer;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    if (scrollableHeader != null) {
      return Scaffold(
        backgroundColor: backgroundColor ?? palette.background,
        drawer: drawer,
        bottomNavigationBar: bottomNavigationBar,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxScrollableWidth ?? 430),
              child: SingleChildScrollView(
                child: Column(children: [scrollableHeader!, child]),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? palette.background,
      drawer: drawer,
      appBar: showAppBar ? AppBar(title: Text(title), actions: actions) : null,
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
