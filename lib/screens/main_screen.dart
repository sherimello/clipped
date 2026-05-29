import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../models/clip_item.dart';
import '../providers/clip_provider.dart';
import '../services/clipboard_service.dart';
import '../services/paste_service.dart';
import '../theme/app_theme.dart';
import '../widgets/clip_card.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/filter_bar.dart';
import 'history_screen.dart';
import 'pins_screen.dart';
import 'settings_screen.dart';
import 'tags_screen.dart';

enum NavPage { all, pins, tags, history, settings }

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WindowListener {
  NavPage _page = NavPage.all;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    HardwareKeyboard.instance.addHandler(_handleKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ClipProvider>().setItemTapHandler(_onItemTap);
      }
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _searchController.dispose();
    super.dispose();
  }

  bool _handleKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      windowManager.hide();
      return true;
    }
    return false;
  }

  @override
  void onWindowEvent(String eventName) {
    if (eventName == 'show' && mounted) {
      setState(() => _page = NavPage.all);
      _searchController.clear();
      final provider = context.read<ClipProvider>();
      provider.resetView();
      provider.reloadFromDisk();
    }
  }

  @override
  void onWindowBlur() {
    Future.delayed(const Duration(milliseconds: 120), () async {
      if (mounted) await windowManager.hide();
    });
  }

  Future<void> _onItemTap(ClipItem item) async {
    if (item.isImage && item.imagePath != null) {
      final file = File(item.imagePath!);
      if (await file.exists()) {
        ClipboardService.suppressImageWrite(await file.length());
      }
      await PasteService.writeImageToClipboard(item.imagePath!);
    } else if (item.textContent != null) {
      await ClipboardService.writeTextToClipboard(item.textContent!);
    }
    await windowManager.hide();
    await PasteService.restoreAndPaste();
  }

  @override
  Widget build(BuildContext context) {
    final tintIndex = context.watch<ClipProvider>().tintThemeIndex;
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(55)),
      child: Container(
        color: AppTheme.tintThemes[tintIndex][0],
        child: Row(
          children: [
            _Sidebar(
              selected: _page,
              onSelect: (p) => setState(() => _page = p),
            ),
            Expanded(child: _buildPage()),
          ],
        ),
      ),
    );
  }

  Widget _buildPage() => switch (_page) {
    NavPage.all => _AllClipsPage(searchController: _searchController),
    NavPage.pins => const PinsScreen(),
    NavPage.tags => const TagsScreen(),
    NavPage.history => const HistoryScreen(),
    NavPage.settings => const SettingsScreen(),
  };
}

// ─── Sidebar ────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final NavPage selected;
  final ValueChanged<NavPage> onSelect;

  const _Sidebar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(21),
      decoration: const BoxDecoration(
        color: Color(0x33000000),
        border: Border(right: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Draggable title bar
          GestureDetector(
            onPanStart: (_) => windowManager.startDragging(),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      // gradient: const LinearGradient(
                      //   colors: [AppTheme.accent, AppTheme.accentPurple],
                      //   begin: Alignment.topLeft,
                      //   end: Alignment.bottomRight,
                      // ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset('assets/images/clipped logo.png'),
                    // child: const Icon(
                    //   Icons.content_paste_rounded,
                    //   color: Colors.white,
                    //   size: 16,
                    // ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'CLIPPED',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  // _CloseButton(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _NavItem(
            icon: Icons.all_inclusive_rounded,
            activeIcon: Icons.all_inclusive_rounded,
            label: 'All Clips',
            page: NavPage.all,
            selected: selected,
            onTap: onSelect,
          ),
          _NavItem(
            icon: Icons.push_pin_outlined,
            activeIcon: Icons.push_pin,
            label: 'Pin',
            page: NavPage.pins,
            selected: selected,
            onTap: onSelect,
            // _CloseButton(),
          ),
          _NavItem(
            icon: Icons.label_outline_rounded,
            activeIcon: Icons.label_rounded,
            label: 'Tags',
            page: NavPage.tags,
            selected: selected,
            onTap: onSelect,
          ),
          _NavItem(
            icon: Icons.history_rounded,
            activeIcon: Icons.history_rounded,
            label: 'History',
            page: NavPage.history,
            selected: selected,
            onTap: onSelect,
          ),
          const Spacer(),
          // const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 8),
          _NavItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings_rounded,
            label: 'Settings',
            page: NavPage.settings,
            selected: selected,
            onTap: onSelect,
          ),
          const SizedBox(height: 12),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
  }
}

class _CloseButton extends StatefulWidget {
  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => windowManager.hide(),
        child: AnimatedContainer(
          duration: 150.ms,
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: _hovered
                ? AppTheme.accentRed.withValues(alpha: 0.8)
                : AppTheme.surfaceMed,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.close_rounded,
            size: 12,
            color: _hovered ? Colors.white : AppTheme.textTertiary,
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final NavPage page;
  final NavPage selected;
  final ValueChanged<NavPage> onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.page,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.selected == widget.page;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => widget.onTap(widget.page),
        child: AnimatedContainer(
          duration: 180.ms,
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isSelected
                ? AppTheme.tintThemes[context
                      .watch<ClipProvider>()
                      .tintThemeIndex][1]
                : _hovered
                ? AppTheme.surface
                : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.8)
                  : Colors.transparent,
              width: 0.05,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? widget.activeIcon : widget.icon,
                size: 17,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── All Clips Page ──────────────────────────────────────────────────────────

class _AllClipsPage extends StatelessWidget {
  final TextEditingController searchController;

  const _AllClipsPage({required this.searchController});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClipProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(21, 21, 21, 0),
      child: Column(
        children: [
          _PageHeader(provider: provider, searchController: searchController),
          Expanded(
            child: provider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.accent),
                  )
                : provider.filteredItems.isEmpty
                ? _EmptyState(hasSearch: provider.searchQuery.isNotEmpty)
                : _ClipsGrid(items: provider.filteredItems),
          ),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final ClipProvider provider;
  final TextEditingController searchController;

  const _PageHeader({required this.provider, required this.searchController});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomSearchBar(
            controller: searchController,
            onChanged: provider.setSearch,
          ),
          const SizedBox(height: 12),
          FilterBar(
            selected: provider.filter,
            onChanged: provider.setFilter,
            total: provider.allItems.length,
            textCount: provider.textCount,
            imageCount: provider.imageCount,
            urlCount: provider.urlCount,
            codeCount: provider.codeCount,
          ),
        ],
      ),
    );
  }
}

class _ClipsGrid extends StatelessWidget {
  final List<ClipItem> items;

  const _ClipsGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
            onDelete: () => ctx.read<ClipProvider>().deleteItem(item),
            onAddTag: (tag) => ctx.read<ClipProvider>().addTag(item, tag),
            onRemoveTag: (tag) => ctx.read<ClipProvider>().removeTag(item, tag),
            onEdit: item.isImage ? null : (c) => ctx.read<ClipProvider>().editItem(item, c),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasSearch;

  const _EmptyState({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child:
          Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasSearch
                        ? Icons.search_off_rounded
                        : Icons.content_paste_off_rounded,
                    size: 48,
                    color: AppTheme.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    hasSearch ? 'No results found' : 'Nothing copied yet',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasSearch
                        ? 'Try a different search term'
                        : 'Copy something and it will appear here',
                    style: const TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                ],
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.95, 0.95)),
    );
  }
}
