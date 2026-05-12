import 'package:flutter/painting.dart';

/// Soft elevation applied to storefront media / card blocks where border radius
/// should match shadow shape (distinct from rectangular page-level wrappers).
const List<BoxShadow> kAppDropComponentShadows = [
  BoxShadow(
    color: Color(0x24000000),
    blurRadius: 12,
    offset: Offset(0, 4),
    spreadRadius: 0,
  ),
];
