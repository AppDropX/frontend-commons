import 'dart:async';

import 'package:flutter/widgets.dart';

import 'network_image_url.dart';

/// Resolves the width/height aspect ratio of a network image, or null on failure.
Future<double?> resolveNetworkImageAspectRatio(String rawUrl) async {
  final url = sanitizedNetworkImageUrl(rawUrl);
  if (url == null) return null;

  final provider = NetworkImage(url);
  final completer = Completer<double?>();
  late ImageStream stream;
  late ImageStreamListener listener;

  listener = ImageStreamListener(
    (ImageInfo info, bool _) {
      final w = info.image.width;
      final h = info.image.height;
      if (!completer.isCompleted) {
        completer.complete(h > 0 ? w / h : null);
      }
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
