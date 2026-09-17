import '../models/page_toolbar_config.dart';

/// Maps a storefront route (+ optional dashboard page name) to the same catalog keys
/// used by the theme builder (`home-page`, `plp-page`, `pdp-page`, `cart-page`, `wishlist-page`, `search-page`).
String storeCatalogKeyForRoute(String route, {String? pageName}) {
  final n = pageName?.trim().toLowerCase();
  if (n != null && n.isNotEmpty) {
    switch (n) {
      case 'home':
        return 'home-page';
      case 'plp':
        return 'plp-page';
      case 'pdp':
        return 'pdp-page';
      case 'cart':
        return 'cart-page';
      case 'wishlist':
        return 'wishlist-page';
      case 'search':
        return 'search-page';
    }
  }

  var r = route.trim();
  if (r.isEmpty) return 'home-page';
  if (!r.startsWith('/')) r = '/$r';

  switch (r) {
    case '/':
    case '/home':
      return 'home-page';
    case '/collections':
    case '/products':
    case '/plp':
      return 'plp-page';
    case '/cart':
      return 'cart-page';
    case '/wishlist':
      return 'wishlist-page';
    case '/search':
      return 'search-page';
    default:
      if (r.startsWith('/products/') && r.length > '/products/'.length) {
        return 'pdp-page';
      }
      if (r.startsWith('/collections/')) {
        return 'plp-page';
      }
      return 'home-page';
  }
}

/// Merchant-created CMS pages (`/about`, `/demo`, …), not Home / PLP / Cart / etc.
///
/// Those pages show **Back** unless they were opened from the bottom bar,
/// where they keep **Side navigation**.
bool isMerchantCreatedPageRoute(String route) {
  var r = route.trim();
  if (r.isEmpty) return false;
  if (!r.startsWith('/')) r = '/$r';
  switch (r) {
    case '/':
    case '/home':
    case '/plp':
    case '/cart':
    case '/wishlist':
    case '/search':
    case '/collections':
    case '/products':
      return false;
    default:
      if (r.startsWith('/products/') && r.length > '/products/'.length) {
        return false;
      }
      if (r.startsWith('/collections/')) return false;
      return true;
  }
}

/// Runtime leading for a merchant-created page.
PageToolbarConfig toolbarLeadingForMerchantPage(
  PageToolbarConfig toolbar, {
  required bool fromBottomBar,
}) {
  return toolbar.copyWith(
    left: fromBottomBar ? ToolbarLeft.sideNavigation : ToolbarLeft.back,
  );
}

/// Reads the dashboard widget-level `visible` flag for `APP_TOOLBAR`.
///
/// Defaults to `true` when the widget is missing so storefronts keep showing
/// an app bar until a page explicitly disables it.
bool appToolbarVisibleFromApiWidgets(List<dynamic> widgets) {
  for (final e in widgets) {
    if (e is! Map) continue;
    final m = Map<String, dynamic>.from(e);
    final bt = (m['block_type'] ?? m['type'] ?? '').toString().toLowerCase();
    if (bt != 'app_toolbar') continue;
    return m['visible'] != false;
  }
  return true;
}

/// Resolves persisted toolbar with per–page-type defaults (aligned with the builder).
PageToolbarConfig effectiveStorefrontToolbar(
  String catalogKey,
  PageToolbarConfig? stored,
) {
  switch (catalogKey) {
    case 'pdp-page':
      final base = stored ?? PageToolbarConfig.pdpDefaults;
      return base.left == ToolbarLeft.back
          ? base
          : base.copyWith(left: ToolbarLeft.back);
    case 'cart-page':
      final base = stored ?? PageToolbarConfig.cartDefaults;
      return base.left == ToolbarLeft.back
          ? base
          : base.copyWith(left: ToolbarLeft.back);
    case 'wishlist-page':
      final base = stored ?? PageToolbarConfig.wishlistDefaults;
      return base.left == ToolbarLeft.back
          ? base
          : base.copyWith(left: ToolbarLeft.back);
    case 'search-page':
      final base = stored ?? PageToolbarConfig.searchDefaults;
      return base.left == ToolbarLeft.back
          ? base
          : base.copyWith(left: ToolbarLeft.back);
    case 'plp-page':
      if (stored != null) return stored;
      return PageToolbarConfig.plpDefaults;
    case 'home-page':
    default:
      if (stored != null) return stored;
      return PageToolbarConfig.homeDefaults;
  }
}
