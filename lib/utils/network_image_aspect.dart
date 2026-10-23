import 'dart:async';

import 'package:flutter/widgets.dart';

import 'network_image_url.dart';

final Map<String, double> _aspectCache = {};

/// Aspect already measured for [rawUrl], if a previous resolve finished.
double? cachedNetworkImageAspectRatio(String rawUrl) {
  final url = sanitizedNetworkImageUrl(rawUrl);
  if (url == null) return null;
  return _aspectCache[url];
}

/// Resolves the width/height aspect ratio of a network image, or null on failure.
Future<double?> resolveNetworkImageAspectRatio(String rawUrl) async {
  final url = sanitizedNetworkImageUrl(rawUrl);
  if (url == null) return null;
  final cached = _aspectCache[url];
  if (cached != null) return cached;

  final provider = NetworkImage(url);
  final completer = Completer<double?>();
  late ImageStream stream;
  late ImageStreamListener listener;

  listener = ImageStreamListener(
    (ImageInfo info, bool _) {
      final w = info.image.width;
      final h = info.image.height;
      final aspect = h > 0 ? w / h : null;
      if (aspect != null && aspect > 0) _aspectCache[url] = aspect;
      if (!completer.isCompleted) completer.complete(aspect);
      stream.removeListener(listener);
    },
    onError: (Object _, StackTrace? __) {
      if (!completer.isCompleted) completer.complete(null);
      stream.removeListener(listener);
    },
  );

  stream = provider.resolve(const ImageConfiguration());
  stream.addListener(listener);

  try {
    return await completer.future.timeout(const Duration(seconds: 15));
  } on TimeoutException {
    stream.removeListener(listener);
    return null;
  }
}
