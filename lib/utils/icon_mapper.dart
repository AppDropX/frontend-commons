import 'package:flutter/material.dart';

IconData iconFromName(String name) {
  return iconFromNameForNav(name, false);
}

/// Returns icon for bottom nav: filled when [selected], outlined when not.
IconData iconFromNameForNav(String name, bool selected) {
  switch (name) {
    case 'home':
    case 'home_outlined':
      return selected ? Icons.home : Icons.home_outlined;
    case 'grid_view':
    case 'collections':
      return selected ? Icons.grid_view : Icons.grid_view_outlined;
    case 'favorite_border':
    case 'heart':
      return Icons.favorite_border;
    case 'shopping_cart_outlined':
    case 'cart':
      return selected ? Icons.shopping_cart : Icons.shopping_cart_outlined;
    case 'person_outline':
    case 'account':
    case 'user':
      return selected ? Icons.person : Icons.person_outline;
    case 'search':
      return Icons.search;
    case 'bell':
    case 'notifications_none':
      return selected ? Icons.notifications : Icons.notifications_none;
    case 'bag':
    case 'shopping_bag_outlined':
      return selected ? Icons.shopping_bag : Icons.shopping_bag_outlined;
    case 'star':
    case 'star_border':
      return selected ? Icons.star : Icons.star_border;
    case 'menu':
      return Icons.menu;
    default:
      return selected ? Icons.circle : Icons.circle_outlined;
  }
}
