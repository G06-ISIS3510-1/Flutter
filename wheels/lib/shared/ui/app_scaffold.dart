import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

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

  @override
  Widget build(BuildContext context) {
    if (scrollableHeader != null) {
      return Scaffold(
        backgroundColor: backgroundColor,
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
      backgroundColor: backgroundColor,
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
