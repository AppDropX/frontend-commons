/// Layout mode for custom HTML blocks — controls slot CSS and fit behaviour.
enum CustomBlockLayoutMode {
  embedded,
  fullScreen,
  popup,
}

/// Builds the HTML document for an embedded/custom HTML block.
///
/// Shared by builder editor preview, theme preview, [pilot], and
/// [appdrop_preview] so layout/CSS behaviour matches everywhere.
class CustomBlockHtmlDocument {
  CustomBlockHtmlDocument._();

  static CustomBlockLayoutMode layoutModeFromDisplayMode(String mode) {
    final normalized = mode.toLowerCase().trim().replaceAll(' ', '_');
    switch (normalized) {
      case 'full_screen':
      case 'fullscreen':
        return CustomBlockLayoutMode.fullScreen;
      case 'popup':
        return CustomBlockLayoutMode.popup;
      default:
        return CustomBlockLayoutMode.embedded;
    }
  }

  /// Slot CSS for the Flutter WebView / iframe viewport.
  static String slotStyles({required CustomBlockLayoutMode layoutMode}) {
    if (layoutMode == CustomBlockLayoutMode.fullScreen) {
      return '''
<style id="appdrop-custom-block-slot">
  html, body {
    margin: 0 !important;
    padding: 0 !important;
    width: 100% !important;
    min-height: 100% !important;
    box-sizing: border-box !important;
    overflow-x: hidden !important;
    overflow-y: auto !important;
    -webkit-overflow-scrolling: touch;
  }
  * { box-sizing: border-box; }
  body {
    display: block !important;
  }
  body > *:first-child {
    width: 100% !important;
    max-width: 100% !important;
    box-sizing: border-box !important;
  }
</style>
''';
    }

    final scaleToFit = layoutMode != CustomBlockLayoutMode.fullScreen;
    final overflowY = scaleToFit ? 'hidden' : 'auto';
    return '''
<style id="appdrop-custom-block-slot">
  html, body {
    margin: 0 !important;
    padding: 0 !important;
    width: 100% !important;
    height: 100% !important;
    min-height: 100% !important;
    max-height: 100% !important;
    box-sizing: border-box !important;
    overflow-x: hidden !important;
    overflow-y: $overflowY !important;
    -webkit-overflow-scrolling: touch;
  }
  * { box-sizing: border-box; }
  body {
    display: block !important;
  }
  #appdrop-fit-root {
    width: 100% !important;
    min-height: 100% !important;
    box-sizing: border-box !important;
    transform-origin: top center;
  }
  body > #appdrop-fit-root,
  body > *:first-child {
    width: 100% !important;
    max-width: 100% !important;
    min-height: 100% !important;
    margin: 0 !important;
    box-sizing: border-box !important;
  }
  #appdrop-fit-root > * {
    width: 100% !important;
    max-width: 100% !important;
    min-height: 100% !important;
    margin: 0 !important;
    box-sizing: border-box !important;
    display: flex !important;
    flex-direction: column !important;
    align-items: center !important;
    justify-content: center !important;
  }
  body > *:last-child {
    margin-bottom: 0 !important;
  }
</style>
''';
  }

