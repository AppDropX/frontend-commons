import 'package:flutter/material.dart';
import '../theme/appdrop_theme_config.dart';
import '../utils/icon_mapper.dart';

class AppDropBottomNav extends StatelessWidget {
  final AppStylingConfig styling;
  final BottomBarConfig config;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int? cartBadgeCount;

  const AppDropBottomNav({
    super.key,
    required this.styling,
    required this.config,
    required this.currentIndex,
    required this.onTap,
    this.cartBadgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final items = config.items.where((e) => e.enabled).toList();
    if (!config.enabled || items.isEmpty) return const SizedBox.shrink();

    final withLabels = styling.bottomIconStyle.toLowerCase().contains('label');
    final underline = styling.bottomStyle.toLowerCase() == 'underline';

    return Container(
      decoration: BoxDecoration(
        color: styling.bottomBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      //padding: const EdgeInsets.only(top: 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(items.length, (i) {
            final item = items[i];
            final selected = i == currentIndex;
            final color =
                selected ? styling.bottomSelected : styling.bottomUnselected;
            final showCartBadge =
                _isCartItem(item) && (cartBadgeCount ?? 0) > 0;

            return Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onTap(i),
                  splashColor: color.withValues(alpha: 0.12),
                  highlightColor: color.withValues(alpha: 0.08),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (underline)
                          Container(
                            height: 3,
                            width: 32,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(3)),
                              color: selected
                                  ? styling.bottomSelected
                                  : Colors.transparent,
                            ),
                          ),
                        SizedBox(height: 10),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              iconFromNameForNav(item.icon, selected),
                              color: color,
                              size: 24,
                            ),
                            if (showCartBadge)
                              Positioned(
                                right: -8,
                                top: -8,
                                child: _CartBadge(count: cartBadgeCount!),
                              ),
                          ],
                        ),
                        if (withLabels) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

bool _isCartItem(BottomBarItemConfig item) {
  final type = item.linkType.trim().toLowerCase();
  final value =
      (item.linkValue ?? '').trim().toLowerCase().replaceAll('_', '-');
  if (type == 'system' && (value == 'cart-page' || value == 'cart')) {
    return true;
  }
  return item.title.trim().toLowerCase() == 'cart';
}

class _CartBadge extends StatelessWidget {
  const _CartBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: const BoxDecoration(
        color: Color(0xFFE53935),
        shape: BoxShape.circle,
      ),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
