import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../models/clip_item.dart';
import '../theme/app_theme.dart';
import 'glass_container.dart';

class ClipCard extends StatefulWidget {
  final ClipItem item;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onDelete;
  final void Function(String tag) onAddTag;
  final void Function(String tag) onRemoveTag;
  final int index;

  const ClipCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onPin,
    required this.onDelete,
    required this.onAddTag,
    required this.onRemoveTag,
    required this.index,
  });

  @override
  State<ClipCard> createState() => _ClipCardState();
}

class _ClipCardState extends State<ClipCard> {
  bool _hovered = false;

  void _showTagDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => _TagDialog(
        item: widget.item,
        onAdd: widget.onAddTag,
        onRemove: widget.onRemoveTag,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Animate(
      effects: [
        FadeEffect(duration: 200.ms, delay: (widget.index * 30).ms),
        SlideEffect(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
          duration: 280.ms,
          delay: (widget.index * 30).ms,
          curve: Curves.easeOutCubic,
        ),
      ],
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GlassCard(
          onTap: widget.onTap,
          padding: item.isImage ? EdgeInsets.zero : const EdgeInsets.all(11),
          borderRadius: 35,
          child: item.isImage ? _buildImageCard(item) : _buildTextCard(item),
        ),
      ),
    );
  }

  // ── Image card ──────────────────────────────────────────────────────────────

  Widget _buildImageCard(ClipItem item) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-bleed image
        item.imagePath != null
            ? Image.file(
                File(item.imagePath!),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(),
              )
            : _placeholder(),

        // Bottom gradient
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              // stops: [0.35, 1.0],
              colors: [Colors.transparent, Colors.black],
            ),
          ),
        ),

        // Type badge — top left
        Positioned(top: 21, left: 21, child: _TypeBadge(type: item.type)),

        // Dimensions — top right
        if (item.imageWidth != null)
          Positioned(
            top: 21,
            right: 21,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(35),
              ),
              child: Text(
                '${item.imageWidth}×${item.imageHeight}',
                style: const TextStyle(color: Colors.white60, fontSize: 9.5),
              ),
            ),
          ),

        // Bottom content overlay
        Positioned(
          bottom: 11,
          left: 11,
          right: 11,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(11, 0, 11, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.ocrText != null && item.ocrText!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      item.ocrText!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (item.tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 3,
                      children: item.tags
                          .take(3)
                          .map((t) => _MiniTagChip(tag: t))
                          .toList(),
                    ),
                  ),
                Row(
                  children: [
                    Text(
                      _formatTime(item.timestamp),
                      style: const TextStyle(
                        color: Color(0x73FFFFFF),
                        fontSize: 10,
                      ),
                    ),
                    const Spacer(),
                    AnimatedOpacity(
                      opacity: _hovered ? 1 : 0,
                      duration: 150.ms,
                      child: _ActionRow(
                        isPinned: item.isPinned,
                        hasTag: item.tags.isNotEmpty,
                        iconColor: Colors.white60,
                        onPin: widget.onPin,
                        onTag: _showTagDialog,
                        onDelete: widget.onDelete,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Text / URL card ─────────────────────────────────────────────────────────

  Widget _buildTextCard(ClipItem item) {
    final isUrl = item.isUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: type badge + icon
        Padding(
          padding: const EdgeInsets.fromLTRB(13, 12, 13, 0),
          child: Row(
            children: [
              _TypeBadge(type: item.type),
              const Spacer(),
              Icon(
                isUrl ? Icons.link_rounded : Icons.subject_rounded,
                size: 21,
                color: AppTheme.textTertiary,
              ),
            ],
          ),
        ),
        // Main text
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(13, 8, 13, 6),
            child: Text(
              item.preview,
              style: TextStyle(
                color: isUrl ? AppTheme.accentBlue : AppTheme.textPrimary,
                fontSize: 12.5,
                height: 1.5,
                fontFamily: isUrl ? 'Consolas' : null,
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        // Tags
        if (item.tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: Wrap(
              spacing: 4,
              runSpacing: 3,
              children: item.tags
                  .take(3)
                  .map((t) => _MiniTagChip(tag: t))
                  .toList(),
            ),
          ),
        // Footer
        Padding(
          padding: const EdgeInsets.fromLTRB(11, 2, 11, 10),
          child: Row(
            children: [
              Text(
                '${item.textContent?.length ?? 0} chars · ${_formatTime(item.timestamp)}',
                style: const TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              AnimatedOpacity(
                opacity: _hovered ? 1 : 0,
                duration: 150.ms,
                child: _ActionRow(
                  isPinned: item.isPinned,
                  hasTag: item.tags.isNotEmpty,
                  iconColor: AppTheme.textTertiary,
                  onPin: widget.onPin,
                  onTag: _showTagDialog,
                  onDelete: widget.onDelete,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _placeholder() => Container(
    color: AppTheme.surfaceMed,
    child: const Center(
      child: Icon(Icons.image_outlined, size: 36, color: AppTheme.textTertiary),
    ),
  );

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(dt);
  }
}

// ── Shared action row ────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final bool isPinned;
  final bool hasTag;
  final Color iconColor;
  final VoidCallback onPin;
  final VoidCallback onTag;
  final VoidCallback onDelete;

  const _ActionRow({
    required this.isPinned,
    required this.hasTag,
    required this.iconColor,
    required this.onPin,
    required this.onTag,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SmallAction(
          icon: isPinned ? Icons.push_pin : Icons.push_pin_outlined,
          color: isPinned ? AppTheme.accent : iconColor,
          onTap: onPin,
        ),
        _SmallAction(
          icon: Icons.label_outline_rounded,
          color: hasTag ? AppTheme.accentPurple : iconColor,
          onTap: onTag,
        ),
        _SmallAction(
          icon: Icons.delete_outline_rounded,
          color: iconColor,
          hoverColor: AppTheme.accentRed,
          onTap: onDelete,
        ),
      ],
    );
  }
}

// ── Small icon action button ─────────────────────────────────────────────────

class _SmallAction extends StatefulWidget {
  final IconData icon;
  final Color color;
  final Color? hoverColor;
  final VoidCallback onTap;

  const _SmallAction({
    required this.icon,
    required this.color,
    required this.onTap,
    this.hoverColor,
  });

  @override
  State<_SmallAction> createState() => _SmallActionState();
}

class _SmallActionState extends State<_SmallAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = _hovered ? (widget.hoverColor ?? widget.color) : widget.color;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: 120.ms,
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: _hovered
                ? color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(widget.icon, size: 17, color: color),
        ),
      ),
    );
  }
}

// ── Type badge ───────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  final ClipType type;

  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      ClipType.text => ('TEXT', AppTheme.accentGreen),
      ClipType.image => ('IMAGE', AppTheme.accentOrange),
      ClipType.url => ('URL', AppTheme.accentBlue),
    };

    return Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
    );

    // return Container(
    //   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    //   decoration: BoxDecoration(
    //     color: color.withValues(alpha: 0.15),
    //     borderRadius: BorderRadius.circular(4),
    //     border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
    //   ),
    //   child: Text(
    //     label,
    //     style: TextStyle(
    //       color: color,
    //       fontSize: 13,
    //       fontWeight: FontWeight.w900,
    //       letterSpacing: 0.5,
    //     ),
    //   ),
    // );
  }
}

// ── Mini tag chip (on card) ──────────────────────────────────────────────────

class _MiniTagChip extends StatelessWidget {
  final String tag;

  const _MiniTagChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.accentPurple.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppTheme.accentPurple.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        '#$tag',
        style: const TextStyle(
          color: AppTheme.accentPurple,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Tag dialog ───────────────────────────────────────────────────────────────

class _TagDialog extends StatefulWidget {
  final ClipItem item;
  final void Function(String) onAdd;
  final void Function(String) onRemove;

  const _TagDialog({
    required this.item,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<_TagDialog> createState() => _TagDialogState();
}

class _TagDialogState extends State<_TagDialog> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.item.tags);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final tag = _controller.text.trim().toLowerCase().replaceAll(' ', '-');
    if (tag.isEmpty || _tags.contains(tag)) return;
    widget.onAdd(tag);
    setState(() => _tags.add(tag));
    _controller.clear();
  }

  void _remove(String tag) {
    widget.onRemove(tag);
    setState(() => _tags.remove(tag));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF131320),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 40,
              spreadRadius: -8,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.label_rounded,
                  color: AppTheme.accent,
                  size: 17,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Tags',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceMed,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppTheme.textTertiary,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Existing tags
            if (_tags.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _tags
                    .map(
                      (t) =>
                          _RemovableTagChip(tag: t, onRemove: () => _remove(t)),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
              const Divider(color: AppTheme.border, height: 1),
              const SizedBox(height: 14),
            ],
            // Input
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: TextField(
                      controller: _controller,
                      focusNode: _focus,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: 'New tag...',
                        hintStyle: const TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 13,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceMed,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: const BorderSide(
                            color: AppTheme.border,
                            width: 0.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: const BorderSide(
                            color: AppTheme.border,
                            width: 0.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: const BorderSide(
                            color: AppTheme.accent,
                            width: 1,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _submit,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Removable tag chip (dialog) ──────────────────────────────────────────────

class _RemovableTagChip extends StatelessWidget {
  final String tag;
  final VoidCallback onRemove;

  const _RemovableTagChip({required this.tag, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 5, 5, 5),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$tag',
            style: const TextStyle(
              color: AppTheme.accent,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 13,
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
