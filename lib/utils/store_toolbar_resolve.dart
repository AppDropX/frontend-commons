import '../models/page_toolbar_config.dart';

/// Maps a storefront route (+ optional dashboard page name) to the same catalog keys
/// used by the theme builder (`home-page`, `plp-page`, `pdp-page`, `cart-page`).
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
    case 'plp-page':
      if (stored != null) return stored;
      return PageToolbarConfig.plpDefaults;
    case 'home-page':
    default:
      if (stored != null) return stored;
      return PageToolbarConfig.homeDefaults;
  }
}
