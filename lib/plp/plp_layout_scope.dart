import 'package:flutter/widgets.dart';

/// Shopper grid/list choice for the PLP under a Sort & Filter bar.
///
/// The merchant toggle ([viewToggleEnabled]) comes from the `sort_filter` block.
/// [mode] is session state: it is not written back to the theme.
class PlpLayoutController extends ChangeNotifier {
  bool viewToggleEnabled = false;
  String mode = 'grid';

  bool get isList => viewToggleEnabled && mode == 'list';

  void syncEnabled(bool enabled) {
    if (viewToggleEnabled == enabled) return;
    viewToggleEnabled = enabled;
    if (!enabled) mode = 'grid';
    notifyListeners();
  }

  void setMode(String next) {
    final normalized = next == 'list' ? 'list' : 'grid';
    if (!viewToggleEnabled || mode == normalized) return;
    mode = normalized;
    notifyListeners();
  }
}

/// Shares one [PlpLayoutController] between the sort bar and the product list.
class PlpLayoutScope extends InheritedNotifier<PlpLayoutController> {
  const PlpLayoutScope({
    super.key,
    required PlpLayoutController controller,
    required super.child,
  }) : super(notifier: controller);

  static PlpLayoutController? watch(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<PlpLayoutScope>()
        ?.notifier;
  }

  static PlpLayoutController? read(BuildContext context) {
    return context.getInheritedWidgetOfExactType<PlpLayoutScope>()?.notifier;
  }
}

/// Owns the controller for one page render.
class PlpLayoutHost extends StatefulWidget {
  const PlpLayoutHost({super.key, required this.child});

  final Widget child;

  @override
  State<PlpLayoutHost> createState() => _PlpLayoutHostState();
}

class _PlpLayoutHostState extends State<PlpLayoutHost> {
  final PlpLayoutController _controller = PlpLayoutController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlpLayoutScope(controller: _controller, child: widget.child);
  }
}
