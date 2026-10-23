import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Delivers `fontsChange` only while the scheduler is idle.
///
/// Flutter 3.41 asserts that text relayout from a system-font change runs in
/// [SchedulerPhase.idle]. On web, a `google_fonts` load can finish during
/// [SchedulerPhase.midFrameMicrotasks] and trip that assert
/// (flutter/flutter#151873). Flutter 3.47 removes the assert. Until then, this
/// mixin waits for idle, which is the phase the framework uses to relayout text.
@visibleForTesting
mixin AppDropFontsChangeDeferral on ServicesBinding {
  @override
  Future<void> handleSystemMessage(Object systemMessage) async {
    if (systemMessage is Map && systemMessage['type'] == 'fontsChange') {
      await _waitUntilSchedulerIdle();
    }
    await super.handleSystemMessage(systemMessage);
  }

  static Future<void> _waitUntilSchedulerIdle() async {
    final scheduler = SchedulerBinding.instance;
    while (scheduler.schedulerPhase != SchedulerPhase.idle) {
      // Callbacks for the current frame were already snapshotted. Request
      // another frame so [SchedulerBinding.endOfFrame] can complete.
      if (scheduler.schedulerPhase == SchedulerPhase.postFrameCallbacks) {
        scheduler.scheduleFrame();
      }
      await scheduler.endOfFrame;
    }
  }
}

/// Application binding used by AppDrop entry points.
///
/// Call [ensureInitialized] instead of [WidgetsFlutterBinding.ensureInitialized]
/// before any other binding is created.
class AppDropWidgetsBinding extends WidgetsFlutterBinding with AppDropFontsChangeDeferral {
  AppDropWidgetsBinding._();

  static AppDropWidgetsBinding? _binding;

  /// Creates the binding, or returns it if this isolate already has one.
  static WidgetsBinding ensureInitialized() {
    final binding = _binding;
    if (binding != null) {
      return binding;
    }
    final created = AppDropWidgetsBinding._();
    _binding = created;
    return created;
  }
}
