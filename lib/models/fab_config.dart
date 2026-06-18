import 'package:flutter/material.dart';

import '../utils/color.dart';

class FabRedirect {
  const FabRedirect({
    required this.linkType,
    required this.linkValue,
    this.urlOpenType,
  });

  final String linkType;
  final String linkValue;
  final String? urlOpenType;

  factory FabRedirect.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const FabRedirect(linkType: 'system', linkValue: 'home');
    }
    return FabRedirect(
      linkType: json['link_type']?.toString() ?? 'system',
      linkValue: json['link_value']?.toString() ?? '',
      urlOpenType: json['url_open_type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'link_type': linkType,
        'link_value': linkValue,
        'url_open_type': linkType == 'url' ? urlOpenType : null,
      };
}

class FabConfig {
  const FabConfig({
    required this.enabled,
    this.shape = 'rounded',
    this.contentStyle = 'icon',
    this.icon = 'shopping_cart',
    this.imageUrl,
    this.backgroundColor = '#FF6B00',
    this.iconColor = '#FFFFFF',
    required this.redirect,
    this.visibility = const ['all'],
    this.updatedAt,
  });

  final bool enabled;
  final String shape;
  final String contentStyle;
  final String icon;
  final String? imageUrl;
  final String backgroundColor;
  final String iconColor;
  final FabRedirect redirect;
  final List<String> visibility;
  final String? updatedAt;

  Color get backgroundColorValue =>
      parseHexColor(backgroundColor) ?? const Color(0xFFFF6B00);

  Color get iconColorValue =>
      parseHexColor(iconColor) ?? Colors.white;

  BorderRadius get borderRadius {
    switch (shape) {
      case 'circle':
        return BorderRadius.circular(999);
      case 'square':
        return BorderRadius.zero;
      default:
        return BorderRadius.circular(14);
    }
  }

  factory FabConfig.fromJson(Map<String, dynamic> json) {
    final visibilityRaw = json['visibility'];
    final visibility = visibilityRaw is List
        ? visibilityRaw.map((e) => e.toString()).toList()
        : const <String>['all'];

    return FabConfig(
      enabled: json['enabled'] == true,
      shape: json['shape']?.toString() ?? 'rounded',
      contentStyle: json['content_style']?.toString() ?? 'icon',
      icon: json['icon']?.toString() ?? 'shopping_cart',
      imageUrl: json['image_url']?.toString(),
      backgroundColor: json['background_color']?.toString() ?? '#FF6B00',
      iconColor: json['icon_color']?.toString() ?? '#FFFFFF',
      redirect: FabRedirect.fromJson(
        json['redirect'] is Map
            ? Map<String, dynamic>.from(json['redirect'] as Map)
            : null,
      ),
      visibility: visibility,
      updatedAt: json['updated_at']?.toString() ?? json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'shape': shape,
        'content_style': contentStyle,
        'icon': contentStyle == 'icon' ? icon : '',
        'image_url': contentStyle == 'image' ? imageUrl : null,
        'background_color': backgroundColor,
        'icon_color': iconColor,
        'redirect': redirect.toJson(),
        'visibility': visibility,
      };

  static FabConfig get defaults => const FabConfig(
        enabled: false,
        redirect: FabRedirect(linkType: 'system', linkValue: 'cart'),
        visibility: ['all'],
      );

  static FabConfig? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    try {
      final root = Map<String, dynamic>.from(raw);
      final normalized = _extractPayload(root);
      return FabConfig.fromJson(normalized);
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _extractPayload(Map<String, dynamic> root) {
    if (root.containsKey('enabled') ||
        root.containsKey('shape') ||
        root.containsKey('content_style')) {
      return root;
    }

    final data = root['data'];
    if (data is Map) {
      final m = Map<String, dynamic>.from(data);
      if (m.containsKey('enabled') ||
          m.containsKey('shape') ||
          m.containsKey('content_style')) {
        return m;
      }
      final nested = m['fab'];
      if (nested is Map) return Map<String, dynamic>.from(nested);
    }

    final nested = root['fab'];
    if (nested is Map) return Map<String, dynamic>.from(nested);

    return root;
  }

  /// Whether the FAB should show on a storefront [routePath] (e.g. `/`, `/plp`).
  bool isVisibleOnRoute(String routePath) {
    if (!enabled) return false;
    if (visibility.contains('all')) return true;

    final key = _visibilityKeyForRoute(routePath);
    if (key == null) return false;
    return visibility.contains(key);
  }

  static String? _visibilityKeyForRoute(String routePath) {
    final path = routePath.trim().isEmpty ? '/' : routePath.trim();
    if (path == '/' || path == '/home') return 'home';
    if (path.startsWith('/plp')) return 'plp';
    if (path.startsWith('/cart')) return 'cart';
    if (path.startsWith('/product/') || path.startsWith('/products/')) {
      return 'pdp';
    }
    if (path.contains('account')) return 'account';
    return null;
  }
}
