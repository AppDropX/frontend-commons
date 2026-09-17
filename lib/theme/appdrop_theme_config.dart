import 'package:flutter/material.dart';
import '../models/page_toolbar_config.dart';
import '../utils/color.dart';

/// Tab / side-menu row can be a legacy [String] or a map with at least [title].
String labelFromThemeNavEntry(dynamic e) {
  if (e == null) return '';
  if (e is String) return e;
  if (e is Map) {
    final m = Map<String, dynamic>.from(e);
    final t = m['title'] ?? m['name'];
    if (t != null) return t.toString();
  }
  return e.toString();
}

class AppStylingConfig {
  final String fontFamily;

  /// Brand / default accent from theme settings (`default_color`).
  final Color defaultColor;

  /// Default body text & icons (theme + blocks that inherit).
  final Color fontIconColor;

  final Color toolbarBg;
  final Color toolbarFont;

  final Color bottomBg;
  final Color bottomSelected;
  final Color bottomUnselected;

  final String bottomStyle; // Underline
  final String bottomIconStyle; // With Labels

  final Color sideNavBg;
  final Color sideNavFontColor;

  /// App-wide screen background (`bg_color`).
  final Color bgColor;

  /// Block / card elevation color (`shadow_color`).
  final Color shadowColor;

  /// When false, block shadows are omitted (`shadow_visible`).
  final bool shadowVisible;

  const AppStylingConfig({
    required this.fontFamily,
    required this.defaultColor,
    required this.fontIconColor,
    required this.toolbarBg,
    required this.toolbarFont,
    required this.bottomBg,
    required this.bottomSelected,
    required this.bottomUnselected,
    required this.bottomStyle,
    required this.bottomIconStyle,
    required this.sideNavBg,
    required this.sideNavFontColor,
    required this.bgColor,
    required this.shadowColor,
    required this.shadowVisible,
  });

  factory AppStylingConfig.fromJson(Map<String, dynamic> json) {
    // Builder/API use `font_color` / `toolbar_font_color`; legacy JSON used
    // `font_icon_color` / `toolbar_font`.
    final fontIcon = parseHexColor(json['font_icon_color']?.toString()) ??
        parseHexColor(json['font_color']?.toString());
    final toolbarText = parseHexColor(json['toolbar_font']?.toString()) ??
        parseHexColor(json['toolbar_font_color']?.toString());

    return AppStylingConfig(
      fontFamily: (json['font_family'] ?? 'Poppins').toString(),
      defaultColor: parseHexColor(json['default_color']?.toString()) ??
          const Color(0xFF54A685),
      fontIconColor: fontIcon ?? const Color(0xFF111111),
      toolbarBg: parseHexColor(json['toolbar_bg']?.toString()) ??
          const Color(0xFFFFFA66),
      toolbarFont: toolbarText ?? const Color(0xFF111111),
      bottomBg: parseHexColor(json['bottom_bg']?.toString()) ?? Colors.white,
      bottomSelected: parseHexColor(json['bottom_selected']?.toString()) ??
          const Color(0xFFF76B0A),
      bottomUnselected: parseHexColor(json['bottom_unselected']?.toString()) ??
          const Color(0xFF9CA3AF),
      bottomStyle: (json['bottom_style'] ?? 'Underline').toString(),
      bottomIconStyle: (json['bottom_icon_style'] ?? 'With Labels').toString(),
      sideNavBg: parseHexColor(json['side_nav_bg']?.toString()) ??
          const Color(0xFF54A685),
      sideNavFontColor:
          parseHexColor(json['side_nav_font_color']?.toString()) ??
              const Color(0xFF6A4571),
      bgColor: parseHexColor(json['bg_color']?.toString()) ?? Colors.white,
      shadowColor: parseHexColor(json['shadow_color']?.toString()) ??
          const Color(0xFF3E4B2F),
      shadowVisible: json['shadow_visible'] is bool
          ? json['shadow_visible'] as bool
          : (json['shadow_visible']?.toString().toLowerCase() != 'false'),
    );
  }

  AppStylingConfig copyWith({
    String? fontFamily,
    Color? defaultColor,
    Color? fontIconColor,
    Color? toolbarBg,
    Color? toolbarFont,
    Color? bottomBg,
    Color? bottomSelected,
    Color? bottomUnselected,
    String? bottomStyle,
    String? bottomIconStyle,
    Color? sideNavBg,
    Color? sideNavFontColor,
    Color? bgColor,
    Color? shadowColor,
    bool? shadowVisible,
  }) {
    return AppStylingConfig(
      fontFamily: fontFamily ?? this.fontFamily,
      defaultColor: defaultColor ?? this.defaultColor,
      fontIconColor: fontIconColor ?? this.fontIconColor,
      toolbarBg: toolbarBg ?? this.toolbarBg,
      toolbarFont: toolbarFont ?? this.toolbarFont,
      bottomBg: bottomBg ?? this.bottomBg,
      bottomSelected: bottomSelected ?? this.bottomSelected,
      bottomUnselected: bottomUnselected ?? this.bottomUnselected,
      bottomStyle: bottomStyle ?? this.bottomStyle,
      bottomIconStyle: bottomIconStyle ?? this.bottomIconStyle,
      sideNavBg: sideNavBg ?? this.sideNavBg,
      sideNavFontColor: sideNavFontColor ?? this.sideNavFontColor,
      bgColor: bgColor ?? this.bgColor,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowVisible: shadowVisible ?? this.shadowVisible,
    );
  }

