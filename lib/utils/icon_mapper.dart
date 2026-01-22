import 'package:flutter/material.dart';

IconData iconFromName(String name) {
  switch (name) {
    case 'home':
      return Icons.home_outlined;
    case 'grid_view':
      return Icons.grid_view;
    case 'favorite_border':
      return Icons.favorite_border;
    case 'shopping_cart_outlined':
      return Icons.shopping_cart_outlined;
    case 'person_outline':
      return Icons.person_outline;
    case 'menu':
      return Icons.menu;
    default:
      return Icons.circle_outlined;
  }
}
