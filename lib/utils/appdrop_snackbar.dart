import 'package:flutter/material.dart';

/// Max width for the centered floating snack bar on wide layouts.
const double kAppDropSnackBarMaxWidth = 360;

/// Minimum width on very narrow viewports.
const double kAppDropSnackBarMinWidth = 200;

const double _kScreenHorizontalGutter = 32;

/// Visual category for [showAppDropSnackBar].
enum AppDropSnackKind {
  /// Saved / created / added — green
  success,

  /// Failures and validation — red
  error,

  /// Completed removal (delete, revoke) — deep red
  removed,

  /// Limits and cautions — amber
  warning,

  /// Neutral information — blue
  info,

  /// Generic toast — charcoal
  neutral,
}

class _SnackStyle {
  const _SnackStyle({
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color foreground;
  final IconData icon;
}

_SnackStyle _styleForKind(AppDropSnackKind kind, ColorScheme cs) {
  switch (kind) {
    case AppDropSnackKind.success:
      return const _SnackStyle(
        background: Color(0xFF166534),
        foreground: Color(0xFFF0FDF4),
        icon: Icons.check_circle_rounded,
      );
    case AppDropSnackKind.error:
      return _SnackStyle(
        background: cs.error,
        foreground: cs.onError,
        icon: Icons.error_rounded,
      );
    case AppDropSnackKind.removed:
      return const _SnackStyle(
        background: Color(0xFF991B1B),
        foreground: Color(0xFFFEF2F2),
        icon: Icons.delete_forever_rounded,
      );
    case AppDropSnackKind.warning:
      return const _SnackStyle(
        background: Color(0xFFB45309),
        foreground: Color(0xFFFFFBEB),
        icon: Icons.warning_rounded,
      );
    case AppDropSnackKind.info:
      return const _SnackStyle(
        background: Color(0xFF1D4ED8),
        foreground: Color(0xFFEFF6FF),
        icon: Icons.info_rounded,
      );
    case AppDropSnackKind.neutral:
      return const _SnackStyle(
        background: Color(0xFF1F2937),
        foreground: Color(0xFFF9FAFB),
        icon: Icons.notifications_rounded,
      );
  }
}

/// Compact, centered-at-bottom snack bar shared across AppDrop apps.
///
/// Pass [kind] for color semantics. If [isError] is true, [kind] is ignored
/// and [AppDropSnackKind.error] is used.
void showAppDropSnackBar(
  BuildContext context,
  String message, {
  AppDropSnackKind kind = AppDropSnackKind.neutral,
  bool isError = false,
  Duration duration = const Duration(seconds: 3),
  bool clearExisting = true,
  Color? backgroundColor,
  Color? foregroundColor,
  IconData? icon,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  if (clearExisting) {
    messenger.clearSnackBars();
  }

  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final screenW = MediaQuery.sizeOf(context).width;
  final targetInner = (screenW - _kScreenHorizontalGutter)
      .clamp(kAppDropSnackBarMinWidth, kAppDropSnackBarMaxWidth)
      .toDouble();
  var sideMargin = (screenW - targetInner) / 2;
  const minSide = 8.0;
  if (sideMargin < minSide) {
    sideMargin = minSide;
  }

  final resolved = isError ? AppDropSnackKind.error : kind;
  final s = _styleForKind(resolved, colorScheme);
  final bg = backgroundColor ?? s.background;
  final fg = foregroundColor ?? s.foreground;
  final snackIcon = icon ?? s.icon;

  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(sideMargin, 0, sideMargin, 20),
      duration: duration,
      elevation: 10,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      backgroundColor: bg,
      // Unique key per SnackBar so Material's internal Hero tags never collide
      // when replacing snack bars or during route transitions (see heroes.dart).
      content: KeyedSubtree(
        key: UniqueKey(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(snackIcon, color: fg, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: fg,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
