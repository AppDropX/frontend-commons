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
    case 'arrow_back':
    case 'back':
      return Icons.arrow_back_ios_new;
    default:
      return selected ? Icons.circle : Icons.circle_outlined;
  }
}

/// Material icon for in-app FAB `icon` field (snake_case API values).
IconData fabIconFromName(String name) {
  switch (name.trim().toLowerCase()) {
    case 'shopping_cart':
      return Icons.shopping_cart_outlined;
    case 'delete':
    case 'delete_outline':
      return Icons.delete_outline_rounded;
    case 'chat':
    case 'chat_bubble':
    case 'chat_bubble_outline':
      return Icons.chat_bubble_outline_rounded;
    case 'favorite':
    case 'favorite_border':
    case 'heart':
      return Icons.favorite_border_rounded;
    case 'support':
    case 'support_agent':
      return Icons.support_agent_outlined;
    case 'local_offer':
    case 'offer':
      return Icons.local_offer_outlined;
    case 'card_giftcard':
    case 'gift':
      return Icons.card_giftcard_outlined;
    case 'help':
    case 'help_outline':
      return Icons.help_outline_rounded;
    case 'link':
      return Icons.link;
    default:
      return Icons.shopping_cart_outlined;
  }
}

/// API snake_case name for a FAB picker [IconData].
String fabIconToName(IconData icon) {
  if (icon == Icons.delete_outline_rounded) return 'delete_outline';
  if (icon == Icons.shopping_cart_outlined) return 'shopping_cart';
  if (icon == Icons.chat_bubble_outline_rounded) return 'chat_bubble_outline';
  if (icon == Icons.favorite_border_rounded) return 'favorite_border';
  if (icon == Icons.support_agent_outlined) return 'support_agent';
  if (icon == Icons.local_offer_outlined) return 'local_offer';
  if (icon == Icons.card_giftcard_outlined) return 'card_giftcard';
  if (icon == Icons.help_outline_rounded) return 'help_outline';
  if (icon == Icons.link) return 'link';
  return 'shopping_cart';
}
