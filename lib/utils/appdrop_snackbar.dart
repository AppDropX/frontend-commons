import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import '../theme/appdrop_theme_scope.dart';
import 'color.dart';

/// Max width for the centered floating snack bar on wide layouts.
const double kAppDropSnackBarMaxWidth = 360;

/// Wider cap when showing long error payloads (still viewport-safe).
const double kAppDropSnackBarErrorMaxWidth = 480;

/// Minimum width on very narrow viewports.
const double kAppDropSnackBarMinWidth = 200;

/// Default message lines for compact toasts; errors use [kAppDropSnackBarErrorMaxLines].
const int kAppDropSnackBarDefaultMaxLines = 2;

/// Enough lines to show a full API error body without horizontal overflow.
const int kAppDropSnackBarErrorMaxLines = 12;

const Duration _kCompactSnackDuration = Duration(milliseconds: 1800);

/// When true, [showAppDropSnackBar] anchors the pill near the top of the scaffold.
class AppDropSnackBarScope extends InheritedWidget {
  const AppDropSnackBarScope({
    super.key,
    this.alignTop = false,
    this.prominent = false,
    required super.child,
  });

  final bool alignTop;
  final bool prominent;

  static bool alignTopOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<AppDropSnackBarScope>()
            ?.alignTop ??
        false;
  }

  static bool prominentOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<AppDropSnackBarScope>()
            ?.prominent ??
        false;
  }

  @override
  bool updateShouldNotify(AppDropSnackBarScope oldWidget) =>
      alignTop != oldWidget.alignTop || prominent != oldWidget.prominent;
}

EdgeInsets _snackBarMargin(
  BuildContext context, {
  required bool alignTop,
  bool prominent = false,
}) {
  const horizontal = 16.0;
  const gap = 12.0;

  if (!alignTop) {
    return const EdgeInsets.fromLTRB(horizontal, 0, horizontal, gap);
  }

  final media = MediaQuery.of(context);
  final topInset = media.padding.top;
  final estimatedSnackHeight = prominent ? 54.0 : 44.0;

  // Floating snack bars sit in the band above [bottomNavigationBar]. Top alignment
  // uses a large bottom margin — it must be relative to that band, not the full
  // screen, or the pill renders off-screen in the iPhone preview (330×690).
  final scaffold = Scaffold.maybeOf(context);
  final appBarHeight = scaffold?.appBarMaxHeight ?? 0.0;
  final topChrome = appBarHeight > 0 ? appBarHeight : math.max(topInset + 44, 52);
  final bottomChrome = media.padding.bottom + kBottomNavigationBarHeight;

  final snackBandHeight = math.max(
    estimatedSnackHeight + gap * 2,
    media.size.height - topChrome - bottomChrome,
  );

  final bottomMargin = (snackBandHeight - estimatedSnackHeight - gap).clamp(
    gap,
    snackBandHeight - estimatedSnackHeight,
  );

  return EdgeInsets.fromLTRB(horizontal, 0, horizontal, bottomMargin);
}

/// Visual category for [showAppDropSnackBar].
enum AppDropSnackKind {
  success,
  error,
  removed,
  warning,
  info,
  neutral,
}

class _SnackAccent {
  const _SnackAccent({required this.accent, required this.icon});

  final Color accent;
  final IconData icon;
}

_SnackAccent _accentForKind(AppDropSnackKind kind, ColorScheme cs) {
  switch (kind) {
    case AppDropSnackKind.success:
      return const _SnackAccent(
        accent: Color(0xFF16A34A),
        icon: FluentIcons.checkmark_circle_20_regular,
      );
    case AppDropSnackKind.error:
      return _SnackAccent(accent: cs.error, icon: FluentIcons.error_circle_20_regular);
    case AppDropSnackKind.removed:
      return const _SnackAccent(
        accent: Color(0xFFDC2626),
        icon: FluentIcons.delete_20_regular,
      );
    case AppDropSnackKind.warning:
      return const _SnackAccent(
        accent: Color(0xFFD97706),
        icon: FluentIcons.warning_20_regular,
      );
    case AppDropSnackKind.info:
      return const _SnackAccent(
        accent: Color(0xFF2563EB),
        icon: FluentIcons.info_20_regular,
      );
    case AppDropSnackKind.neutral:
      return const _SnackAccent(
        accent: Color(0xFF374151),
        icon: FluentIcons.alert_20_regular,
      );
  }
}

DateTime? _lastWishlistHapticAt;
bool? _cachedHasVibrator;
bool? _cachedHasAmplitudeControl;

/// Pre-warm vibrator capability checks so the first wishlist tap feels instant.
void warmUpWishlistHaptic() {
  if (kIsWeb) return;
  unawaited(_ensureWishlistVibratorCache());
}

