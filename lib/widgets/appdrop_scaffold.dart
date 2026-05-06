import 'package:flutter/material.dart';

import '../theme/appdrop_theme_config.dart';
import '../theme/appdrop_theme_scope.dart';

import '../theme_library.dart';
import 'appdrop_app_bar.dart';
import 'appdrop_top_tabs.dart';
import 'appdrop_side_menu.dart';
import 'appdrop_bottom_nav.dart';

class AppDropScaffold extends StatefulWidget {
  /// your theme JSON (app_styling, bottom_bar, product_block, side_menu, top_navigation)
  final Map<String, dynamic> themeJson;

  /// your page widgets json (banner/slider/product_grid etc.)
  final List<dynamic> pageJson;

  final String title;
  final double appbarHeight;

  final void Function(int index, TopNavTabEntry tab)? onTabChanged;

  /// Selects which top tab is highlighted (e.g. current storefront page).
  final int initialTopTabIndex;
  final void Function(SideMenuItemEntry item)? onMenuItemTap;
  final void Function(int index, BottomBarItemConfig item)? onBottomNavTap;
  final VoidCallback? onCartTap;

  final void Function(BuildContext ctx, Map<String, dynamic> action)? onAction;
  final bool showTopTabs;

  /// When false, omits [AppDropBottomNav] (e.g. product detail pushed above the shell).
  final bool showBottomNav;

  /// Index among **enabled** bottom bar items (same order as [AppDropBottomNav]).
  final int initialBottomNavIndex;

  /// PLP product grid: per-product quantity in cart for stepper UI.
  final CartQuantityResolver? cartQuantityForProduct;

  /// Total units in cart; badge on app bar cart icon when > 0.
  final int? cartBadgeCount;

  /// Optional per-page toolbar (Home / PLP / custom). When null, uses [title] + drawer + cart.
  final PageToolbarConfig? pageToolbar;

  final VoidCallback? onWishlistTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onBack;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final Widget? bodyOverride;

  const AppDropScaffold({
    super.key,
    required this.themeJson,
    required this.pageJson,
    required this.appbarHeight,
    this.title = 'Store',
    this.initialBottomNavIndex = 0,
    this.onTabChanged,
    this.initialTopTabIndex = 0,
    this.onMenuItemTap,
    this.onBottomNavTap,
    this.onCartTap,
    this.onAction,
    this.showTopTabs = true,
    this.showBottomNav = true,
    this.cartQuantityForProduct,
    this.cartBadgeCount,
    this.pageToolbar,
    this.onWishlistTap,
    this.onSearchTap,
    this.onBack,
    this.scaffoldKey,
    this.bodyOverride,
  });

  @override
  State<AppDropScaffold> createState() => _AppDropScaffoldState();
}

class _AppDropScaffoldState extends State<AppDropScaffold> {
  late int tabIndex;
  late int bottomIndex;

  @override
  void initState() {
    super.initState();
    bottomIndex = widget.initialBottomNavIndex;
    tabIndex = widget.initialTopTabIndex;
  }

