import 'package:flutter/material.dart';
import '../theme/appdrop_theme_config.dart';

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

  @override
  Widget build(BuildContext context) {
    final dividerColor = styling.sideNavFontColor.withValues(alpha: 0.2);
    final mediaTop = MediaQuery.paddingOf(context).top;
    final topInset = mediaTop > 0 ? mediaTop : statusBarInset;

    return Drawer(
      width: 280,
      backgroundColor: styling.sideNavBg,
      child: SafeArea(
        top: false,
        child: ListView.separated(
          padding: EdgeInsets.only(top: topInset),
          itemCount: config.menuItems.length,
          separatorBuilder: (_, __) => config.showDividers
              ? Divider(height: 1, color: dividerColor)
              : const SizedBox.shrink(),
          itemBuilder: (_, i) {
            final item = config.menuItems[i];
            return ListTile(
              title: Text(
                item.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: styling.sideNavFontColor,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onItemTap?.call(item);
              },
            );
          },
        ),
      ),
    );
  }
}
