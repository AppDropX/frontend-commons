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

  final void Function(int index, String tab)? onTabChanged;
  final void Function(String item)? onMenuItemTap;
  final void Function(int index, BottomBarItemConfig item)? onBottomNavTap;
  final VoidCallback? onCartTap;

  final void Function(BuildContext ctx, Map<String, dynamic> action)? onAction;

  const AppDropScaffold({
    super.key,
    required this.themeJson,
    required this.pageJson,
    required this.appbarHeight,
    this.title = 'Store',
    this.onTabChanged,
    this.onMenuItemTap,
    this.onBottomNavTap,
    this.onCartTap,
    this.onAction,
  });

  @override
  State<AppDropScaffold> createState() => _AppDropScaffoldState();
}

class _AppDropScaffoldState extends State<AppDropScaffold> {
  int tabIndex = 0;
  int bottomIndex = 0;

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
          drawer: hasDrawer
              ? AppDropSideMenu(
            config: cfg.sideMenu,
            onItemTap: (item) => widget.onMenuItemTap?.call(item),
          )
              : null,
          appBar: AppDropAppBar(
            toolbarHeight: widget.appbarHeight,
            styling: cfg.appStyling,
            title: widget.title,
            showMenu: hasDrawer,
            showCart: true,
            onCartTap: widget.onCartTap,
          ),
          bottomNavigationBar: AppDropBottomNav(
            styling: cfg.appStyling,
            config: cfg.bottomBar,
            currentIndex: bottomIndex,
            onTap: (i) {
              setState(() => bottomIndex = i);
              if (i < bottomItems.length) widget.onBottomNavTap?.call(i, bottomItems[i]);
            },
          ),
          body: Column(
            children: [
              if (cfg.topNavigation.tabs.isNotEmpty)
                AppDropTopTabs(
                  styling: cfg.appStyling,
                  config: cfg.topNavigation,
                  selectedIndex: tabIndex,
                  onChanged: (i) {
                    setState(() => tabIndex = i);
                    widget.onTabChanged?.call(i, cfg.topNavigation.tabs[i]);
                  },
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: AppDropRenderer(
                    nodes: inlineNodes,
                    registry: registry,
                    onAction: onAction,
                  ),
                ),
              ),
              if (fixedBottomNodes.isNotEmpty)
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
