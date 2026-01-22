import 'package:flutter/material.dart';
import '../theme/appdrop_theme_config.dart';
import '../utils/icon_mapper.dart';

class AppDropAppBar extends StatelessWidget implements PreferredSizeWidget {
  final AppStylingConfig styling;
  final String title;
  final bool showMenu;
  final bool showCart;
  final VoidCallback? onCartTap;

  const AppDropAppBar({
    super.key,
    required this.styling,
    required this.title,
    required this.showMenu,
    required this.showCart,
    this.onCartTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: styling.toolbarBg,
      foregroundColor: styling.toolbarFont,
      centerTitle: true,
      leading: showMenu
          ? Builder(
        builder: (ctx) => IconButton(
          icon: Icon(iconFromName('menu'), color: styling.toolbarFont),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      )
          : null,
      title: Text(title, style: TextStyle(color: styling.toolbarFont, fontWeight: FontWeight.w600)),
      actions: [
        if (showCart)
          IconButton(
            icon: Icon(iconFromName('shopping_cart_outlined'), color: styling.toolbarFont),
            onPressed: onCartTap,
          ),
      ],
    );
  }
}