  @override
  void didUpdateWidget(AppDropScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialBottomNavIndex != widget.initialBottomNavIndex) {
      bottomIndex = widget.initialBottomNavIndex;
    }
    if (oldWidget.initialTopTabIndex != widget.initialTopTabIndex) {
      tabIndex = widget.initialTopTabIndex;
    }
  }

  /// Splits pageJson into inline blocks and CTA blocks with scrollStyle "fixed_at_bottom".
  static void _splitPageJson(List<dynamic> pageJson, List<dynamic> inlineOut, List<dynamic> fixedBottomOut) {
    for (final item in pageJson) {
      final map = item is Map ? item as Map<String, dynamic> : null;
      if (map == null) {
        inlineOut.add(item);
        continue;
      }
      final type = (map['type'] ?? '').toString();
      final scrollStyle = (map['scrollStyle'] ?? 'inline').toString().toLowerCase();
      if (type == 'cta_button' && scrollStyle == 'fixed_at_bottom') {
        fixedBottomOut.add(Map<String, dynamic>.from(map));
      } else {
        inlineOut.add(item);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = AppDropThemeConfig.fromJson(widget.themeJson);
    final topItems = cfg.topNavigation.items;
    final safeTopTabIndex = topItems.isEmpty
        ? 0
        : tabIndex.clamp(0, topItems.length - 1);
    final inlineJson = <dynamic>[];
    final fixedBottomJson = <dynamic>[];
    _splitPageJson(widget.pageJson, inlineJson, fixedBottomJson);

    final inlineNodes = WidgetNode.listFromJson(inlineJson);
    final fixedBottomNodes = fixedBottomJson.isEmpty
        ? <WidgetNode>[]
        : WidgetNode.listFromJson(fixedBottomJson);

    final hasDrawer = cfg.sideMenu.menuItems.isNotEmpty;
    final bottomItems = cfg.bottomBar.items.where((e) => e.enabled).toList();
    final theme = AppDropThemeData.buildFromConfig(cfg); // ✅ add this


    if (bottomIndex >= bottomItems.length) bottomIndex = 0;

    final registry = WidgetRegistry.defaults();
    final onAction = widget.onAction != null
        ? (dynamic ctx, Map<String, dynamic> action) =>
            widget.onAction!.call(ctx as BuildContext, action)
        : null;

    return AppDropThemeScope(
      config: cfg,
      child: Theme(
        data: theme,
        child: Scaffold(
          key: widget.scaffoldKey,
          drawer: hasDrawer
              ? AppDropSideMenu(
            styling: cfg.appStyling,
            config: cfg.sideMenu,
            onItemTap: (item) => widget.onMenuItemTap?.call(item),
          )
              : null,
          appBar: AppDropAppBar(
            toolbarHeight: widget.appbarHeight,
            styling: cfg.appStyling,
            title: widget.title,
            showMenu: hasDrawer,
            showCart: widget.pageToolbar == null,
            onCartTap: widget.onCartTap,
            cartBadgeCount: widget.cartBadgeCount,
            pageToolbar: widget.pageToolbar,
            hasDrawer: hasDrawer,
            onBack: widget.onBack,
            onWishlistTap: widget.onWishlistTap,
            onSearchTap: widget.onSearchTap,
          ),
          bottomNavigationBar: widget.showBottomNav
              ? AppDropBottomNav(
                  styling: cfg.appStyling,
                  config: cfg.bottomBar,
                  currentIndex: bottomIndex,
                  onTap: (i) {
                    setState(() => bottomIndex = i);
                    if (i < bottomItems.length) {
                      widget.onBottomNavTap?.call(i, bottomItems[i]);
                    }
                  },
                )
              : null,
          body: Column(
            children: [
              if (widget.showTopTabs && topItems.isNotEmpty)
                Transform.translate(
                  offset: const Offset(0, -1),
                  child: AppDropTopTabs(
                    styling: cfg.appStyling,
                    config: cfg.topNavigation,
                    selectedIndex: safeTopTabIndex,
                    onChanged: (i) {
                      setState(() => tabIndex = i);
                      widget.onTabChanged?.call(i, cfg.topNavigation.items[i]);
                    },
                  ),
                ),
              Expanded(
                child: widget.bodyOverride ??
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: AppDropRenderer(
                        nodes: inlineNodes,
                        registry: registry,
                        onAction: onAction,
                        cartQuantityForProduct: widget.cartQuantityForProduct,
                      ),
                    ),
              ),
              if (widget.bodyOverride == null && fixedBottomNodes.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: AppDropRenderer(
                      nodes: fixedBottomNodes,
                      registry: registry,
                      onAction: onAction,
                      cartQuantityForProduct: widget.cartQuantityForProduct,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
