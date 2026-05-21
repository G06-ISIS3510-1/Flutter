import 'package:flutter/material.dart';

import '../../../../theme/app_radius.dart';
import '../../../../theme/app_theme_palette.dart';

class HelpSearchBar extends StatefulWidget {
  const HelpSearchBar({
    required this.initialValue,
    required this.onChanged,
    required this.onClear,
    super.key,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<HelpSearchBar> createState() => _HelpSearchBarState();
}

class _HelpSearchBarState extends State<HelpSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    widget.onChanged(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: palette.input,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: palette.border),
      ),
      child: TextField(
        controller: _controller,
        textInputAction: TextInputAction.search,
        style: TextStyle(color: palette.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search articles…',
          hintStyle: TextStyle(color: palette.textSecondary),
          prefixIcon: Icon(Icons.search_rounded, color: palette.textSecondary),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  icon: Icon(Icons.close_rounded, color: palette.textSecondary),
                  onPressed: () {
                    _controller.clear();
                    widget.onClear();
                  },
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
