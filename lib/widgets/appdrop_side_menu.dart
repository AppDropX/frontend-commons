import 'package:flutter/material.dart';
import '../theme/appdrop_theme_config.dart';

class AppDropSideMenu extends StatelessWidget {
  final AppStylingConfig styling;
  final SideMenuConfig config;
  final ValueChanged<String>? onItemTap;

  const AppDropSideMenu({
    super.key,
    required this.styling,
    required this.config,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final dividerColor = styling.sideNavFontColor.withValues(alpha: 0.2);
    return Drawer(
      backgroundColor: styling.sideNavBg,
      child: SafeArea(
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: config.menuItems.length,
          separatorBuilder: (_, __) => config.showDividers
              ? Divider(height: 1, color: dividerColor)
              : const SizedBox.shrink(),
          itemBuilder: (_, i) {
            final title = config.menuItems[i];
            return ListTile(
              title: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: styling.sideNavFontColor,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onItemTap?.call(title);
              },
            );
          },
        ),
      ),
    );
  }
}
