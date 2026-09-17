/// Decode-size quantization step, in device pixels.
///
/// Coarse buckets let a 2-column and a 3-column grid tile, plus the intermediate
/// sizes a [Hero] passes through mid-flight, share one `imageCache` entry instead
/// of forcing a fresh decode per pixel width.
const int _kDecodeWidthStepPx = 64;

/// Target decode width in device pixels for an image painted into [maxWidth]
/// logical pixels, or `null` when the box is unbounded.
///
/// Feed the result to `Image.network(cacheWidth:)`. Decoding at display size is
/// what keeps a 2048 px product original from occupying ~16 MB of RGBA to paint
/// a 150 dp card. `ResizeImage` does not upscale, so an already-small thumbnail
/// is unaffected.
int? decodeWidthForBox(double maxWidth, double devicePixelRatio) {
  if (!maxWidth.isFinite || maxWidth <= 0) return null;
  final px = maxWidth * devicePixelRatio;
  if (!px.isFinite || px <= 0) return null;
  return (px / _kDecodeWidthStepPx).ceil() * _kDecodeWidthStepPx;
}
