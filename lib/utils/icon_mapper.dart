import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

IconData iconFromName(String name) {
  return iconFromNameForNav(name, false);
}

/// Returns icon for bottom nav: filled when [selected], regular when not.
IconData iconFromNameForNav(String name, bool selected) {
  switch (name) {
    case 'home':
    case 'home_outlined':
      return selected ? FluentIcons.home_20_filled : FluentIcons.home_20_regular;
    case 'grid_view':
    case 'collections':
      return selected ? FluentIcons.grid_20_filled : FluentIcons.grid_20_regular;
    case 'favorite_border':
    case 'heart':
      return selected ? FluentIcons.heart_20_filled : FluentIcons.heart_20_regular;
    case 'shopping_cart_outlined':
    case 'cart':
      return selected ? FluentIcons.cart_20_filled : FluentIcons.cart_20_regular;
    case 'person_outline':
    case 'account':
    case 'user':
      return selected ? FluentIcons.person_20_filled : FluentIcons.person_20_regular;
    case 'search':
      return FluentIcons.search_20_regular;
    case 'bell':
    case 'notifications_none':
      return selected ? FluentIcons.alert_20_filled : FluentIcons.alert_20_regular;
    case 'bag':
    case 'shopping_bag_outlined':
      return selected
          ? FluentIcons.shopping_bag_20_filled
          : FluentIcons.shopping_bag_20_regular;
    case 'star':
    case 'star_border':
      return selected ? FluentIcons.star_20_filled : FluentIcons.star_20_regular;
    case 'menu':
      return FluentIcons.navigation_20_regular;
    case 'arrow_back':
    case 'back':
      return FluentIcons.chevron_left_20_regular;
    default:
      return selected ? FluentIcons.circle_20_filled : FluentIcons.circle_20_regular;
  }
}

/// Fluent icon for in-app FAB `icon` field (snake_case API values).
IconData fabIconFromName(String name) {
  switch (name.trim().toLowerCase()) {
    case 'shopping_cart':
      return FluentIcons.cart_20_regular;
    case 'delete':
    case 'delete_outline':
      return FluentIcons.delete_20_regular;
    case 'chat':
    case 'chat_bubble':
    case 'chat_bubble_outline':
      return FluentIcons.chat_20_regular;
    case 'favorite':
    case 'favorite_border':
    case 'heart':
      return FluentIcons.heart_20_regular;
    case 'support':
    case 'support_agent':
      return FluentIcons.headset_20_regular;
    case 'local_offer':
    case 'offer':
      return FluentIcons.tag_20_regular;
    case 'card_giftcard':
    case 'gift':
      return FluentIcons.gift_20_regular;
    case 'help':
    case 'help_outline':
      return FluentIcons.question_circle_20_regular;
    case 'link':
      return FluentIcons.link_20_regular;
    default:
      return FluentIcons.cart_20_regular;
  }
}

/// API snake_case name for a FAB picker [IconData].
String fabIconToName(IconData icon) {
  if (icon == FluentIcons.delete_20_regular) return 'delete_outline';
  if (icon == FluentIcons.cart_20_regular) return 'shopping_cart';
  if (icon == FluentIcons.chat_20_regular) return 'chat_bubble_outline';
  if (icon == FluentIcons.heart_20_regular) return 'favorite_border';
  if (icon == FluentIcons.headset_20_regular) return 'support_agent';
  if (icon == FluentIcons.tag_20_regular) return 'local_offer';
  if (icon == FluentIcons.gift_20_regular) return 'card_giftcard';
  if (icon == FluentIcons.question_circle_20_regular) return 'help_outline';
  if (icon == FluentIcons.link_20_regular) return 'link';
  return 'shopping_cart';
}
