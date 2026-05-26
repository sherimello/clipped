import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/clip_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClipProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(21, 21, 21, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            provider: provider,
            icon: Icons.settings_rounded,
            label: 'Settings',
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            title: 'General',
            children: [
              _SettingsTile(
                icon: Icons.keyboard_alt_outlined,
                label: 'Global Hotkey',
                subtitle: 'Alt + C to show/hide Clipped',
                provider: provider,
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Alt+C',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.launch_rounded,
                label: 'Launch at startup',
                provider: provider,
                subtitle: 'Start Clipped when Windows starts',
                trailing: Switch(
                  value: provider.launchAtStartup,
                  onChanged: provider.setLaunchAtStartup,
                  activeThumbColor:
                      AppTheme.tintThemes[provider.tintThemeIndex][1],
                  activeTrackColor: Colors.white.withValues(alpha: 0.75),
                  inactiveTrackColor: AppTheme.surfaceMed,
                  inactiveThumbColor: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsGroup(
            title: 'Clipboard',
            children: [
              _SettingsTile(
                icon: Icons.history_rounded,
                label: 'Max History Size',
                provider: provider,
                subtitle: 'Maximum items to keep in history',
                trailing: _HistorySizePicker(
                  value: provider.maxHistory,
                  onChanged: provider.setMaxHistory,
                ),
              ),
              _SettingsTile(
                icon: Icons.image_search_rounded,
                label: 'OCR for Images',
                provider: provider,
                subtitle: 'Extract text from copied images (offline)',
                trailing: _StatusBadge(
                  label: 'Active',
                  color: AppTheme.accentGreen,
                ),
              ),
              _SettingsTile(
                icon: Icons.link_rounded,
                label: 'URL Detection',
                provider: provider,
                subtitle: 'Automatically detect and categorize URLs',
                trailing: _StatusBadge(
                  label: 'Active',
                  color: AppTheme.accentGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsGroup(
            title: 'Appearance',
            children: [
              _SettingsTile(
                icon: Icons.brightness_1_rounded,
                label: 'Background',
                provider: provider,
                subtitle: 'Solid dark with theme tint',
                trailing: _StatusBadge(
                  label: 'Solid',
                  color: AppTheme.textSecondary,
                ),
              ),
              _SettingsTile(
                icon: Icons.dark_mode_rounded,
                provider: provider,
                label: 'Theme',
                subtitle: 'Window background tint',
                trailing: _TintPicker(
                  value: provider.tintThemeIndex,
                  onChanged: provider.setTintTheme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsGroup(
            title: 'Data',
            children: [
              _DangerTile(
                icon: Icons.delete_sweep_rounded,
                label: 'Clear All History',
                subtitle: 'Delete all unpinned clipboard items',
                onTap: () => _confirmClear(context, provider),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.accent, AppTheme.accentPurple],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Icon(
                          Icons.content_paste_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Clipped v1.0.0',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Press Esc or Alt+C to hide  •  Fully Offline & Private',
                  style: TextStyle(color: AppTheme.textTertiary, fontSize: 11),
                ),
                const SizedBox(height: 21),
              ],
            ),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
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
          'Clear All History',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'This will permanently delete all unpinned clipboard items.',
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
              'Clear All',
              style: TextStyle(color: AppTheme.accentRed),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) provider.clearHistory();
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final ClipProvider provider;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Icon(
        //   icon,
        //   color: AppTheme.tintThemes[provider.tintThemeIndex][1],
        //   size: 20,
        // ),
        // const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
        GlassContainer(
          borderRadius: 12,
          padding: EdgeInsets.zero,
          child: Column(
            children: children.asMap().entries.map((e) {
              return Column(
                children: [
                  e.value,
                  if (e.key < children.length - 1)
                    const Divider(
                      height: 0.5,
                      color: AppTheme.border,
                      indent: 48,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final ClipProvider provider;
  final IconData icon;
  final String label;
  final String subtitle;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.trailing,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.tintThemes[provider.tintThemeIndex][1],
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: Colors.white, width: 0.05),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class _DangerTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _DangerTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_DangerTile> createState() => _DangerTileState();
}

class _DangerTileState extends State<_DangerTile> {
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
          color: _hovered
              ? AppTheme.accentRed.withValues(alpha: 0.08)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.accentRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(widget.icon, size: 16, color: AppTheme.accentRed),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: AppTheme.accentRed,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppTheme.accentRed.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TintPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _TintPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(AppTheme.tintThemes.length, (i) {
        final preview = AppTheme.tintThemes[i][1];
        final isSelected = value == i;
        return GestureDetector(
          onTap: () => onChanged(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(left: 6),
            width: isSelected ? 22 : 18,
            height: isSelected ? 22 : 18,
            decoration: BoxDecoration(
              color: preview,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppTheme.accent : Colors.white,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.accent.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ]
                  : [],
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded, size: 11, color: Colors.white)
                : null,
          ),
        );
      }),
    );
  }
}

class _HistorySizePicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _HistorySizePicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      value: value,
      onChanged: (v) => v != null ? onChanged(v) : null,
      dropdownColor: const Color(0xFF1A1A2E),
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
      underline: const SizedBox(),
      items: const [
        DropdownMenuItem(value: 50, child: Text('50 items')),
        DropdownMenuItem(value: 100, child: Text('100 items')),
        DropdownMenuItem(value: 200, child: Text('200 items')),
        DropdownMenuItem(value: 500, child: Text('500 items')),
      ],
    );
  }
}
