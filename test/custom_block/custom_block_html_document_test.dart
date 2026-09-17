import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_commons/custom_block/custom_block_api_payload.dart';
import 'package:frontend_commons/custom_block/custom_block_html_document.dart';
import 'package:frontend_commons/custom_block/embedded_custom_block_metrics.dart';

void main() {
  group('CustomBlockHtmlDocument', () {
    test('wraps fragment CSS and JS without rendering scripts as text', () {
      final document = CustomBlockHtmlDocument.build(
        html: '<section id="content">Hello</section>',
        css: '#content { color: red; }',
        js: 'document.body.dataset.ready = "true";',
      );

      expect(document, contains('<section id="content">Hello</section>'));
      expect(
        document,
        contains('<script id="appdrop-custom-block-host">'),
      );
      expect(
        document,
        contains('<script id="appdrop-custom-block-user-js">'),
      );
      expect(document.indexOf('<script id="appdrop-custom-block-host">'),
          lessThan(document.indexOf('</body>')));
    });

    test('shows a useful hint when JavaScript is pasted into HTML', () {
      const pastedHost = '''
(function () {
  if (window.__appdropHostInstalled) return;
  window.__appdropHostInstalled = true;
  window.AppDropHost.postMessage("test");
})();
''';

      final document = CustomBlockHtmlDocument.build(html: pastedHost);

      expect(document, contains('HTML tab mein markup paste karein'));
      expect(document, isNot(contains(pastedHost)));
    });

    test('detects common JavaScript statements in the HTML field', () {
      const pastedJs = '''
const button = document.querySelector("#open");
button.addEventListener("click", () => window.open("/"));
''';

      final document = CustomBlockHtmlDocument.build(html: pastedJs);

      expect(document, contains('HTML tab mein markup paste karein'));
      expect(document, isNot(contains(pastedJs)));
    });

    test('preserves ordinary user IIFE JavaScript', () {
      const userJs = '(function () { window.userWidgetReady = true; })();';

      final document = CustomBlockHtmlDocument.build(
        html: '<div>Widget</div>',
        js: userJs,
      );

      expect(document, contains(userJs));
    });

    test('keeps injected host JS inside script tags on an empty block', () {
      final document = CustomBlockHtmlDocument.build(html: '');

      expect(document, contains('<script id="appdrop-custom-block-host">'));
      expect(document, contains('type: "resize"'));
      expect(document, contains('scheduleResize'));
      expect(document, contains('function isMeasurable'));
      expect(document, contains('function fillsViewport'));
      expect(document, contains('createRange'));
      expect(document, contains('getBoundingClientRect'));
    });

    test('applies mode-specific viewport behavior', () {
      final embedded = CustomBlockHtmlDocument.build(
        html: '<div>Embedded</div>',
        layoutMode: CustomBlockLayoutMode.embedded,
      );
      final fullScreen = CustomBlockHtmlDocument.build(
        html: '<div>Full screen</div>',
        layoutMode: CustomBlockLayoutMode.fullScreen,
      );
      final popup = CustomBlockHtmlDocument.build(
        html: '<div>Popup</div>',
        layoutMode: CustomBlockLayoutMode.popup,
      );

      expect(embedded, isNot(contains('id="appdrop-custom-block-fit"')));
      expect(embedded, contains('height: auto !important'));
      expect(embedded, contains('id="appdrop-custom-block-stretch-kill"'));
      expect(popup, contains('id="appdrop-custom-block-fit"'));
      expect(fullScreen, isNot(contains('id="appdrop-custom-block-fit"')));
      expect(fullScreen, contains('overflow-y: auto !important'));
    });

    test('parses content-height resize messages', () {
      expect(
        CustomBlockHtmlDocument.contentHeightFromHostMessage(
          '{"source":"appdrop-custom-block","type":"resize","height":412}',
        ),
        412 + kEmbeddedCustomBlockHeightSlack,
      );
      expect(
        CustomBlockHtmlDocument.contentHeightFromHostMessage(
          '{"source":"appdrop-custom-block","type":"overlay","open":true}',
        ),
        isNull,
      );
    });
  });

  test('CustomBlockApiPayload reads popup metadata from nested config', () {
    final payload = CustomBlockApiPayload.fromDetailApiJson({
      'id': 'popup-1',
      'config': {
        'html': '<div>Popup</div>',
        'display_mode': 'popup',
        'popup_type': 'bottom',
      },
    });

    expect(payload, isNotNull);
    expect(payload!.displayMode, 'popup');
    expect(payload.popupType, 'bottom');
  });

  test('embedded height clamp keeps strip slots small', () {
    expect(clampEmbeddedCustomBlockHeight(42), 42);
    expect(clampEmbeddedCustomBlockHeight(2), kEmbeddedCustomBlockMinHeight);
    expect(clampEmbeddedCustomBlockHeight(900), kEmbeddedCustomBlockMaxHeight);
  });
}
