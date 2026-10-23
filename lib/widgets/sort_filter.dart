import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme_library.dart';
import '../utils/color.dart';

/// PLP collection heading with SORT / FILTER triggers.
///
/// Transparent bar. With the grid/list switch off, the collection name sits on
/// the left and the actions on the right. With the switch on, Sort and Filter
/// move left and the view buttons sit on the right. Dispatches
/// `{type: sort, sort, order}` and `{type: open_filter}`.
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
  final actionsRaw = node.props['showSortAndFilter'];
  final actionsFallback = node.b('showSortButton', def: true) ||
      node.b('showFilterButton', def: true);
  final visibility = SortFilterVisibility.resolve(
    showTitle: node.b('showTitle', def: true),
    showSortAndFilter: actionsRaw is bool ? actionsRaw : actionsFallback,
    showViewToggle: node.b('showViewToggle'),
  );
  final showTitle = visibility.showTitle;
  final showSortButton = visibility.showSortAndFilter;
  final showFilterButton = visibility.showSortAndFilter;
  final showViewToggle = visibility.showViewToggle;
  final selectedSort = node.s('selectedSort').trim();
  final selectedOrder = node.s('selectedOrder').trim();
  final hasActiveFilters = node.b('hasActiveFilters');
  final layoutMode = PlpLayoutScope.watch(context)?.mode ?? 'grid';

  final titleColor =
      parseHexColor(node.s('titleColor', def: '')) ?? content;
  final actionColor = parseHexColor(node.s('actionColor', def: '')) ??
      content.withValues(alpha: 0.62);

  return _PlpViewToggleSync(
    enabled: showViewToggle,
    child: _SortFilterBar(
    collectionTitle:
        collectionTitle.isEmpty ? 'Collection' : collectionTitle,
    sortLabel: sortLabel.isEmpty ? 'SORT' : sortLabel,
    filterLabel: filterLabel.isEmpty ? 'FILTER' : filterLabel,
    showTitle: showTitle,
    showSortButton: showSortButton,
    showFilterButton: showFilterButton,
    showViewToggle: showViewToggle,
    sortIcon: node.s('sortIcon', def: 'chevron_down'),
    sortIconUrl: node.s('sortIconUrl'),
    filterIcon: node.s('filterIcon', def: 'chevron_down'),
    filterIconUrl: node.s('filterIconUrl'),
    gridIcon: node.s('gridIcon', def: 'grid_view'),
    gridIconUrl: node.s('gridIconUrl'),
    listIcon: node.s('listIcon', def: 'list'),
    listIconUrl: node.s('listIconUrl'),
    iconBeforeLabel: node.b('iconBeforeLabel'),
    layoutMode: layoutMode,
    selectedSort: selectedSort,
    selectedOrder: selectedOrder,
    hasActiveFilters: hasActiveFilters,
    titleColor: titleColor,
    actionColor: actionColor,
    r: r,
    onLayoutSelected: (mode) {
      final controller = PlpLayoutScope.read(context);
      controller?.syncEnabled(showViewToggle);
      controller?.setMode(mode);
    },
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
    ),
  );
}

