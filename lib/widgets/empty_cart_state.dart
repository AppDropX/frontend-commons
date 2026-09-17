import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import '../theme_library.dart';
import '../utils/color.dart';

/// Empty cart / wishlist placeholder with premium e-commerce styling.
///
/// Builder-managed props: [message], [subtitle], [ctaTitle], [ctaStyle]
/// (`filled` | `outlined`), [action], [iconSizeDp], [iconColor], [textColor].
/// Legacy [ctaStyle] `soft` is treated as filled so older pages pick up the
/// theme CTA without a republish.
Widget buildEmptyCartState(BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final r = env.r;
  final message = node.s('message', def: 'Cart is empty');
  final emptyVariant = node.s('emptyStateVariant', def: 'cart').toLowerCase();
  final isWishlist = emptyVariant == 'wishlist';
  final iconDp = node.d('iconSizeDp', def: 32).clamp(28, 48);
  final iconHex = node.s('iconColor', def: '');
  final iconColor = iconHex.isNotEmpty
      ? (parseHexColor(iconHex) ?? Colors.grey.shade400)
      : null;
  final textHex = node.s('textColor', def: '');
  final scope = AppDropThemeScope.maybeOf(context);
  final fallbackText = scope?.appStyling.fontIconColor ?? const Color(0xFF111827);
  final textColor =
      textHex.isNotEmpty ? (parseHexColor(textHex) ?? fallbackText) : fallbackText;
  final subtitle = node.s('subtitle', def: '');
  final ctaTitle = node.s('ctaTitle', def: '');
  final action = node.m('action');
  final ctaStyle = node.s('ctaStyle', def: 'filled').toLowerCase();
  final isOutlinedCta = ctaStyle == 'outlined';

  final accent = resolveAppDropPrimaryColor(context);
  final onAccent = resolveAppDropOnPrimaryColor(accent);
  final fontFamily = scope?.appStyling.fontFamily ?? 'Poppins';
  final defaultSubtitle = isWishlist
      ? 'Save products you love and shop them anytime.'
      : 'Discover something you love and add it to your bag.';
  final resolvedSubtitle = subtitle.isNotEmpty ? subtitle : defaultSubtitle;
  final resolvedCta = ctaTitle.isNotEmpty
      ? ctaTitle
      : (isWishlist ? 'Browse products' : 'Start shopping');
  final resolvedAction = _resolvedEmptyStateAction(action);
  final headline = message.isEmpty
      ? (isWishlist ? 'Your wishlist is empty' : 'Your cart is empty')
      : message;

  final pb = scope?.productBlock ?? const <String, dynamic>{};
  final Color fillBg;
  final Color fillFont;
  final Color? outline;
  if (isOutlinedCta) {
    fillBg = (scope?.appStyling.bgColor ?? Colors.white).withValues(alpha: 0);
    fillFont = accent;
    outline = accent;
  } else {
    fillBg = parseHexColor(pb['filled_button_bg']?.toString()) ?? accent;
    fillFont = parseHexColor(pb['filled_button_color']?.toString()) ?? onAccent;
    outline = null;
  }

  final titleStyle = AppDropThemeData.textStyle(
    fontFamily: fontFamily,
    fontSize: r.sp(22, min: 20, max: 24),
    fontWeight: FontWeight.w600,
    color: textColor,
  ).copyWith(height: 1.25, letterSpacing: -0.4);

  final subtitleStyle = AppDropThemeData.textStyle(
    fontFamily: fontFamily,
    fontSize: r.sp(14, min: 13, max: 15),
    fontWeight: FontWeight.w400,
    color: textColor.withValues(alpha: 0.55),
  ).copyWith(height: 1.5);

  final ctaStyleText = AppDropThemeData.textStyle(
    fontFamily: fontFamily,
    fontSize: r.sp(15, min: 14, max: 16),
    fontWeight: FontWeight.w600,
    color: fillFont,
  ).copyWith(letterSpacing: 0.2);

  return LayoutBuilder(
    builder: (context, constraints) {
      final mq = MediaQuery.of(context);
      final available = constraints.maxHeight.isFinite
          ? constraints.maxHeight
          : mq.size.height - mq.padding.vertical - kToolbarHeight - 120;
      final minH = available.clamp(280.0, 560.0);
      final disc = r.dp(iconDp + 36);
      final halo = disc + r.dp(28);
      final radius = r.dp(12);

      return SizedBox(
        width: double.infinity,
        height: minH,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: r.dp(32)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: halo,
                height: halo,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accent.withValues(alpha: 0.14),
                          width: 1,
                        ),
                      ),
                      child: const SizedBox.expand(),
                    ),
                    Container(
                      width: disc,
                      height: disc,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.28),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        isWishlist
                            ? FluentIcons.heart_24_regular
                            : FluentIcons.shopping_bag_24_regular,
                        size: r.dp(iconDp),
                        color: iconColor ?? onAccent,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: r.dp(28)),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: r.dp(280)),
                child: Column(
                  children: [
                    Text(
                      headline,
                      textAlign: TextAlign.center,
                      style: titleStyle,
                    ),
                    SizedBox(height: r.dp(10)),
                    Text(
                      resolvedSubtitle,
                      textAlign: TextAlign.center,
                      style: subtitleStyle,
                    ),
                  ],
                ),
              ),
              SizedBox(height: r.dp(32)),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: r.dp(360)),
                child: SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isOutlinedCta ? Colors.transparent : fillBg,
                      borderRadius: BorderRadius.circular(radius),
                      border: outline != null
                          ? Border.all(color: outline, width: 1.5)
                          : null,
                      boxShadow: isOutlinedCta
                          ? const []
                          : [
                              BoxShadow(
                                color: fillBg.withValues(alpha: 0.28),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(radius),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(radius),
                        onTap: () => env.dispatchAction(context, resolvedAction),
                        child: Semantics(
                          button: true,
                          label: resolvedCta,
                          child: Container(
                            constraints: BoxConstraints(minHeight: r.dp(52)),
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(
                              horizontal: r.dp(20),
                              vertical: r.dp(14),
                            ),
                            child: Text(
                              resolvedCta,
                              style: ctaStyleText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Map<String, dynamic> _resolvedEmptyStateAction(Map<String, dynamic>? action) {
  const home = {'type': 'open_page', 'pageId': 'home-page'};
  if (action == null || action.isEmpty) return Map<String, dynamic>.from(home);

  final type = action['type']?.toString().trim() ?? '';
  if (type == 'open_collection') {
    final collection =
        action['collection']?.toString().trim().toLowerCase() ?? '';
    if (collection.isEmpty || collection == 'all') {
      return Map<String, dynamic>.from(home);
    }
  }
  if (type.isEmpty) return Map<String, dynamic>.from(home);
  return Map<String, dynamic>.from(action);
}
