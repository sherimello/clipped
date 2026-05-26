import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/clip_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/clip_card.dart';
import '../widgets/custom_search_bar.dart';

class PinsScreen extends StatefulWidget {
  const PinsScreen({super.key});

  @override
  State<PinsScreen> createState() => _PinsScreenState();
}

class _PinsScreenState extends State<PinsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClipProvider>();
    final items = provider.pinnedItems
        .where((i) => i.matches(_search))
        .toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(21, 21, 21, 0),
          decoration: const BoxDecoration(
            // border: Border(
            //   bottom: BorderSide(color: AppTheme.border, width: 0.5),
            // ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // const Icon(
                  //   Icons.push_pin_rounded,
                  //   color: AppTheme.accent,
                  //   size: 18,
                  // ),
                  // const SizedBox(width: 8),
                  const Text(
                    'Pinned',
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
                ],
              ),
              const SizedBox(height: 12),
              CustomSearchBar(
                onChanged: (q) => setState(() => _search = q),
                hint: 'Search pinned...',
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
                        Icons.push_pin_outlined,
                        size: 48,
                        color: AppTheme.textTertiary,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No pinned items',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Pin items to keep them here',
                        style: TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(),
                )
              : Scrollbar(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.1,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final item = items[i];
                      return ClipCard(
                        key: ValueKey(item.id),
                        item: item,
                        index: i,
                        onTap: () => ctx.read<ClipProvider>().tapItem(item),
                        onPin: () => ctx.read<ClipProvider>().togglePin(item),
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
        ),
      ],
    );
  }
}
