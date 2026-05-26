import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/clip_provider.dart';
import '../theme/app_theme.dart';

class FilterBar extends StatelessWidget {
  final FilterType selected;
  final ValueChanged<FilterType> onChanged;
  final int total;
  final int textCount;
  final int imageCount;
  final int urlCount;

  const FilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.total,
    required this.textCount,
    required this.imageCount,
    required this.urlCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterChip(
          label: 'ALL',
          count: total,
          selected: selected == FilterType.all,
          onTap: () => onChanged(FilterType.all),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'TEXT',
          count: textCount,
          selected: selected == FilterType.text,
          onTap: () => onChanged(FilterType.text),
          color: AppTheme.accentGreen,
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'IMAGES',
          count: imageCount,
          selected: selected == FilterType.images,
          onTap: () => onChanged(FilterType.images),
          color: AppTheme.accentOrange,
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'URLS',
          count: urlCount,
          selected: selected == FilterType.urls,
          onTap: () => onChanged(FilterType.urls),
          color: AppTheme.accentBlue,
        ),
      ],
    );
  }
}

class _FilterChip extends StatefulWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClipProvider>();
    final activeColor = widget.color ?? AppTheme.accent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: widget.selected
                ? activeColor.withValues(alpha: 0.2)
                : _hovered
                ? AppTheme.surfaceMed
                : Colors.transparent,
            border: Border.all(
              color: widget.selected
                  ? activeColor.withValues(alpha: 0.6)
                  : AppTheme.border,
              width: widget.selected ? 1 : 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.selected ? activeColor : AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 5),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: widget.selected
                      ? activeColor.withValues(alpha: 0.3)
                      : AppTheme.surfaceMed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${widget.count}',
                  style: TextStyle(
                    color: widget.selected
                        ? activeColor
                        : AppTheme.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
