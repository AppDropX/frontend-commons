import 'package:flutter/widgets.dart';
import 'appdrop_theme_config.dart';

class AppDropThemeScope extends InheritedWidget {
  final AppDropThemeConfig config;

  const AppDropThemeScope({
    super.key,
    required this.config,
    required Widget child,
  }) : super(child: child);

  static AppDropThemeConfig? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppDropThemeScope>()?.config;
  }

  static AppDropThemeConfig of(BuildContext context) {
    final cfg = maybeOf(context);
    assert(cfg != null, 'AppDropThemeScope not found. Wrap with AppDropThemeScope.');
    return cfg!;
  }

  @override
  bool updateShouldNotify(AppDropThemeScope oldWidget) => oldWidget.config != config;
}
