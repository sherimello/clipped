import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/clip_item.dart';
import '../providers/clip_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_search_bar.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClipProvider>();
    final items = provider.allItems.where((i) => i.matches(_search)).toList();
    final grouped = _groupByDate(items);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(21, 21, 21, 0),
          decoration: const BoxDecoration(
            // border: Border(
            //   bottom: BorderSide(color: AppTheme.border, width: 0.0),
            // ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // const Icon(
                  //   Icons.history_rounded,
                  //   color: AppTheme.accent,
                  //   size: 18,
                  // ),
                  // const SizedBox(width: 8),
                  const Text(
                    'History',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceMed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${items.length}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _ClearButton(onClear: () => _confirmClear(context, provider)),
                ],
              ),
              const SizedBox(height: 12),
              CustomSearchBar(
                onChanged: (q) => setState(() => _search = q),
                hint: 'Search history...',
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.history_rounded,
                        size: 48,
                        color: AppTheme.textTertiary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _search.isNotEmpty
                            ? 'No results found'
                            : 'No history yet',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: grouped.length,
                  itemBuilder: (ctx, groupIndex) {
                    final entry = grouped[groupIndex];
                    final date = entry.key;
                    final groupItems = entry.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Text(
                            date,
                            style: const TextStyle(
                              color: AppTheme.textTertiary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        ...groupItems.asMap().entries.map(
                          (e) => _HistoryRow(
                            item: e.value,
                            index: e.key,
                            onTap: () =>
                                ctx.read<ClipProvider>().tapItem(e.value),
                            onPin: () =>
                                ctx.read<ClipProvider>().togglePin(e.value),
                            onDelete: () =>
                                ctx.read<ClipProvider>().deleteItem(e.value),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  List<MapEntry<String, List<ClipItem>>> _groupByDate(List<ClipItem> items) {
    final map = <String, List<ClipItem>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final item in items) {
      final d = DateTime(
        item.timestamp.year,
        item.timestamp.month,
        item.timestamp.day,
      );
      final String label;
      if (d == today) {
        label = 'TODAY';
      } else if (d == yesterday) {
        label = 'YESTERDAY';
      } else {
        label = DateFormat('MMMM d, yyyy').format(d).toUpperCase();
      }
      map.putIfAbsent(label, () => []).add(item);
    }
    return map.entries.toList();
  }

  Future<void> _confirmClear(
    BuildContext context,
    ClipProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Clear History',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'This will delete all unpinned items. Pinned items will remain.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Clear',
              style: TextStyle(color: AppTheme.accentRed),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) provider.clearHistory();
  }
}

class _HistoryRow extends StatefulWidget {
  final ClipItem item;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  const _HistoryRow({
    required this.item,
    required this.index,
    required this.onTap,
    required this.onPin,
    required this.onDelete,
  });

  @override
  State<_HistoryRow> createState() => _HistoryRowState();
}

class _HistoryRowState extends State<_HistoryRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final time = DateFormat('h:mm a').format(item.timestamp);

    return Animate(
      effects: [FadeEffect(duration: 200.ms, delay: (widget.index * 20).ms)],
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: 150.ms,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: _hovered ? AppTheme.surfaceMed : Colors.transparent,
              border: Border.all(
                color: _hovered ? AppTheme.border : Colors.transparent,
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _typeColor(item.type).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _typeIcon(item.type),
                    size: 15,
                    color: _typeColor(item.type),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.preview,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                    if (_hovered)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: widget.onPin,
                            child: Icon(
                              item.isPinned
                                  ? Icons.push_pin
                                  : Icons.push_pin_outlined,
                              size: 14,
                              color: item.isPinned
                                  ? AppTheme.accent
                                  : AppTheme.textTertiary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: widget.onDelete,
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              size: 14,
                              color: AppTheme.textTertiary,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _typeColor(ClipType type) => switch (type) {
    ClipType.text => AppTheme.accentGreen,
    ClipType.image => AppTheme.accentOrange,
    ClipType.url => AppTheme.accentBlue,
  };

  IconData _typeIcon(ClipType type) => switch (type) {
    ClipType.text => Icons.subject_rounded,
    ClipType.image => Icons.image_rounded,
    ClipType.url => Icons.link_rounded,
  };
}

class _ClearButton extends StatefulWidget {
  final VoidCallback onClear;

  const _ClearButton({required this.onClear});

  @override
  State<_ClearButton> createState() => _ClearButtonState();
}

class _ClearButtonState extends State<_ClearButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onClear,
        child: AnimatedContainer(
          duration: 150.ms,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered
                ? AppTheme.accentRed.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered
                  ? AppTheme.accentRed.withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.delete_sweep_rounded,
                size: 14,
                color: _hovered ? AppTheme.accentRed : AppTheme.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                'Clear',
                style: TextStyle(
                  color: _hovered ? AppTheme.accentRed : AppTheme.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