/// Publishes the merchant's grid/list toggle onto the page layout controller.
class _PlpViewToggleSync extends StatefulWidget {
  const _PlpViewToggleSync({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  State<_PlpViewToggleSync> createState() => _PlpViewToggleSyncState();
}

class _PlpViewToggleSyncState extends State<_PlpViewToggleSync> {
  @override
  void initState() {
    super.initState();
    _scheduleSync();
  }

  @override
  void didUpdateWidget(covariant _PlpViewToggleSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) _scheduleSync();
  }

  void _scheduleSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      PlpLayoutScope.read(context)?.syncEnabled(widget.enabled);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _SortFilterBar extends StatelessWidget {
  const _SortFilterBar({
    required this.collectionTitle,
    required this.sortLabel,
    required this.filterLabel,
    required this.showTitle,
    required this.showSortButton,
    required this.showFilterButton,
    required this.showViewToggle,
    required this.sortIcon,
    required this.sortIconUrl,
    required this.filterIcon,
    required this.filterIconUrl,
    required this.gridIcon,
    required this.gridIconUrl,
    required this.listIcon,
    required this.listIconUrl,
    required this.iconBeforeLabel,
    required this.layoutMode,
    required this.selectedSort,
    required this.selectedOrder,
    required this.hasActiveFilters,
    required this.titleColor,
    required this.actionColor,
    required this.r,
    required this.onLayoutSelected,
    required this.onSortSelected,
    required this.onFilterTap,
  });

  final String collectionTitle;
  final String sortLabel;
  final String filterLabel;
  final bool showTitle;
  final bool showSortButton;
  final bool showFilterButton;
  final bool showViewToggle;
  final String sortIcon;
  final String sortIconUrl;
  final String filterIcon;
  final String filterIconUrl;
  final String gridIcon;
  final String gridIconUrl;
  final String listIcon;
  final String listIconUrl;
  final bool iconBeforeLabel;
  final String layoutMode;
  final String selectedSort;
  final String selectedOrder;
  final bool hasActiveFilters;
  final Color titleColor;
  final Color actionColor;
  final R r;
  final ValueChanged<String> onLayoutSelected;
  final ValueChanged<ProductSortChoice> onSortSelected;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final titleSize = r.sp(15, min: 13, max: 18);
    final actionSize = r.sp(11, min: 10, max: 13);
    final iconSize = r.dp(18);

    final title = Text(
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
    );

    final sortButton = _SortMenuButton(
      label: sortLabel.toUpperCase(),
      color: actionColor,
      fontSize: actionSize,
      iconSize: iconSize,
      iconBeforeLabel: iconBeforeLabel,
      iconGlyph: sortIcon,
      iconUrl: sortIconUrl,
      selectedSort: selectedSort,
      selectedOrder: selectedOrder,
      onSelected: onSortSelected,
    );
    final filterButton = _FilterActionButton(
      label: filterLabel.toUpperCase(),
      color: actionColor,
      fontSize: actionSize,
      iconSize: iconSize,
      iconBeforeLabel: iconBeforeLabel,
      iconGlyph: filterIcon,
      iconUrl: filterIconUrl,
      hasActiveFilters: hasActiveFilters,
      onTap: onFilterTap,
    );
    final viewButtons = _ViewModeToggle(
      mode: layoutMode,
      activeColor: titleColor,
      inactiveColor: actionColor,
      gridIcon: gridIcon,
      gridIconUrl: gridIconUrl,
      listIcon: listIcon,
      listIconUrl: listIconUrl,
      iconSize: iconSize,
      onSelected: onLayoutSelected,
    );

    // View buttons sit on the right. Sort and Filter move to the left, and the
    // collection title only stays if its own toggle is still on.
    final children = showViewToggle
        ? <Widget>[
            if (showSortButton) sortButton,
            if (showFilterButton) filterButton,
            if (showTitle)
              Expanded(child: title)
            else
              const Spacer(),
            viewButtons,
          ]
        : <Widget>[
            if (showTitle) Expanded(child: title) else const Spacer(),
            if (showSortButton) sortButton,
            if (showFilterButton) ...[
              SizedBox(width: r.dp(4)),
              filterButton,
            ],
          ];

    return Padding(
      padding: EdgeInsets.fromLTRB(r.dp(8), r.dp(8), r.dp(4), r.dp(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
    );
  }
}

class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle({
    required this.mode,
    required this.activeColor,
    required this.inactiveColor,
    required this.gridIcon,
    required this.gridIconUrl,
    required this.listIcon,
    required this.listIconUrl,
    required this.iconSize,
    required this.onSelected,
  });

  final String mode;
  final Color activeColor;
  final Color inactiveColor;
  final String gridIcon;
  final String gridIconUrl;
  final String listIcon;
  final String listIconUrl;
  final double iconSize;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ViewModeButton(
          label: 'Grid view',
          glyph: gridIcon,
          iconUrl: gridIconUrl,
          iconSize: iconSize,
          selected: mode != 'list',
          activeColor: activeColor,
          inactiveColor: inactiveColor,
          onTap: () => onSelected('grid'),
        ),
        const SizedBox(width: 4),
        _ViewModeButton(
          label: 'List view',
          glyph: listIcon,
          iconUrl: listIconUrl,
          iconSize: iconSize,
          selected: mode == 'list',
          activeColor: activeColor,
          inactiveColor: inactiveColor,
          onTap: () => onSelected('list'),
        ),
      ],
    );
  }
}

class _ViewModeButton extends StatelessWidget {
  const _ViewModeButton({
    required this.label,
    required this.glyph,
    required this.iconUrl,
    required this.iconSize,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final String label;
  final String glyph;
  final String iconUrl;
  final double iconSize;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? activeColor : inactiveColor;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: selected
                  ? BoxDecoration(color: activeColor.withValues(alpha: 0.14))
                  : null,
              child: _PlpBarIcon(
                glyph: glyph.isEmpty ? 'grid_view' : glyph,
                iconUrl: iconUrl,
                size: iconSize,
                color: color,
                filled: selected,
              ),
            ),
          ),
        ),
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
    required this.iconBeforeLabel,
    required this.iconGlyph,
    required this.iconUrl,
    required this.selectedSort,
    required this.selectedOrder,
    required this.onSelected,
  });

  final String label;
  final Color color;
  final double fontSize;
  final double iconSize;
  final bool iconBeforeLabel;
  final String iconGlyph;
  final String iconUrl;
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
          iconBeforeLabel: iconBeforeLabel,
          iconGlyph: iconGlyph,
          iconUrl: iconUrl,
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
    required this.iconBeforeLabel,
    required this.iconGlyph,
    required this.iconUrl,
    required this.hasActiveFilters,
    required this.onTap,
  });

  final String label;
  final Color color;
  final double fontSize;
  final double iconSize;
  final bool iconBeforeLabel;
  final String iconGlyph;
  final String iconUrl;
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
              iconBeforeLabel: iconBeforeLabel,
              iconGlyph: iconGlyph,
              iconUrl: iconUrl,
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

class _PlpBarIcon extends StatelessWidget {
  const _PlpBarIcon({
    required this.glyph,
    required this.iconUrl,
    required this.size,
    required this.color,
    this.filled = false,
  });

  final String glyph;
  final String iconUrl;
  final double size;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final resolved = glyph.trim().isEmpty ? 'chevron_down' : glyph.trim();
    final drawn = size * sortFilterIconScale(resolved);
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: AppDropTintedGraphic(
          glyph: resolved,
          svgUrl: iconUrl,
          size: drawn,
          color: color,
          filled: filled,
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
    required this.iconBeforeLabel,
    required this.iconGlyph,
    required this.iconUrl,
  });

  final String label;
  final Color color;
  final double fontSize;
  final double iconSize;
  final bool iconBeforeLabel;
  final String iconGlyph;
  final String iconUrl;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconBeforeLabel) ...[
              _PlpBarIcon(
                glyph: iconGlyph,
                iconUrl: iconUrl,
                size: iconSize,
                color: color,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.3,
              ),
            ),
            if (!iconBeforeLabel) ...[
              const SizedBox(width: 4),
              _PlpBarIcon(
                glyph: iconGlyph,
                iconUrl: iconUrl,
                size: iconSize,
                color: color,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
