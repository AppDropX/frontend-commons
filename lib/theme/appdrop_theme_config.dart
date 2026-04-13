import 'package:flutter/material.dart';
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
  /// Default body text & icons (theme + blocks that inherit).
  final Color fontIconColor;

  final Color toolbarBg;
  final Color toolbarFont;

  final Color bottomBg;
  final Color bottomSelected;
  final Color bottomUnselected;

  final String bottomStyle;     // Underline
  final String bottomIconStyle; // With Labels

  final Color sideNavBg;
  final Color sideNavFontColor;

  const AppStylingConfig({
    required this.fontFamily,
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
      fontIconColor: fontIcon ?? const Color(0xFF111111),
      toolbarBg: parseHexColor(json['toolbar_bg']?.toString()) ?? const Color(0xFFFFFA66),
      toolbarFont: toolbarText ?? const Color(0xFF111111),
      bottomBg: parseHexColor(json['bottom_bg']?.toString()) ?? Colors.white,
      bottomSelected: parseHexColor(json['bottom_selected']?.toString()) ?? const Color(0xFFF76B0A),
      bottomUnselected: parseHexColor(json['bottom_unselected']?.toString()) ?? const Color(0xFF9CA3AF),
      bottomStyle: (json['bottom_style'] ?? 'Underline').toString(),
      bottomIconStyle: (json['bottom_icon_style'] ?? 'With Labels').toString(),
      sideNavBg: parseHexColor(json['side_nav_bg']?.toString()) ?? const Color(0xFF54A685),
      sideNavFontColor: parseHexColor(json['side_nav_font_color']?.toString()) ?? const Color(0xFF6A4571),
    );
  }
}

class BottomBarItemConfig {
  final String icon;
  final String title;
  final bool enabled;

  const BottomBarItemConfig({required this.icon, required this.title, required this.enabled});

  factory BottomBarItemConfig.fromJson(Map<String, dynamic> json) {
    return BottomBarItemConfig(
      icon: (json['icon'] ?? 'home').toString(),
      title: (json['title'] ?? '').toString(),
      enabled: (json['enabled'] ?? true) == true,
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
      items: list.map((e) => BottomBarItemConfig.fromJson(Map<String, dynamic>.from(e))).toList(),
    );
  }
}

class SideMenuConfig {
  final List<String> menuItems;
  final bool showDividers;

  const SideMenuConfig({required this.menuItems, required this.showDividers});

  factory SideMenuConfig.fromJson(Map<String, dynamic> json) {
    final items = (json['menu_items'] is List) ? (json['menu_items'] as List) : const [];
    return SideMenuConfig(
      menuItems: items.map(labelFromThemeNavEntry).toList(),
      showDividers: (json['show_dividers'] ?? true) == true,
    );
  }
}

/// One top navigation tab: label + link target (same shape as theme JSON entries).
class TopNavTabEntry {
  final String title;
  final String linkType;
  final String? linkValue;

  const TopNavTabEntry({
    required this.title,
    this.linkType = 'system',
    this.linkValue,
  });

  factory TopNavTabEntry.fromJson(dynamic e) {
    if (e == null) {
      return const TopNavTabEntry(title: '', linkType: 'system', linkValue: 'home-page');
    }
    if (e is String) {
      return TopNavTabEntry(
        title: e,
        linkType: 'system',
        linkValue: 'home-page',
      );
    }
    if (e is Map) {
      final m = Map<String, dynamic>.from(e);
      return TopNavTabEntry(
        title: labelFromThemeNavEntry(m),
        linkType: (m['link_type'] ?? 'system').toString(),
        linkValue: m['link_value']?.toString(),
      );
    }
    return TopNavTabEntry(title: e.toString());
  }
}

class TopNavigationConfig {
  /// Full tab rows from theme JSON (title, link_type, link_value).
  final List<TopNavTabEntry> items;

  const TopNavigationConfig({required this.items});

  /// Tab labels for the horizontal bar.
  List<String> get tabs => items.map((e) => e.title).toList();

  factory TopNavigationConfig.fromJson(Map<String, dynamic> json) {
    final list = (json['tabs'] is List) ? (json['tabs'] as List) : const [];
    return TopNavigationConfig(
      items: list.map(TopNavTabEntry.fromJson).toList(),
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
      appStyling: AppStylingConfig.fromJson(Map<String, dynamic>.from(json['app_styling'] ?? {})),
      bottomBar: BottomBarConfig.fromJson(Map<String, dynamic>.from(json['bottom_bar'] ?? {})),
      sideMenu: SideMenuConfig.fromJson(Map<String, dynamic>.from(json['side_menu'] ?? {})),
      topNavigation: TopNavigationConfig.fromJson(Map<String, dynamic>.from(json['top_navigation'] ?? {})),
      productBlock: Map<String, dynamic>.from(json['product_block'] ?? {}),
    );
  }
}