  /// Scales content down to fit the Flutter slot height. Uses top-center
  /// origin so the UI stays horizontally centered (no left-pinned look).
  static String fitScript() {
    return r'''
<script id="appdrop-custom-block-fit">
(function () {
  if (window.__appdropFitInstalled) return;
  window.__appdropFitInstalled = true;

  function ensureRoot() {
    var existing = document.getElementById('appdrop-fit-root');
    if (existing) return existing;

    var root = document.createElement('div');
    root.id = 'appdrop-fit-root';

    var nodes = [];
    for (var i = 0; i < document.body.childNodes.length; i++) {
      nodes.push(document.body.childNodes[i]);
    }
    for (var j = 0; j < nodes.length; j++) {
      var node = nodes[j];
      if (node.nodeType === 1 && node.id === 'appdrop-custom-block-fit') continue;
      if (node.nodeType === 1 && node.id === 'appdrop-custom-block-user-js') continue;
      root.appendChild(node);
    }
    document.body.insertBefore(root, document.body.firstChild);
    return root;
  }

  function fit() {
    var root = ensureRoot();
    if (!root) return;

    root.style.transform = 'none';
    root.style.width = '100%';
    root.style.marginLeft = '0';
    root.style.transformOrigin = 'top center';

    var availH = window.innerHeight || document.documentElement.clientHeight || 1;
    var contentH = Math.max(root.scrollHeight, root.offsetHeight);
    if (!contentH || !availH) return;

    var scale = contentH > availH ? (availH / contentH) : 1;
    if (scale > 0.995) scale = 1;

    if (scale < 1) {
      root.style.width = '100%';
      root.style.transformOrigin = 'top center';
      root.style.transform = 'scale(' + scale + ')';
    }
  }

  function scheduleFit() {
    if (window.__appdropFitRaf) cancelAnimationFrame(window.__appdropFitRaf);
    window.__appdropFitRaf = requestAnimationFrame(function () {
      fit();
      requestAnimationFrame(fit);
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', scheduleFit);
  } else {
    scheduleFit();
  }
  window.addEventListener('load', scheduleFit);
  window.addEventListener('resize', scheduleFit);

  if (typeof ResizeObserver !== 'undefined') {
    var ro = new ResizeObserver(scheduleFit);
    if (document.body) ro.observe(document.body);
    document.addEventListener('DOMContentLoaded', function () {
      var root = document.getElementById('appdrop-fit-root');
      if (root) ro.observe(root);
    });
  }

  document.addEventListener(
    'load',
    function (e) {
      var t = e.target;
      if (t && (t.tagName === 'IMG' || t.tagName === 'VIDEO' || t.tagName === 'IFRAME')) {
        scheduleFit();
      }
    },
    true
  );
})();
</script>
''';
  }

  static String userCssStyle(String css) {
    if (css.trim().isEmpty) return '';
    return '<style id="appdrop-custom-block-user-css">\n$css\n</style>\n';
  }

  static String userJsScript(String js) {
    if (js.trim().isEmpty) return '';
    return '<script id="appdrop-custom-block-user-js">\n$js\n</script>';
  }

  /// Assembles a full HTML document from user [html] / [css] / [js].
  static String build({
    required String html,
    String css = '',
    String js = '',
    CustomBlockLayoutMode layoutMode = CustomBlockLayoutMode.embedded,
  }) {
    final useFitScript = layoutMode != CustomBlockLayoutMode.fullScreen;

    final resetAndUser = '''
<style id="appdrop-custom-block-reset">
  html, body {
    margin: 0;
    padding: 0;
    overflow-x: hidden;
    width: 100%;
  }
  * { box-sizing: border-box; }
</style>
${userCssStyle(css)}${slotStyles(layoutMode: layoutMode)}''';

    final userJs = userJsScript(js);
    final fitJs = useFitScript ? fitScript() : '';
    final tailJs = '$userJs$fitJs';
    final source = html;
    final lower = source.toLowerCase();
    final hasHtmlTag = lower.contains('<html');

    if (hasHtmlTag) {
      var doc = source;
      if (lower.contains('</head>')) {
        doc = _replaceFirst(doc, '</head>', '$resetAndUser</head>');
      } else if (lower.contains('<head>')) {
        doc = _replaceFirst(doc, '<head>', '<head>$resetAndUser');
      } else if (lower.contains('<body')) {
        doc = _replaceFirst(doc, '<body', '$resetAndUser<body');
      } else {
        doc = '$resetAndUser$doc';
      }
      if (tailJs.isNotEmpty) {
        if (doc.toLowerCase().contains('</body>')) {
          doc = _replaceFirst(doc, '</body>', '$tailJs</body>');
        } else {
          doc = '$doc$tailJs';
        }
      }
      return doc;
    }

    return '''
<!doctype html>
<html>
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
$resetAndUser
</head>
<body>
$source
$tailJs
</body>
</html>
''';
  }

  static String _replaceFirst(String source, String pattern, String replacement) {
    final regex = RegExp(RegExp.escape(pattern), caseSensitive: false);
    return source.replaceFirst(regex, replacement);
  }
}
