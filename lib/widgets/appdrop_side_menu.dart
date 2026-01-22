import 'package:flutter/material.dart';
import '../theme/appdrop_theme_config.dart';

class AppDropSideMenu extends StatelessWidget {
  final SideMenuConfig config;
  final ValueChanged<String>? onItemTap;

  const AppDropSideMenu({
    super.key,
    required this.config,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: config.menuItems.length,
          separatorBuilder: (_, __) => config.showDividers ? const Divider(height: 1) : const SizedBox.shrink(),
          itemBuilder: (_, i) {
            final title = config.menuItems[i];
            return ListTile(
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
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
