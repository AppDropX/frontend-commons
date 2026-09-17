import 'dart:convert';

import 'embedded_custom_block_metrics.dart';

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

  /// JS channel name registered on mobile [WebViewController]s.
  static const String hostChannelName = 'AppDropHost';

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

    if (layoutMode == CustomBlockLayoutMode.embedded) {
      return '''
<style id="appdrop-custom-block-slot">
  html, body {
    margin: 0 !important;
    padding: 0 !important;
    width: 100% !important;
    height: auto !important;
    min-height: 0 !important;
    max-height: none !important;
    box-sizing: border-box !important;
    overflow-x: hidden !important;
    overflow-y: visible !important;
    background: transparent !important;
  }
  * { box-sizing: border-box; }
  body {
    display: block !important;
  }
  body > * {
    width: 100% !important;
    max-width: 100% !important;
    min-height: 0 !important;
    height: auto !important;
    margin-top: 0 !important;
    box-sizing: border-box !important;
  }
  html body *:not(script):not(style):not(link):not(img):not(video):not(canvas):not(svg):not(iframe) {
    min-height: 0 !important;
    max-height: none !important;
    height: auto !important;
    flex-grow: 0 !important;
  }
  script,
  style {
    display: none !important;
    width: 0 !important;
    min-height: 0 !important;
    height: 0 !important;
    overflow: hidden !important;
  }
</style>
''';
    }

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
    overflow-y: hidden !important;
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
    justify-content: flex-start !important;
  }
  #appdrop-fit-root > script,
  #appdrop-fit-root > style,
  script,
  style {
    display: none !important;
    width: 0 !important;
    min-height: 0 !important;
    height: 0 !important;
    overflow: hidden !important;
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
      if (node.nodeType === 1) {
        var tag = (node.tagName || "").toUpperCase();
        if (tag === "SCRIPT" || tag === "STYLE" || tag === "LINK") continue;
        var id = node.id || "";
        if (id === "appdrop-custom-block-fit") continue;
        if (id === "appdrop-custom-block-user-js") continue;
        if (id === "appdrop-custom-block-host") continue;
      }
      root.appendChild(node);
    }
    document.body.insertBefore(root, document.body.firstChild);
    return root;
  }

  function fit() {
    var root = ensureRoot();
    if (!root) return;
    if (document.body && document.body.classList.contains('appdrop-overlay-open')) {
      root.style.transform = 'none';
      root.style.width = '100%';
      root.style.marginLeft = '0';
      return;
    }

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
    return '<style id="appdrop-custom-block-user-css">\n${_escapeInlineStyle(css)}\n</style>\n';
  }

  static String userJsScript(String js) {
    final sanitized = _sanitizeUserJs(js);
    if (sanitized.trim().isEmpty) return '';
    return '<script id="appdrop-custom-block-user-js">\n${_escapeInlineScript(sanitized)}\n</script>';
  }

  /// Host overlay bridge is injected automatically. Ignore a pasted copy so
  /// preview does not run a second, conflicting IIFE.
  static String _sanitizeUserJs(String js) {
    final trimmed = js.trim();
    if (trimmed.isEmpty) return '';
    if (looksLikeHostBridgePaste(trimmed)) return '';
    return js;
  }

  static bool _hasHtmlMarkup(String source) {
    return RegExp(
      r'<\s*(div|section|button|table|p|span|ul|ol|h[1-6]|img|a|form|header|footer|main|article|nav|style)\b',
      caseSensitive: false,
    ).hasMatch(source);
  }

  /// True when [source] is the auto-injected overlay host script pasted by
  /// mistake into HTML or JS tabs.
  static bool looksLikeHostBridgePaste(String source) {
    final t = source.trim();
    if (t.isEmpty) return false;
    if (_hasHtmlMarkup(t)) return false;

    final hostMarkers = t.contains('data-appdrop-overlay-panel') ||
        t.contains('data-appdrop-overlay=') ||
        t.contains('__appdropHostInstalled') ||
        t.contains('_appdropHost') ||
        t.contains('_appdropInit') ||
        t.contains('appdrop-overlay-open') ||
        t.contains('AppDropHost.postMessage') ||
        t.contains('appdrop-custom-block-host') ||
        t.contains('appdrop-custom-block-fit');

    if (hostMarkers && !t.contains('sf-block') && !t.contains('sg-modal')) {
      return true;
    }

    return false;
  }

  /// True when the HTML tab contains a JS IIFE (commonly the host bridge)
  /// instead of markup — that would render as visible source in preview.
  static bool looksLikeBareJavaScript(String source) {
    final t = source.trim();
    if (t.isEmpty) return false;
    if (_hasHtmlMarkup(t)) return false;

    if (t.startsWith('(function') ||
        t.startsWith('!function') ||
        RegExp(r'^\s*function\s*\(', caseSensitive: false).hasMatch(t)) {
      return true;
    }

    if (RegExp(r'^\s*<script\b', caseSensitive: false).hasMatch(t)) {
      final withoutScripts = t.replaceAll(
        RegExp(r'<script[\s\S]*?</script>', caseSensitive: false),
        '',
      );
      if (!_hasHtmlMarkup(withoutScripts.trim())) return true;
    }

    if (looksLikeHostBridgePaste(t)) return true;

    if ((t.contains('window.Appdrop') || t.contains('window.AppDrop')) &&
        t.contains('postMessage')) {
      return true;
    }

    if (RegExp(
      r'^\s*(const|let|var|class|import|export)\s+',
      caseSensitive: false,
    ).hasMatch(t)) {
      return true;
    }
    if (RegExp(
      r'^\s*(document|window)\s*[.\[]',
      caseSensitive: false,
    ).hasMatch(t)) {
      return true;
    }
    if (t.contains('=>') &&
        (t.contains('addEventListener') || t.contains('querySelector'))) {
      return true;
    }

    return false;
  }

  static const String _jsPastedAsHtmlHint = '''
<div class="appdrop-html-hint">
  <p class="appdrop-html-hint__title">HTML tab mein markup paste karein</p>
  <p class="appdrop-html-hint__body">Yeh JavaScript code hai — isko HTML tab mein mat daalein. Overlay code AppDrop khud inject karta hai. Size chart ka HTML/CSS yahan paste karein; tab switching logic JS tab mein rakhein.</p>
</div>
<style>
  .appdrop-html-hint {
    font-family: Arial, Helvetica, sans-serif;
    padding: 16px;
    color: #444;
    font-size: 13px;
    line-height: 1.45;
    box-sizing: border-box;
  }
  .appdrop-html-hint__title {
    margin: 0 0 8px;
    font-weight: 700;
    color: #111;
  }
  .appdrop-html-hint__body {
    margin: 0;
  }
</style>
''';

  static String _escapeInlineScript(String source) {
    return source.replaceAll(RegExp('</script', caseSensitive: false), '<\\/script');
  }

  static String _escapeInlineStyle(String source) {
    return source.replaceAll(RegExp('</style', caseSensitive: false), '<\\/style');
  }

  static String _resolveUserHtmlBody(String html) {
    final trimmed = html.trim();
    if (trimmed.isEmpty) return '';
    if (looksLikeBareJavaScript(trimmed)) return _jsPastedAsHtmlHint;
    return html;
  }

  static String overlayStyles() {
    return r'''
<style id="appdrop-custom-block-overlay">
  html.appdrop-overlay-open,
  body.appdrop-overlay-open {
    overflow: auto !important;
    height: 100% !important;
    max-height: none !important;
  }
  body.appdrop-overlay-open #appdrop-fit-root {
    transform: none !important;
    width: 100% !important;
    min-height: 100% !important;
    height: auto !important;
  }
  body.appdrop-overlay-open #appdrop-fit-root > * {
    justify-content: flex-start !important;
    align-items: stretch !important;
    display: block !important;
    min-height: 100% !important;
  }
  [data-appdrop-overlay-panel] {
    position: fixed;
    inset: 0;
    z-index: 2147483000;
    background: #ffffff;
    overflow-y: auto;
    -webkit-overflow-scrolling: touch;
  }
  [data-appdrop-overlay-panel][hidden] {
    display: none !important;
  }
</style>
''';
  }

  /// Lets block HTML open/close a full-screen overlay via
  /// `data-appdrop-overlay="open|close"` or `Appdrop.openOverlay()`.
  static String hostBridgeScript({required bool forceOverlay}) {
    final forceFlag = forceOverlay
        ? '<script>window.__APPDROP_FORCE_OVERLAY=true;</script>\n'
        : '';
    return '''$forceFlag$_hostBridgeBody''';
  }

  static const String _hostBridgeBody = r'''
<script id="appdrop-custom-block-host">
(function () {
  if (window.__appdropHostInstalled) return;
  window.__appdropHostInstalled = true;

  function hasNativeHost() {
    try {
      return !!(window.AppDropHost && typeof window.AppDropHost.postMessage === "function");
    } catch (e) {
      return false;
    }
  }

  function post(payload) {
    var raw = JSON.stringify(payload);
    try {
      if (hasNativeHost()) window.AppDropHost.postMessage(raw);
    } catch (e) {}
    try {
      if (window.parent && window.parent !== window) {
        window.parent.postMessage(raw, "*");
      }
    } catch (e) {}
  }

  function send(open) {
    post({ source: "appdrop-custom-block", type: "overlay", open: !!open });
  }

  function isMeasurable(el) {
    if (!el || el.nodeType !== 1) return false;
    var tag = (el.tagName || "").toUpperCase();
    if (tag === "SCRIPT" || tag === "STYLE" || tag === "LINK" || tag === "META") {
      return false;
    }
    var node = el;
    while (node && node.nodeType === 1) {
      if (node.hasAttribute && node.hasAttribute("hidden")) return false;
      try {
        var style = window.getComputedStyle ? window.getComputedStyle(node) : null;
        if (style && (style.display === "none" || style.visibility === "hidden")) {
          return false;
        }
      } catch (e) {}
      node = node.parentElement;
    }
    return true;
  }

  function docBottom(el) {
    try {
      var rect = el.getBoundingClientRect();
      var scrollY = window.pageYOffset || document.documentElement.scrollTop || 0;
      return scrollY + (rect.bottom || 0);
    } catch (e) {
      return (el.offsetTop || 0) + (el.offsetHeight || 0);
    }
  }

  function fillsViewport(el) {
    var viewport = window.innerHeight || 0;
    if (viewport < 8) return false;
    var h = el.offsetHeight || 0;
    try {
      var rect = el.getBoundingClientRect();
      h = Math.max(h, rect.height || 0);
    } catch (e) {}
    return h >= viewport * 0.85;
  }

  function measureHeight() {
    var body = document.body;
    if (!body) return 0;
    var viewport = window.innerHeight || 0;
    var walkH = 0;
    var nodes = body.getElementsByTagName("*");
    for (var i = 0; i < nodes.length; i++) {
      var el = nodes[i];
      if (!isMeasurable(el)) continue;
      var tag = (el.tagName || "").toUpperCase();
      if (
        (tag === "DIV" || tag === "SECTION" || tag === "ARTICLE" || tag === "MAIN") &&
        fillsViewport(el)
      ) {
        continue;
      }
      if (fillsViewport(el) && tag !== "TABLE" && tag !== "P" && tag !== "BUTTON") {
        continue;
      }
      walkH = Math.max(walkH, docBottom(el));
    }
    var rangeH = 0;
    try {
      var range = document.createRange();
      range.selectNodeContents(body);
      rangeH = range.getBoundingClientRect().height || 0;
    } catch (e) {}
    var h = 0;
    if (walkH > 8 && walkH < viewport * 0.85) h = walkH;
    else if (rangeH > 8 && rangeH < viewport * 0.85) h = rangeH;
    else if (walkH > 8 && Math.abs(walkH - viewport) > 2) h = walkH;
    else h = walkH || rangeH;
    return Math.ceil(h);
  }

  var lastReportedHeight = -1;
  function sendResize() {
    if (document.body && document.body.classList.contains("appdrop-overlay-open")) {
      return;
    }
    var h = measureHeight();
    if (h < 1) return;
    if (h === lastReportedHeight) return;
    lastReportedHeight = h;
    post({ source: "appdrop-custom-block", type: "resize", height: h });
  }

  function scheduleResize() {
    if (window.__appdropResizeRaf) cancelAnimationFrame(window.__appdropResizeRaf);
    window.__appdropResizeRaf = requestAnimationFrame(function () {
      sendResize();
      requestAnimationFrame(sendResize);
    });
  }

  function setOverlayClass(open) {
    var root = document.documentElement;
    var body = document.body;
    if (open) {
      if (root) root.classList.add("appdrop-overlay-open");
      if (body) body.classList.add("appdrop-overlay-open");
    } else {
      if (root) root.classList.remove("appdrop-overlay-open");
      if (body) body.classList.remove("appdrop-overlay-open");
    }
  }

  function setPanels(open) {
    var panels = document.querySelectorAll("[data-appdrop-overlay-panel]");
    for (var i = 0; i < panels.length; i++) {
      if (open) panels[i].removeAttribute("hidden");
      else panels[i].setAttribute("hidden", "");
    }
  }

  function openOverlay() {
    var nativeSlot = hasNativeHost() && !window.__APPDROP_FORCE_OVERLAY;
    if (!nativeSlot) {
      setPanels(true);
      setOverlayClass(true);
    }
    send(true);
  }

  function closeOverlay() {
    setPanels(false);
    setOverlayClass(false);
    send(false);
  }

  window.Appdrop = window.Appdrop || {};
  window.Appdrop.openOverlay = openOverlay;
  window.Appdrop.closeOverlay = closeOverlay;
  window.AppDrop = window.Appdrop;

  document.addEventListener(
    "click",
    function (e) {
      var el = e.target;
      if (!el) return;
      if (el.nodeType !== 1) el = el.parentElement;
      while (el && el.getAttribute && !el.getAttribute("data-appdrop-overlay")) {
        el = el.parentElement;
      }
      if (!el || !el.getAttribute) return;
      var action = el.getAttribute("data-appdrop-overlay");
      if (action === "open") {
        e.preventDefault();
        openOverlay();
      } else if (action === "close") {
        e.preventDefault();
        closeOverlay();
      }
    },
    true
  );

  document.addEventListener("click", scheduleResize, true);
  window.addEventListener("load", function () {
    scheduleResize();
    setTimeout(scheduleResize, 50);
    setTimeout(scheduleResize, 200);
  });
  window.addEventListener("resize", scheduleResize);
  if (typeof MutationObserver !== "undefined") {
    var mo = new MutationObserver(scheduleResize);
    function observeBody() {
      if (!document.body) return;
      mo.observe(document.body, {
        childList: true,
        subtree: true,
        attributes: true,
        characterData: true,
      });
    }
    if (document.body) observeBody();
    else document.addEventListener("DOMContentLoaded", observeBody);
  }

  function applyForce() {
    if (!window.__APPDROP_FORCE_OVERLAY) return;
    setPanels(true);
    setOverlayClass(true);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", function () {
      applyForce();
      scheduleResize();
    });
  } else {
    applyForce();
    scheduleResize();
  }
})();
</script>
''';

  /// Parses `{ source: appdrop-custom-block, type: resize, height: num }`
  /// from a JS channel or `window.parent.postMessage` payload.
  static double? contentHeightFromHostMessage(dynamic raw) {
    final data = _coerceHostMessageMap(raw);
    if (data == null) return null;
    if (data['source']?.toString() != 'appdrop-custom-block') return null;
    if (data['type']?.toString() != 'resize') return null;
    final height = data['height'];
    num? value;
    if (height is num) {
      value = height;
    } else if (height is String) {
      value = num.tryParse(height.trim());
    }
    if (value == null) return null;
    return clampEmbeddedCustomBlockHeight(
      value + kEmbeddedCustomBlockHeightSlack,
    );
  }

  /// Parses `{ source: appdrop-custom-block, type: overlay, open: bool }`
  /// from a JS channel or `window.parent.postMessage` payload.
  static bool? overlayOpenFromHostMessage(dynamic raw) {
    final data = _coerceHostMessageMap(raw);
    if (data == null) return null;
    if (data['source']?.toString() != 'appdrop-custom-block') return null;
    if (data['type']?.toString() != 'overlay') return null;
    final open = data['open'];
    if (open is bool) return open;
    if (open is num) return open != 0;
    if (open is String) {
      final v = open.toLowerCase().trim();
      if (v == 'true' || v == '1') return true;
      if (v == 'false' || v == '0') return false;
    }
    return null;
  }

  static Map<String, dynamic>? _coerceHostMessageMap(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return null;
      }
      return null;
    }
    if (raw is Map) {
      try {
        return {
          for (final e in raw.entries) e.key.toString(): e.value,
        };
      } catch (_) {
        return null;
      }
    }
    try {
      final decoded = jsonDecode(jsonEncode(raw));
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
  }

  /// Assembles a full HTML document from user [html] / [css] / [js].
  static String build({
    required String html,
    String css = '',
    String js = '',
    CustomBlockLayoutMode layoutMode = CustomBlockLayoutMode.embedded,
    bool forceOverlay = false,
  }) {
    final useFitScript = layoutMode == CustomBlockLayoutMode.popup;

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
${userCssStyle(css)}${slotStyles(layoutMode: layoutMode)}${overlayStyles()}''';

    final stretchKill = layoutMode == CustomBlockLayoutMode.embedded
        ? _embeddedStretchKillStyles()
        : '';
    final hostJs = hostBridgeScript(forceOverlay: forceOverlay);
    final userJs = userJsScript(js);
    final fitJs = useFitScript ? fitScript() : '';
    final tailJs = '$stretchKill$hostJs$userJs$fitJs';
    final source = _resolveUserHtmlBody(html);
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

  static String _embeddedStretchKillStyles() {
    return '''
<style id="appdrop-custom-block-stretch-kill">
  html, body {
    height: auto !important;
    min-height: 0 !important;
    max-height: none !important;
    background: transparent !important;
  }
  html body *:not(script):not(style):not(link):not(img):not(video):not(canvas):not(svg):not(iframe) {
    min-height: 0 !important;
    max-height: none !important;
    height: auto !important;
    flex-grow: 0 !important;
  }
</style>
''';
  }

  static String _replaceFirst(String source, String pattern, String replacement) {
    final regex = RegExp(RegExp.escape(pattern), caseSensitive: false);
    return source.replaceFirst(regex, replacement);
  }
}
