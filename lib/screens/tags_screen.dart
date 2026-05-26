import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/clip_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/clip_card.dart';

class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  String? _selectedTag;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClipProvider>();
    final tags = provider.allTags;
    final tagMap = provider.taggedItems;

    return Row(
      children: [
        // Tag list
        Container(
          width: 160,
          padding: const EdgeInsets.fromLTRB(21, 21, 21, 0),
          decoration: const BoxDecoration(
            border: Border(
              right: BorderSide(color: AppTheme.border, width: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Row(
                  children: [
                    // Icon(Icons.label_rounded, color: AppTheme.accent, size: 16),
                    // SizedBox(width: 8),
                    Text(
                      'Tags',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: tags.isEmpty
                    ? const Center(
                        child: Text(
                          'No tags yet',
                          style: TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: tags.length,
                        itemBuilder: (ctx, i) {
                          final tag = tags[i];
                          final count = tagMap[tag]?.length ?? 0;
                          final isSelected = _selectedTag == tag;
                          return _TagListItem(
                            tag: tag,
                            count: count,
                            isSelected: isSelected,
                            onTap: () => setState(
                              () => _selectedTag = isSelected ? null : tag,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        // Tagged items
        Expanded(
          child: _selectedTag == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.label_outline_rounded,
                        size: 48,
                        color: AppTheme.textTertiary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tags.isEmpty ? 'No tags yet' : 'Select a tag',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tags.isEmpty
                            ? 'Add tags to items to organize them'
                            : 'Choose a tag to view its items',
                        style: const TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppTheme.border,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.accent.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '#$_selectedTag',
                              style: const TextStyle(
                                color: AppTheme.accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${tagMap[_selectedTag]?.length ?? 0} items',
                            style: const TextStyle(
                              color: AppTheme.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.1,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        itemCount: tagMap[_selectedTag]?.length ?? 0,
                        itemBuilder: (ctx, i) {
                          final item = tagMap[_selectedTag]![i];
                          return ClipCard(
                            key: ValueKey(item.id),
                            item: item,
                            index: i,
                            onTap: () => ctx.read<ClipProvider>().tapItem(item),
                            onPin: () =>
                                ctx.read<ClipProvider>().togglePin(item),
                            onDelete: () =>
                                ctx.read<ClipProvider>().deleteItem(item),
                            onAddTag: (tag) =>
                                ctx.read<ClipProvider>().addTag(item, tag),
                            onRemoveTag: (tag) =>
                                ctx.read<ClipProvider>().removeTag(item, tag),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _TagListItem extends StatefulWidget {
  final String tag;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _TagListItem({
    required this.tag,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TagListItem> createState() => _TagListItemState();
}

class _TagListItemState extends State<_TagListItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: 150.ms,
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: widget.isSelected
                ? AppTheme.accent.withValues(alpha: 0.15)
                : _hovered
                ? AppTheme.surface
                : Colors.transparent,
            border: Border.all(
              color: widget.isSelected
                  ? AppTheme.accent.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.label_rounded,
                size: 13,
                color: widget.isSelected
                    ? AppTheme.accent
                    : AppTheme.textTertiary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.tag,
                  style: TextStyle(
                    color: widget.isSelected
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${widget.count}',
                style: const TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
