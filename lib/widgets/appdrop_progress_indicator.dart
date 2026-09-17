import 'package:flutter/cupertino.dart';

import 'variant_choice_chips.dart';

/// Theme-colored [CupertinoActivityIndicator] using app `default_color`.
class AppDropProgressIndicator extends StatelessWidget {
  const AppDropProgressIndicator({
    super.key,
    this.radius = 14,
  });

  final double radius;

  @override
  Widget build(BuildContext context) {
    return CupertinoActivityIndicator(
      radius: radius,
      color: resolveAppDropPrimaryColor(context),
    );
  }
}

/// Centers [AppDropProgressIndicator] for full-page / overlay loads.
class AppDropProgressCenter extends StatelessWidget {
  const AppDropProgressCenter({super.key, this.radius = 14});

  final double radius;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppDropProgressIndicator(radius: radius),
    );
  }
}
