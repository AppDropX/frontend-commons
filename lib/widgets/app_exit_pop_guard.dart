import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/appdrop_theme_config.dart';
import 'app_exit_confirm_dialog.dart';

/// Intercepts the system back button when the current route is the last one.
///
/// Pushed screens still pop normally ([ModalRoute.canPop] is true). On the
/// last route, [onGoToRoot] runs unless [isAtAppRoot] is true, in which case
/// an exit confirmation is shown.
class AppExitPopGuard extends StatefulWidget {
  const AppExitPopGuard({
    super.key,
    required this.child,
    required this.isAtAppRoot,
    required this.onGoToRoot,
    this.themeConfig,
  });

  final Widget child;
  final bool isAtAppRoot;
  final VoidCallback onGoToRoot;
  final AppDropThemeConfig? themeConfig;

  @override
  State<AppExitPopGuard> createState() => _AppExitPopGuardState();
}

class _AppExitPopGuardState extends State<AppExitPopGuard> {
  var _busy = false;

  Future<void> _onPopAttempt() async {
    if (_busy) return;
    if (!widget.isAtAppRoot) {
      widget.onGoToRoot();
      return;
    }
    _busy = true;
    try {
      final shouldExit = await showAppExitConfirmDialog(
        context,
        themeConfig: widget.themeConfig,
      );
      if (shouldExit && context.mounted) {
        await SystemNavigator.pop();
      }
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeCanPop = ModalRoute.of(context)?.canPop ?? false;
    return PopScope(
      canPop: routeCanPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onPopAttempt();
      },
      child: widget.child,
    );
  }
}