  /// Applies per-page toolbar / screen color overrides when set.
  AppStylingConfig withPageToolbarAppearance(PageToolbarConfig? tb) {
    if (tb == null) return this;
    return copyWith(
      toolbarBg: parseHexColor(tb.toolbarBg) ?? toolbarBg,
      toolbarFont: parseHexColor(tb.toolbarFont) ?? toolbarFont,
      bgColor: parseHexColor(tb.screenBg) ?? bgColor,
    );
  }
}

class BottomBarItemConfig {
  final String icon;
  final String title;
  final bool enabled;
  final String linkType;
  final String? linkValue;

  const BottomBarItemConfig({
    required this.icon,
    required this.title,
    required this.enabled,
    this.linkType = 'system',
    this.linkValue,
  });

  factory BottomBarItemConfig.fromJson(Map<String, dynamic> json) {
    return BottomBarItemConfig(
      icon: (json['icon'] ?? 'home').toString(),
      title: (json['title'] ?? '').toString(),
      enabled: (json['enabled'] ?? true) == true,
      linkType: (json['link_type'] ?? 'system').toString(),
      linkValue: json['link_value']?.toString(),
    );
  }
}

class BottomBarConfig {
  final bool enabled;
  final List<BottomBarItemConfig> items;

  const BottomBarConfig({required this.enabled, required this.items});