/// Device vibration + haptic when a product is saved to wishlist.
void triggerWishlistAddHaptic() {
  if (kIsWeb) return;

  final now = DateTime.now();
  if (_lastWishlistHapticAt != null &&
      now.difference(_lastWishlistHapticAt!) <
          const Duration(milliseconds: 400)) {
    return;
  }
  _lastWishlistHapticAt = now;

  try {
    HapticFeedback.heavyImpact();
  } catch (_) {}

  unawaited(_pulseWishlistVibration());
}

Future<void> _ensureWishlistVibratorCache() async {
  if (_cachedHasVibrator != null) return;
  try {
    _cachedHasVibrator = await Vibration.hasVibrator();
    if (_cachedHasVibrator == true) {
      _cachedHasAmplitudeControl = await Vibration.hasAmplitudeControl();
    }
  } catch (_) {
    _cachedHasVibrator = false;
  }
}

Future<void> _pulseWishlistVibration() async {
  try {
    await _ensureWishlistVibratorCache();
    if (_cachedHasVibrator != true) return;

    const durationMs = 90;
    if (_cachedHasAmplitudeControl == true) {
      await Vibration.vibrate(duration: durationMs, amplitude: 200);
    } else {
      await Vibration.vibrate(duration: durationMs);
    }
  } catch (_) {}
}

Color _wishlistAccentForSnack(BuildContext context, Color? override) {
  if (override != null) return override;
  final cfg = AppDropThemeScope.maybeOf(context);
  if (cfg != null) {
    final wishlist = parseHexColor(
      cfg.productBlock['product_wishlist_color']?.toString(),
    );
    if (wishlist != null) return wishlist;
    final defaultColor = cfg.appStyling.defaultColor;
    if (defaultColor != Colors.transparent) return defaultColor;
  }
  return const Color(0xFFE53935);
}

OverlayEntry? _activeCompactSnackEntry;
Timer? _activeCompactSnackTimer;

void _removeActiveCompactSnack() {
  _activeCompactSnackTimer?.cancel();
  _activeCompactSnackTimer = null;
  _activeCompactSnackEntry?.remove();
  _activeCompactSnackEntry = null;
}

/// Bottom chrome below body content (home indicator + optional bottom nav).
double _overlayBottomChrome(BuildContext context) {
  final padding = MediaQuery.paddingOf(context).bottom;
  final scaffold = Scaffold.maybeOf(context);
  final hasBottomNav = scaffold?.widget.bottomNavigationBar != null;
  return padding + (hasBottomNav ? kBottomNavigationBarHeight : 0);
}

/// Presents the compact pill via [Overlay] — not Material [SnackBar].
///
/// StatefulShellRoute keeps multiple branch [Scaffold]s registered under one
/// [ScaffoldMessenger]; Material snack bars mount on each and share the same
/// SnackBar Hero tag, which asserts on route transitions (e.g. View cart).
///
/// When [messenger] is passed explicitly (builder phone preview / admin host),
/// fall back to Material [SnackBar] so the pill stays in that messenger's
/// scaffold instead of the root app [Overlay].
void _presentCompactSnackBar(
  BuildContext context, {
  required String message,
  required Color accent,
  required IconData icon,
  Duration duration = _kCompactSnackDuration,
  bool clearExisting = true,
  EdgeInsets? margin,
  bool alignTop = false,
  bool prominent = false,
  String? actionLabel,
  VoidCallback? onAction,
  ScaffoldMessengerState? messenger,
  int messageMaxLines = kAppDropSnackBarDefaultMaxLines,
  double? maxWidth,
}) {
  if (messenger != null) {
    _presentMaterialCompactSnackBar(
      messenger,
      message: message,
      accent: accent,
      icon: icon,
      duration: duration,
      clearExisting: clearExisting,
      margin: margin,
      alignTop: alignTop,
      prominent: prominent,
      actionLabel: actionLabel,
      onAction: onAction,
      messageMaxLines: messageMaxLines,
      maxWidth: maxWidth,
    );
    return;
  }

  if (clearExisting) {
    ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
    _removeActiveCompactSnack();
  }

  final overlay = Overlay.maybeOf(context);
  if (overlay == null || !context.mounted) return;

  final resolvedMargin = margin ?? const EdgeInsets.fromLTRB(16, 0, 16, 12);
  final topPad =
      alignTop ? MediaQuery.paddingOf(context).top + 12 : 0.0;
  final bottomPad = alignTop
      ? 0.0
      : resolvedMargin.bottom + _overlayBottomChrome(context);

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (overlayContext) {
      VoidCallback? resolvedAction;
      if (onAction != null) {
        resolvedAction = () {
          _removeActiveCompactSnack();
          onAction();
        };
      }

      // Positioned.fill is required — Overlay stack children otherwise
      // shrink-wrap, so Align.bottomCenter can't reach the screen bottom.
      return Positioned.fill(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            resolvedMargin.left,
            topPad,
            resolvedMargin.right,
            bottomPad,
          ),
          child: Align(
            alignment:
                alignTop ? Alignment.topCenter : Alignment.bottomCenter,
            child: Material(
              color: Colors.transparent,
              child: _CompactSnackBody(
                message: message,
                accent: accent,
                icon: icon,
                prominent: prominent,
                actionLabel: actionLabel,
                onAction: resolvedAction,
                messageMaxLines: messageMaxLines,
                maxWidth: maxWidth,
              ),
            ),
          ),
        ),
      );
    },
  );

  _activeCompactSnackEntry = entry;
  overlay.insert(entry);
  _activeCompactSnackTimer = Timer(duration, _removeActiveCompactSnack);
}

