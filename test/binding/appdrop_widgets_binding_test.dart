import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_commons/binding/appdrop_widgets_binding.dart';

/// Test binding with the same font-change deferral as production startup.
class _FontsChangeTestBinding extends AutomatedTestWidgetsFlutterBinding
    with AppDropFontsChangeDeferral {}

void main() {
  _FontsChangeTestBinding();

  testWidgets('fontsChange during mid-frame microtasks does not assert', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Text('Hello'),
      ),
    );
    expect(tester.binding.schedulerPhase, SchedulerPhase.idle);
    expect(tester.binding.hasScheduledFrame, isFalse);

    tester.binding.scheduleFrameCallback((_) {
      scheduleMicrotask(() {
        tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          SystemChannels.system.name,
          const JSONMessageCodec().encodeMessage(<String, Object>{
            'type': 'fontsChange',
          }),
          (_) {},
        );
      });
    });

    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(tester.binding.schedulerPhase, SchedulerPhase.idle);
    // RelayoutWhenSystemFontsChangeMixin schedules the text relayout once the
    // deferred fontsChange is delivered on the idle turn.
    expect(tester.binding.hasScheduledFrame, isTrue);
  });
}
