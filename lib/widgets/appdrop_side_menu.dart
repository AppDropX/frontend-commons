import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import '../theme/appdrop_theme_config.dart';
import '../theme/appdrop_theme_data.dart';

class AppDropSideMenu extends StatelessWidget {
  final AppStylingConfig styling;
  final SideMenuConfig config;
  final ValueChanged<SideMenuItemEntry>? onItemTap;

  /// Extra top inset when [MediaQuery] has no top padding (builder iPhone frame).
  final double statusBarInset;

  const AppDropSideMenu({
    super.key,
    required this.styling,
    required this.config,
    this.onItemTap,
    this.statusBarInset = 0,
  });

  static const double _kHPad = 20;
  static const double _kChildIndent = 16;
  static const double _kItemFontSize = 13;

  @override
  Widget build(BuildContext context) {
    final fontColor = styling.sideNavFontColor;
    final dividerColor = fontColor.withValues(alpha: 0.10);
    final mediaTop = MediaQuery.paddingOf(context).top;
    final topInset = mediaTop > 0 ? mediaTop : statusBarInset;
    final screenW = MediaQuery.sizeOf(context).width;
    final drawerWidth = (screenW * 0.74).clamp(230.0, 280.0);

    return Drawer(
      width: drawerWidth,
      elevation: 4,
      backgroundColor: styling.sideNavBg,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.14),
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: topInset),
            _SideMenuCloseButton(color: fontColor),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(top: 4, bottom: 32),
                itemCount: config.menuItems.length,
                separatorBuilder: (_, __) => config.showDividers
                    ? Divider(
                        height: 1,
                        thickness: 0.5,
                        indent: _kHPad,
                        endIndent: _kHPad,
                        color: dividerColor,
                      )
                    : const SizedBox.shrink(),
                itemBuilder: (_, i) {
                  final item = config.menuItems[i];
                  if (item.hasChildren) {
                    return _SideMenuGroup(
                      item: item,
                      initiallyExpanded: config.expandDropdowns,
                      fontFamily: styling.fontFamily,
                      color: fontColor,
                      fontSize: _kItemFontSize,
                      horizontalPadding: _kHPad,
                      childIndent: _kChildIndent,
                      onChildTap: (child) {
                        Navigator.pop(context);
                        onItemTap?.call(child);
                      },
                    );
                  }
                  return _SideMenuRow(
                    title: item.title,
                    fontFamily: styling.fontFamily,
                    color: fontColor,
                    fontSize: _kItemFontSize,
                    horizontalPadding: _kHPad,
                    onTap: () {
                      Navigator.pop(context);
                      onItemTap?.call(item);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideMenuCloseButton extends StatelessWidget {
  const _SideMenuCloseButton({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Semantics(
        button: true,
        label: 'Close menu',
        child: IconButton(
          tooltip: 'Close menu',
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            FluentIcons.dismiss_20_regular,
            size: 18,
            color: color,
          ),
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            foregroundColor: color,
            minimumSize: const Size(48, 48),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }
}

class _SideMenuGroup extends StatelessWidget {
  const _SideMenuGroup({
    required this.item,
    required this.initiallyExpanded,
    required this.fontFamily,
    required this.color,
    required this.fontSize,
    required this.horizontalPadding,
    required this.childIndent,
    required this.onChildTap,
  });

  final SideMenuItemEntry item;
  final bool initiallyExpanded;
  final String fontFamily;
  final Color color;
  final double fontSize;
  final double horizontalPadding;
  final double childIndent;
  final ValueChanged<SideMenuItemEntry> onChildTap;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: ValueKey('side-group-${item.id}-$initiallyExpanded'),
        initiallyExpanded: initiallyExpanded,
        tilePadding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        childrenPadding: EdgeInsets.zero,
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        visualDensity: VisualDensity.compact,
        iconColor: color,
        collapsedIconColor: color.withValues(alpha: 0.55),
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        shape: const Border(),
        collapsedShape: const Border(),
        dense: true,
        minTileHeight: 48,
        title: _SideMenuTitle(
          title: item.title,
          fontFamily: fontFamily,
          color: color,
          fontSize: fontSize,
        ),
        children: [
          for (final child in item.children)
            _SideMenuRow(
              title: child.title,
              fontFamily: fontFamily,
              color: color,
              fontSize: fontSize,
              horizontalPadding: horizontalPadding + childIndent,
              compact: true,
              onTap: () => onChildTap(child),
            ),
        ],
      ),
    );
  }
}

class _SideMenuRow extends StatelessWidget {
  const _SideMenuRow({
    required this.title,
    required this.fontFamily,
    required this.color,
    required this.fontSize,
    required this.horizontalPadding,
    required this.onTap,
    this.compact = false,
  });

  final String title;
  final String fontFamily;
  final Color color;
  final double fontSize;
  final double horizontalPadding;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withValues(alpha: 0.06),
        highlightColor: color.withValues(alpha: 0.04),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: compact ? 36 : 48),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: compact ? 4 : 12,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: _SideMenuTitle(
                title: title,
                fontFamily: fontFamily,
                color: color,
                fontSize: fontSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SideMenuTitle extends StatelessWidget {
  const _SideMenuTitle({
    required this.title,
    required this.fontFamily,
    required this.color,
    required this.fontSize,
  });

  final String title;
  final String fontFamily;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final isAllCaps = title.isNotEmpty && title == title.toUpperCase();

    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppDropThemeData.textStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        color: color,
      ).copyWith(
        height: 1.25,
        letterSpacing: isAllCaps ? 0.7 : 0.15,
      ),
    );
  }
}