void _presentMaterialCompactSnackBar(
  ScaffoldMessengerState messenger, {
  required String message,
  required Color accent,
  required IconData icon,
  Duration duration = _kCompactSnackDuration,
  bool clearExisting = true,
  EdgeInsets? margin,
  bool alignTop = false,
  bool prominent = false,
  String? actionLabel,
  VoidCallback? onAction,
  int messageMaxLines = kAppDropSnackBarDefaultMaxLines,
  double? maxWidth,
}) {
  if (clearExisting) {
    messenger.clearSnackBars();
  }

  VoidCallback? resolvedAction;
  if (onAction != null) {
    resolvedAction = () {
      // Immediate remove — hide() leaves Heroes in-tree during route transitions.
      messenger.removeCurrentSnackBar();
      onAction();
    };
  }

  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: margin ?? const EdgeInsets.fromLTRB(16, 0, 16, 12),
      duration: duration,
      elevation: 0,
      padding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      dismissDirection:
          alignTop ? DismissDirection.up : DismissDirection.down,
      content: Center(
        child: _CompactSnackBody(
          message: message,
          accent: accent,
          icon: icon,
          prominent: prominent,
          actionLabel: actionLabel,
          onAction: resolvedAction,
          messageMaxLines: messageMaxLines,
          maxWidth: maxWidth,
        ),
      ),
    ),
  );
}

/// Compact centered pill snack bar shared across AppDrop apps.
void showAppDropSnackBar(
  BuildContext context,
  String message, {
  AppDropSnackKind kind = AppDropSnackKind.neutral,
  bool isError = false,
  Duration duration = _kCompactSnackDuration,
  bool clearExisting = true,
  Color? backgroundColor,
  Color? foregroundColor,
  IconData? icon,
  ScaffoldMessengerState? messenger,
  bool? alignTop,
  bool? prominent,
  String? actionLabel,
  VoidCallback? onAction,
  int? messageMaxLines,
}) {
  if (!context.mounted) return;

  final resolved = isError ? AppDropSnackKind.error : kind;
  final style = _accentForKind(resolved, Theme.of(context).colorScheme);
  final accent = backgroundColor ?? style.accent;
  final snackIcon = icon ?? style.icon;
  final resolvedAlignTop = alignTop ?? AppDropSnackBarScope.alignTopOf(context);
  final resolvedProminent =
      prominent ?? AppDropSnackBarScope.prominentOf(context);
  final resolvedMessageMaxLines = messageMaxLines ??
      (isError ? kAppDropSnackBarErrorMaxLines : kAppDropSnackBarDefaultMaxLines);
  final viewportWidth = MediaQuery.sizeOf(context).width;
  final resolvedMaxWidth = isError
      ? math
          .min(kAppDropSnackBarErrorMaxWidth, viewportWidth - 32)
          .clamp(kAppDropSnackBarMinWidth, kAppDropSnackBarErrorMaxWidth)
      : math
          .min(kAppDropSnackBarMaxWidth, viewportWidth - 32)
          .clamp(kAppDropSnackBarMinWidth, kAppDropSnackBarMaxWidth);
  final resolvedDuration = actionLabel != null && onAction != null
      ? const Duration(milliseconds: 4500)
      : (isError
          ? const Duration(milliseconds: 6000)
          : (resolvedProminent && duration == _kCompactSnackDuration
              ? const Duration(milliseconds: 2600)
              : duration));

  _presentCompactSnackBar(
    context,
    message: message,
    accent: accent,
    icon: snackIcon,
    duration: resolvedDuration,
    clearExisting: clearExisting,
    margin: _snackBarMargin(
      context,
      alignTop: resolvedAlignTop,
      prominent: resolvedProminent,
    ),
    alignTop: resolvedAlignTop,
    prominent: resolvedProminent,
    actionLabel: actionLabel,
    onAction: onAction,
    messenger: messenger,
    messageMaxLines: resolvedMessageMaxLines,
    maxWidth: resolvedMaxWidth,
  );
}

