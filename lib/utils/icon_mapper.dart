import 'package:flutter/material.dart';

IconData iconFromName(String name) {
  return iconFromNameForNav(name, false);
}

/// Returns icon for bottom nav: filled when [selected], outlined when not.
IconData iconFromNameForNav(String name, bool selected) {
  switch (name) {
    case 'home':
      return selected ? Icons.home : Icons.home_outlined;
    case 'grid_view':
    case 'collections':
      return selected ? Icons.shopping_bag : Icons.shopping_bag_outlined;
    case 'favorite_border':
      return Icons.favorite_border;
    case 'shopping_cart_outlined':
    case 'cart':
      return selected ? Icons.shopping_cart : Icons.shopping_cart_outlined;
    case 'person_outline':
    case 'account':
      return selected ? Icons.person : Icons.person_outline;
    case 'menu':
      return Icons.menu;
    default:
      return selected ? Icons.circle : Icons.circle_outlined;
  }
}
