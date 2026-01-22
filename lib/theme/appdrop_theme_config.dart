import 'package:flutter/material.dart';
import '../utils/color.dart';

class AppStylingConfig {
  final String fontFamily;

  final Color toolbarBg;
  final Color toolbarFont;

  final Color bottomBg;
  final Color bottomSelected;
  final Color bottomUnselected;

  final String bottomStyle;     // Underline
  final String bottomIconStyle; // With Labels

  const AppStylingConfig({
    required this.fontFamily,
    required this.toolbarBg,
    required this.toolbarFont,
    required this.bottomBg,
    required this.bottomSelected,
    required this.bottomUnselected,
    required this.bottomStyle,
    required this.bottomIconStyle,
  });

  factory AppStylingConfig.fromJson(Map<String, dynamic> json) {
    return AppStylingConfig(
      fontFamily: (json['font_family'] ?? 'Poppins').toString(),
      toolbarBg: parseHexColor(json['toolbar_bg']?.toString()) ?? const Color(0xFFFFFA66),
      toolbarFont: parseHexColor(json['toolbar_font']?.toString()) ?? const Color(0xFF111111),
      bottomBg: parseHexColor(json['bottom_bg']?.toString()) ?? Colors.white,
      bottomSelected: parseHexColor(json['bottom_selected']?.toString()) ?? const Color(0xFFF76B0A),
      bottomUnselected: parseHexColor(json['bottom_unselected']?.toString()) ?? const Color(0xFF9CA3AF),
      bottomStyle: (json['bottom_style'] ?? 'Underline').toString(),
      bottomIconStyle: (json['bottom_icon_style'] ?? 'With Labels').toString(),
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
      menuItems: items.map((e) => e.toString()).toList(),
      showDividers: (json['show_dividers'] ?? true) == true,
    );
  }
}

class TopNavigationConfig {
  final List<String> tabs;
  const TopNavigationConfig({required this.tabs});

  factory TopNavigationConfig.fromJson(Map<String, dynamic> json) {
    final list = (json['tabs'] is List) ? (json['tabs'] as List) : const [];
    return TopNavigationConfig(tabs: list.map((e) => e.toString()).toList());
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
