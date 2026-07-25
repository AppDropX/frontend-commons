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

/// Minimum width on very narrow viewports.
const double kAppDropSnackBarMinWidth = 200;

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

void _presentCompactSnackBar(
  ScaffoldMessengerState messenger, {
  required String message,
  required Color accent,
  required IconData icon,
  Duration duration = _kCompactSnackDuration,
  bool clearExisting = true,
  EdgeInsets? margin,
  bool alignTop = false,
  bool prominent = false,
}) {
  if (clearExisting) {
    messenger.clearSnackBars();
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
      content: KeyedSubtree(
        key: UniqueKey(),
        child: _CompactSnackBody(
          message: message,
          accent: accent,
          icon: icon,
          prominent: prominent,
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
}) {
  final resolvedMessenger = messenger ?? ScaffoldMessenger.maybeOf(context);
  if (resolvedMessenger == null) return;

  final resolved = isError ? AppDropSnackKind.error : kind;
  final style = _accentForKind(resolved, Theme.of(context).colorScheme);
  final accent = backgroundColor ?? style.accent;
  final snackIcon = icon ?? style.icon;
  final resolvedAlignTop = alignTop ?? AppDropSnackBarScope.alignTopOf(context);
  final resolvedProminent =
      prominent ?? AppDropSnackBarScope.prominentOf(context);
  final resolvedDuration = resolvedProminent && duration == _kCompactSnackDuration
      ? const Duration(milliseconds: 2600)
      : duration;

  _presentCompactSnackBar(
    resolvedMessenger,
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
  final resolvedMessenger =
      messenger ?? ScaffoldMessenger.maybeOf(context);
  if (resolvedMessenger == null) return;

  triggerWishlistAddHaptic();

  final accent = _wishlistAccentForSnack(context, accentColor);
  final alignTop = AppDropSnackBarScope.alignTopOf(context);
  final prominent = AppDropSnackBarScope.prominentOf(context);
  final resolvedDuration = prominent && duration == _kCompactSnackDuration
      ? const Duration(milliseconds: 2600)
      : duration;
  _presentCompactSnackBar(
    resolvedMessenger,
    message: message,
    accent: accent,
    icon: FluentIcons.heart_20_filled,
    duration: resolvedDuration,
    clearExisting: true,
    margin: _snackBarMargin(context, alignTop: alignTop, prominent: prominent),
    alignTop: alignTop,
    prominent: prominent,
  );
}

class _CompactSnackBody extends StatelessWidget {
  const _CompactSnackBody({
    required this.message,
    required this.accent,
    required this.icon,
    this.prominent = false,
  });

  final String message;
  final Color accent;
  final IconData icon;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(prominent ? 12 : 10);
    final iconSize = prominent ? 18.0 : 15.0;
    final iconBox = prominent ? 32.0 : 26.0;
    final accentFill = prominent ? 0.22 : 0.12;

    return Align(
      alignment: Alignment.center,
      child: IntrinsicWidth(
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (prominent)
                  Container(width: 4, height: 52, color: accent),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: prominent ? 14 : 10,
                    vertical: prominent ? 11 : 7,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
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
                      Text(
                        message,
                        style: TextStyle(
                          color: const Color(0xFF0F172A),
                          fontSize: prominent ? 14 : 13,
                          fontWeight:
                              prominent ? FontWeight.w700 : FontWeight.w600,
                          height: 1.25,
                          letterSpacing: prominent ? 0.1 : 0,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
