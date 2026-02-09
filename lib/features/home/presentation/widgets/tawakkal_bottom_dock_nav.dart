import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';

class TawakkalBottomDockNav extends StatelessWidget {
  const TawakkalBottomDockNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const List<_DockItemData> _items = [
    _DockItemData(index: 0, label: 'Home', icon: Icons.home_rounded),
    _DockItemData(index: 1, label: 'Quran', icon: Icons.menu_book_rounded),
    _DockItemData(
      index: 2,
      label: 'Belajar',
      icon: Icons.school_rounded,
      center: true,
    ),
    _DockItemData(index: 3, label: 'Audio', icon: Icons.headphones_rounded),
    _DockItemData(index: 4, label: 'Profil', icon: Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? TawakkalColors.surfaceDark.withValues(alpha: 0.94)
              : TawakkalColors.surfaceLight.withValues(alpha: 0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0x1EFFFFFF) : const Color(0x14000000),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.1),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
          8,
          10,
          8,
          bottomInset > 0 ? bottomInset : 10,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: _items.map((item) {
            return Expanded(
              child: item.center
                  ? _CenterDockItem(
                      item: item,
                      selected: selectedIndex == item.index,
                      onTap: () => onSelected(item.index),
                    )
                  : _DockItem(
                      item: item,
                      selected: selectedIndex == item.index,
                      onTap: () => onSelected(item.index),
                    ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _DockItemData item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = TawakkalColors.primary;
    final inactiveColor = isDark
        ? TawakkalColors.textSecondary
        : TawakkalColors.textPrimaryLight.withValues(alpha: 0.62);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 23,
              color: selected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected ? activeColor : inactiveColor,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterDockItem extends StatelessWidget {
  const _CenterDockItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _DockItemData item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glow = TawakkalColors.primary.withValues(alpha: isDark ? 0.35 : 0.26);

    return Transform.translate(
      offset: const Offset(0, -18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TawakkalColors.primary,
                border: Border.all(
                  color: isDark ? TawakkalColors.backgroundDark : Colors.white,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: glow,
                    blurRadius: selected ? 22 : 14,
                    spreadRadius: selected ? 0.5 : 0,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 30,
                color: TawakkalColors.backgroundDark,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: selected
                  ? TawakkalColors.primary
                  : TawakkalColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DockItemData {
  const _DockItemData({
    required this.index,
    required this.label,
    required this.icon,
    this.center = false,
  });

  final int index;
  final String label;
  final IconData icon;
  final bool center;
}