/// After add-to-cart: pill toast with optional navigation to the cart screen.
void showAppDropAddedToCartSnack(
  BuildContext context, {
  required VoidCallback onViewCart,
  String message = 'Added to cart',
  String actionLabel = 'View cart',
  Color? accentColor,
  ScaffoldMessengerState? messenger,
}) {
  showAppDropSnackBar(
    context,
    message,
    kind: AppDropSnackKind.success,
    backgroundColor: accentColor ?? const Color(0xFFFF6A00),
    icon: FluentIcons.cart_20_regular,
    messenger: messenger,
    duration: const Duration(milliseconds: 4500),
    actionLabel: actionLabel,
    onAction: onViewCart,
  );
}

/// Compact toast when a product is saved to wishlist (add only).
void showAppDropWishlistAddedSnack(
  BuildContext context, {
  String message = 'Added to wishlist',
  Color? accentColor,
  Duration duration = _kCompactSnackDuration,
  ScaffoldMessengerState? messenger,
}) {
  if (!context.mounted) return;

  triggerWishlistAddHaptic();

  final accent = _wishlistAccentForSnack(context, accentColor);
  final alignTop = AppDropSnackBarScope.alignTopOf(context);
  final prominent = AppDropSnackBarScope.prominentOf(context);
  final resolvedDuration = prominent && duration == _kCompactSnackDuration
      ? const Duration(milliseconds: 2600)
      : duration;
  _presentCompactSnackBar(
    context,
    message: message,
    accent: accent,
    icon: FluentIcons.heart_20_filled,
    duration: resolvedDuration,
    clearExisting: true,
    margin: _snackBarMargin(context, alignTop: alignTop, prominent: prominent),
    alignTop: alignTop,
    prominent: prominent,
    messenger: messenger,
  );
}

class _CompactSnackBody extends StatelessWidget {
  const _CompactSnackBody({
    required this.message,
    required this.accent,
    required this.icon,
    this.prominent = false,
    this.actionLabel,
    this.onAction,
    this.messageMaxLines = kAppDropSnackBarDefaultMaxLines,
    this.maxWidth,
  });

  final String message;
  final Color accent;
  final IconData icon;
  final bool prominent;
  final String? actionLabel;
  final VoidCallback? onAction;
  final int messageMaxLines;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(prominent ? 12 : 10);
    final iconSize = prominent ? 18.0 : 15.0;
    final iconBox = prominent ? 32.0 : 26.0;
    final accentFill = prominent ? 0.22 : 0.12;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final resolvedMaxWidth = maxWidth ??
        math
            .min(kAppDropSnackBarMaxWidth, viewportWidth - 32)
            .clamp(kAppDropSnackBarMinWidth, kAppDropSnackBarMaxWidth);

    // Shrink-wrap to the pill. A plain Align.center expands to the parent and
    // vertically centers the toast when shown in a full-screen Overlay.
    return Align(
      alignment: Alignment.center,
      widthFactor: 1,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: resolvedMaxWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: prominent ? const Color(0xFFFAFAFA) : Colors.white,
            borderRadius: borderRadius,
            border: Border.all(
              color: prominent
                  ? accent.withValues(alpha: 0.35)
                  : const Color(0xFFE5E7EB),
              width: prominent ? 1.4 : 1,
            ),
            boxShadow: prominent
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: -2,
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (prominent) ColoredBox(color: accent, child: const SizedBox(width: 4)),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: prominent ? 14 : 10,
                        vertical: prominent ? 11 : 7,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: iconBox,
                            height: iconBox,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: accentFill),
                              shape: BoxShape.circle,
                              border: prominent
                                  ? Border.all(
                                      color: accent.withValues(alpha: 0.28),
                                    )
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Icon(icon, color: accent, size: iconSize),
                          ),
                          SizedBox(width: prominent ? 10 : 8),
                          Expanded(
                            child: Text(
                              message,
                              style: TextStyle(
                                color: const Color(0xFF0F172A),
                                fontSize: prominent ? 14 : 13,
                                fontWeight: prominent
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                height: 1.25,
                                letterSpacing: prominent ? 0.1 : 0,
                              ),
                              maxLines: messageMaxLines,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (actionLabel != null && onAction != null) ...[
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: onAction,
                              style: TextButton.styleFrom(
                                foregroundColor: accent,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              child: Text(
                                actionLabel!,
                                style: TextStyle(
                                  color: accent,
                                  fontSize: prominent ? 14 : 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
