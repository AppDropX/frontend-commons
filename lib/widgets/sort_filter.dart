import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme_library.dart';
import '../utils/color.dart';

/// PLP collection heading with SORT / FILTER triggers.
///
/// Transparent bar: serif collection name on the left, sans-serif actions on
/// the right. Dispatches `{type: sort, sort, order}` and `{type: open_filter}`.
Widget buildSortFilter(
  BuildContext context,
  WidgetNode node,
  AppDropBuildEnv env,
) {
  final enabled = node.b('enabled', def: true);
  if (!enabled) return const SizedBox.shrink();

  final r = env.r;
  final cfg = AppDropThemeScope.maybeOf(context);
  final content = cfg?.appStyling.fontIconColor ?? const Color(0xFF2C2C2C);

  final collectionTitle = node.s('collectionTitle').trim();
  final sortLabel = node.s('sortLabel', def: 'SORT').trim();
  final filterLabel = node.s('filterLabel', def: 'FILTER').trim();
  final showFilterButton = node.b('showFilterButton', def: true);
  final selectedSort = node.s('selectedSort').trim();
  final selectedOrder = node.s('selectedOrder').trim();
  final hasActiveFilters = node.b('hasActiveFilters');

  final titleColor =
      parseHexColor(node.s('titleColor', def: '')) ?? content;
  final actionColor = parseHexColor(node.s('actionColor', def: '')) ??
      content.withValues(alpha: 0.62);

  return _SortFilterBar(
    collectionTitle:
        collectionTitle.isEmpty ? 'Collection' : collectionTitle,
    sortLabel: sortLabel.isEmpty ? 'SORT' : sortLabel,
    filterLabel: filterLabel.isEmpty ? 'FILTER' : filterLabel,
    showFilterButton: showFilterButton,
    selectedSort: selectedSort,
    selectedOrder: selectedOrder,
    hasActiveFilters: hasActiveFilters,
    titleColor: titleColor,
    actionColor: actionColor,
    r: r,
    onSortSelected: (choice) {
      env.dispatchAction(context, {
        'type': 'sort',
        'sort': choice.sort,
        'order': choice.order,
        'value': choice.label,
      });
    },
    onFilterTap: () {
      env.dispatchAction(context, {'type': 'open_filter'});
    },
  );
}

class _SortFilterBar extends StatelessWidget {
  const _SortFilterBar({
    required this.collectionTitle,
    required this.sortLabel,
    required this.filterLabel,
    required this.showFilterButton,
    required this.selectedSort,
    required this.selectedOrder,
    required this.hasActiveFilters,
    required this.titleColor,
    required this.actionColor,
    required this.r,
    required this.onSortSelected,
    required this.onFilterTap,
  });

  final String collectionTitle;
  final String sortLabel;
  final String filterLabel;
  final bool showFilterButton;
  final String selectedSort;
  final String selectedOrder;
  final bool hasActiveFilters;
  final Color titleColor;
  final Color actionColor;
  final R r;
  final ValueChanged<ProductSortChoice> onSortSelected;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final titleSize = r.sp(15, min: 13, max: 18);
    final actionSize = r.sp(11, min: 10, max: 13);

    return Padding(
      padding: EdgeInsets.fromLTRB(r.dp(8), r.dp(8), r.dp(4), r.dp(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              collectionTitle.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.playfairDisplay(
                color: titleColor,
                fontSize: titleSize,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.4,
                height: 1.2,
              ),
            ),
          ),
          _SortMenuButton(
            label: sortLabel.toUpperCase(),
            color: actionColor,
            fontSize: actionSize,
            iconSize: r.dp(14),
            selectedSort: selectedSort,
            selectedOrder: selectedOrder,
            onSelected: onSortSelected,
          ),
          if (showFilterButton) ...[
            SizedBox(width: r.dp(4)),
            _FilterActionButton(
              label: filterLabel.toUpperCase(),
              color: actionColor,
              fontSize: actionSize,
              iconSize: r.dp(14),
              hasActiveFilters: hasActiveFilters,
              onTap: onFilterTap,
            ),
          ],
        ],
      ),
    );
  }
}

class _SortMenuButton extends StatelessWidget {
  const _SortMenuButton({
    required this.label,
    required this.color,
    required this.fontSize,
    required this.iconSize,
    required this.selectedSort,
    required this.selectedOrder,
    required this.onSelected,
  });

  final String label;
  final Color color;
  final double fontSize;
  final double iconSize;
  final String selectedSort;
  final String selectedOrder;
  final ValueChanged<ProductSortChoice> onSelected;

  @override
  Widget build(BuildContext context) {
    final cfg = AppDropThemeScope.maybeOf(context);
    final menuBg = cfg?.appStyling.bgColor ??
        Theme.of(context).scaffoldBackgroundColor;
    final menuFg = cfg?.appStyling.fontIconColor ?? color;

    return PopupMenuButton<ProductSortChoice>(
      tooltip: 'Sort',
      padding: EdgeInsets.zero,
      offset: const Offset(0, 36),
      color: menuBg,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final choice in kProductSortChoices)
          PopupMenuItem<ProductSortChoice>(
            value: choice,
            child: Text(
              choice.label,
              style: TextStyle(
                color: menuFg,
                fontWeight: choice.matches(selectedSort, selectedOrder)
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),
      ],
      child: Semantics(
        button: true,
        label: 'Sort',
        child: _ActionLabel(
          label: label,
          color: color,
          fontSize: fontSize,
          iconSize: iconSize,
        ),
      ),
    );
  }
}

class _FilterActionButton extends StatelessWidget {
  const _FilterActionButton({
    required this.label,
    required this.color,
    required this.fontSize,
    required this.iconSize,
    required this.hasActiveFilters,
    required this.onTap,
  });

  final String label;
  final Color color;
  final double fontSize;
  final double iconSize;
  final bool hasActiveFilters;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Filter',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _ActionLabel(
              label: label,
              color: color,
              fontSize: fontSize,
              iconSize: iconSize,
            ),
            if (hasActiveFilters)
              Positioned(
                top: 10,
                right: 6,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionLabel extends StatelessWidget {
  const _ActionLabel({
    required this.label,
    required this.color,
    required this.fontSize,
    required this.iconSize,
  });

  final String label;
  final Color color;
  final double fontSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              FluentIcons.chevron_down_20_regular,
              size: iconSize,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
