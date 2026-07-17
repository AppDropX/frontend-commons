import 'package:flutter/material.dart';
import '../models/page_toolbar_config.dart';
import '../theme/appdrop_theme_config.dart';
import '../utils/icon_mapper.dart';
import '../utils/network_image_url.dart';

class AppDropAppBar extends StatelessWidget implements PreferredSizeWidget {
  final AppStylingConfig styling;
  final String title;
  final double toolbarHeight;
  final bool showMenu;
  final bool showCart;
  final VoidCallback? onCartTap;

  /// Total units in cart; shown as a badge on the cart icon when > 0.
  final int? cartBadgeCount;

  /// When set, drives leading, title, and actions (PLP / Home / custom toolbars).
  final PageToolbarConfig? pageToolbar;

  /// Whether a drawer is available (required for side-navigation leading control).
  final bool hasDrawer;
  final VoidCallback? onBack;
  final VoidCallback? onWishlistTap;
  final bool wishlistSelected;
  final VoidCallback? onSearchTap;

  /// When the app runs inside the builder iPhone frame, pass
  /// [Iphone15ProPreview.safeTop] so the toolbar row sits below the painted
  /// status bar instead of vertically centering in a combined height.
  final double statusBarInset;

  const AppDropAppBar({
    super.key,
    required this.toolbarHeight,
    required this.styling,
    required this.title,
    required this.showMenu,
    required this.showCart,
    this.onCartTap,
    this.cartBadgeCount,
    this.pageToolbar,
    this.hasDrawer = false,
    this.onBack,
    this.onWishlistTap,
    this.wishlistSelected = false,
    this.onSearchTap,
    this.statusBarInset = 0,
  });

  double get _toolbarContentHeight => toolbarHeight;
  double get _h => _toolbarContentHeight + statusBarInset;
  @override
  Size get preferredSize => Size.fromHeight(_h);

  Widget? _leading(BuildContext context) {
    final pt = pageToolbar;
    if (pt != null) {
      switch (pt.left) {
        case ToolbarLeft.sideNavigation:
          if (!hasDrawer) return null;
          return Builder(
            builder: (ctx) => IconButton(
              icon: Icon(iconFromName('menu'), color: styling.toolbarFont),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          );
        case ToolbarLeft.back:
          return IconButton(
            icon: Icon(iconFromName('back'),
                color: styling.toolbarFont, size: 20),
            onPressed: onBack ?? () => Navigator.maybePop(context),
          );
        case ToolbarLeft.none:
        default:
          return null;
      }
    }
    if (showMenu) {
      return Builder(
        builder: (ctx) => IconButton(
          icon: Icon(iconFromName('menu'), color: styling.toolbarFont),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      );
    }
    return null;
  }

  Widget _titleWidget() {
    final pt = pageToolbar;
    if (pt != null) {
      if (pt.center == ToolbarCenter.none) {
        return const SizedBox.shrink();
      }
      if (pt.center == ToolbarCenter.text) {
        return Text(
          pt.centerText.isEmpty ? title : pt.centerText,
          style: TextStyle(
              color: styling.toolbarFont, fontWeight: FontWeight.w600),
        );
      }
      if (pt.center == ToolbarCenter.logo) {
        final url = sanitizedNetworkImageUrl(pt.centerLogoUrl);
        if (url == null) {
          return const SizedBox.shrink();
        }
        final logoHeight = (_toolbarContentHeight * 0.52).clamp(28.0, 44.0);
        return SizedBox(
          height: logoHeight,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        );
      }
      if (pt.center == ToolbarCenter.collectionSearch) {
        return Text(
          'Collection',
          style: TextStyle(
              color: styling.toolbarFont, fontWeight: FontWeight.w600),
        );
      }
    }
    return Text(title,
        style:
            TextStyle(color: styling.toolbarFont, fontWeight: FontWeight.w600));
  }

  Widget? _slotAction(String slot) {
    switch (slot) {
      case ToolbarRight.none:
        return null;
      case ToolbarRight.cart:
        return IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(iconFromName('shopping_cart_outlined'),
                  color: styling.toolbarFont),
              if (cartBadgeCount != null && cartBadgeCount! > 0)
                Positioned(
                  right: -6,
                  top: -4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    alignment: Alignment.center,
                    child: Text(
                      cartBadgeCount! > 99 ? '99+' : '${cartBadgeCount!}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          onPressed: onCartTap,
        );
      case ToolbarRight.wishlist:
        return IconButton(
          icon: Icon(
            wishlistSelected ? Icons.favorite : iconFromName('favorite_border'),
            color: styling.toolbarFont,
          ),
          onPressed: onWishlistTap,
        );
      case ToolbarRight.search:
        return IconButton(
          icon: Icon(iconFromName('search'), color: styling.toolbarFont),
          onPressed: onSearchTap,
        );
      default:
        return null;
    }
  }

  List<Widget> _actions() {
    final pt = pageToolbar;
    if (pt != null) {
      final out = <Widget>[];
      void addSlot(String s) {
        final w = _slotAction(s);
        if (w != null) out.add(w);
      }

      addSlot(pt.rightSlot1);
      addSlot(pt.rightSlot2);
      return out;
    }
    if (showCart) {
      return [
        IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(iconFromName('shopping_cart_outlined'),
                  color: styling.toolbarFont),
              if (cartBadgeCount != null && cartBadgeCount! > 0)
                Positioned(
                  right: -6,
                  top: -4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    alignment: Alignment.center,
                    child: Text(
                      cartBadgeCount! > 99 ? '99+' : '${cartBadgeCount!}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          onPressed: onCartTap,
        ),
      ];
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final pt = pageToolbar;
    final useToolbar = pt != null;
    final leading = _leading(context);
    final actions = _actions();
    final appBar = AppBar(
      elevation: 0,
      shadowColor: Colors.transparent,
      scrolledUnderElevation: 0,
      primary: statusBarInset <= 0,
      toolbarHeight: _toolbarContentHeight,
      surfaceTintColor: styling.toolbarBg,
      backgroundColor: styling.toolbarBg,
      foregroundColor: styling.toolbarFont,
      centerTitle: true,
      leading: leading,
      automaticallyImplyLeading: !useToolbar && showMenu,
      title: _titleWidget(),
      actions: actions,
    );

    if (statusBarInset <= 0) return appBar;

    return ColoredBox(
      color: styling.toolbarBg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: statusBarInset),
          appBar,
        ],
      ),
    );
  }
}