  factory BottomBarConfig.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] is List) ? (json['items'] as List) : const [];
    return BottomBarConfig(
      enabled: (json['enabled'] ?? true) == true,
      items: list
          .map(
              (e) => BottomBarItemConfig.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class SideMenuConfig {
  final List<SideMenuItemEntry> menuItems;
  final bool showDividers;
  final bool expandDropdowns;

  const SideMenuConfig({
    required this.menuItems,
    required this.showDividers,
    this.expandDropdowns = false,
  });

  factory SideMenuConfig.fromJson(Map<String, dynamic> json) {
    final items =
        (json['menu_items'] is List) ? (json['menu_items'] as List) : const [];
    final config = json['config'];
    final childrenByParent = _parseSideMenuChildren(config);
    return SideMenuConfig(
      menuItems: items
          .map((raw) {
            final entry = SideMenuItemEntry.fromJson(raw);
            final children = (childrenByParent[entry.id] ?? const [])
                .where((c) => c.enabled)
                .toList(growable: false);
            return children.isEmpty
                ? entry
                : SideMenuItemEntry(
                    id: entry.id,
                    title: entry.title,
                    enabled: entry.enabled,
                    linkType: entry.linkType,
                    linkValue: entry.linkValue,
                    urlOpenType: entry.urlOpenType,
                    children: children,
                  );
          })
          .where((e) => e.enabled)
          .toList(),
      showDividers: (json['show_dividers'] ?? true) == true,
      expandDropdowns: config is Map && config['expand_dropdowns'] == true,
    );
  }

  /// `config.children` is `{ parentId: [ child, ... ] }` — one nesting level.
  static Map<String, List<SideMenuItemEntry>> _parseSideMenuChildren(
    dynamic config,
  ) {
    if (config is! Map) return const {};
    final raw = config['children'];
    if (raw is! Map) return const {};
    final out = <String, List<SideMenuItemEntry>>{};
    for (final entry in raw.entries) {
      final list = entry.value;
      if (list is! List) continue;
      final children = list
          .map(SideMenuItemEntry.fromJson)
          .where((e) => e.enabled)
          .toList(growable: false);
      if (children.isNotEmpty) {
        out[entry.key.toString()] = children;
      }
    }
    return out;
  }
}

/// One side menu row with link metadata.
class SideMenuItemEntry {
  final String id;
  final String title;
  final bool enabled;
  final String linkType;
  final String? linkValue;
  final String? urlOpenType;

  /// One-level children from `side_menu.config.children[id]`. Never nested.
  final List<SideMenuItemEntry> children;

  const SideMenuItemEntry({
    this.id = '',
    required this.title,
    this.enabled = true,
    this.linkType = 'system',
    this.linkValue,
    this.urlOpenType,
    this.children = const [],
  });

  bool get hasChildren => children.isNotEmpty;

  factory SideMenuItemEntry.fromJson(dynamic e) {
    if (e == null) {
      return const SideMenuItemEntry(
        title: '',
        linkType: 'system',
        linkValue: 'home-page',
      );
    }
    if (e is String) {
      return SideMenuItemEntry(
        title: e,
        enabled: true,
        linkType: 'system',
        linkValue: 'home-page',
      );
    }
    if (e is Map) {
      final m = Map<String, dynamic>.from(e);
      return SideMenuItemEntry(
        id: (m['id'] ?? '').toString(),
        title: labelFromThemeNavEntry(m),
        enabled: m['enabled'] as bool? ?? true,
        linkType: (m['link_type'] ?? 'system').toString(),
        linkValue: m['link_value']?.toString(),
        urlOpenType: _normalizeUrlOpenType(m['url_open_type']),
      );
    }
    return SideMenuItemEntry(title: e.toString());
  }

  static String? _normalizeUrlOpenType(dynamic raw) {
    final v = raw?.toString().trim().toLowerCase();
    if (v == null || v.isEmpty || v == 'null') return null;
    if (v == 'internal' || v == 'external') return v;
    return null;
  }
}

/// One top navigation tab: label + link target (same shape as theme JSON entries).
class TopNavTabEntry {
  final String title;
  final bool enabled;
  final String linkType;
  final String? linkValue;

  /// API `url_open_type`: `internal` (webview) or `external` (browser).
  final String? urlOpenType;

  const TopNavTabEntry({
    required this.title,
    this.enabled = true,
    this.linkType = 'system',
    this.linkValue,
    this.urlOpenType,
  });

  factory TopNavTabEntry.fromJson(dynamic e) {
    if (e == null) {
      return const TopNavTabEntry(
        title: '',
        linkType: 'system',
        linkValue: 'home-page',
      );
    }
    if (e is String) {
      return TopNavTabEntry(
        title: e,
        enabled: true,
        linkType: 'system',
        linkValue: 'home-page',
      );
    }
    if (e is Map) {
      final m = Map<String, dynamic>.from(e);
      return TopNavTabEntry(
        title: labelFromThemeNavEntry(m),
        enabled: m['enabled'] as bool? ?? true,
        linkType: (m['link_type'] ?? 'system').toString(),
        linkValue: m['link_value']?.toString(),
        urlOpenType: _normalizeUrlOpenType(m['url_open_type']),
      );
    }
    return TopNavTabEntry(title: e.toString());
  }

  static String? _normalizeUrlOpenType(dynamic raw) {
    final v = raw?.toString().trim().toLowerCase();
    if (v == null || v.isEmpty || v == 'null') return null;
    if (v == 'internal' || v == 'external') return v;
    return null;
  }
}

class TopNavigationConfig {
  final bool enabled;

  /// Full tab rows from theme JSON (title, link_type, link_value).
  final List<TopNavTabEntry> items;

  const TopNavigationConfig({
    this.enabled = true,
    required this.items,
  });

  /// Tab labels for the horizontal bar.
  List<String> get tabs => items.map((e) => e.title).toList();

  factory TopNavigationConfig.fromJson(Map<String, dynamic> json) {
    final list = (json['tabs'] is List) ? (json['tabs'] as List) : const [];
    return TopNavigationConfig(
      enabled: json['enabled'] is bool ? json['enabled'] as bool : true,
      items: list.map(TopNavTabEntry.fromJson).where((e) => e.enabled).toList(),
    );
  }
}

class AppDropThemeConfig {
  final AppStylingConfig appStyling;
  final BottomBarConfig bottomBar;
  final SideMenuConfig sideMenu;
  final TopNavigationConfig topNavigation;

  /// product_block settings (global defaults)
  final Map<String, dynamic> productBlock;

  const AppDropThemeConfig({
    required this.appStyling,
    required this.bottomBar,
    required this.sideMenu,
    required this.topNavigation,
    required this.productBlock,
  });

  factory AppDropThemeConfig.fromJson(Map<String, dynamic> json) {
    return AppDropThemeConfig(
      appStyling: AppStylingConfig.fromJson(
          Map<String, dynamic>.from(json['app_styling'] ?? {})),
      bottomBar: BottomBarConfig.fromJson(
          Map<String, dynamic>.from(json['bottom_bar'] ?? {})),
      sideMenu: SideMenuConfig.fromJson(
          Map<String, dynamic>.from(json['side_menu'] ?? {})),
      topNavigation: TopNavigationConfig.fromJson(
          Map<String, dynamic>.from(json['top_navigation'] ?? {})),
      productBlock: Map<String, dynamic>.from(json['product_block'] ?? {}),
    );
  }

  AppDropThemeConfig copyWith({
    AppStylingConfig? appStyling,
    BottomBarConfig? bottomBar,
    SideMenuConfig? sideMenu,
    TopNavigationConfig? topNavigation,
    Map<String, dynamic>? productBlock,
  }) {
    return AppDropThemeConfig(
      appStyling: appStyling ?? this.appStyling,
      bottomBar: bottomBar ?? this.bottomBar,
      sideMenu: sideMenu ?? this.sideMenu,
      topNavigation: topNavigation ?? this.topNavigation,
      productBlock: productBlock ?? this.productBlock,
    );
  }

  AppDropThemeConfig withPageToolbarAppearance(PageToolbarConfig? tb) {
    return copyWith(appStyling: appStyling.withPageToolbarAppearance(tb));
  }
}
