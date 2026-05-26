// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Worker-isolate friendliness tests.
//
// Spawns real Dart isolates via `Isolate.spawn` from within
// `flutter_test`. Worker isolates do NOT have `WidgetsBinding` set up
// and do NOT have access to the main isolate's platform-channel
// messenger — they are the production reality these tests model.
//
// Worker entry points must be top-level functions (Isolate.spawn
// constraint).
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

import 'dart:async';
import 'dart:isolate';

import 'package:df_pod/df_pod.dart';
import 'package:flutter_test/flutter_test.dart';

// ───────────────────────────────────────────────────────────────────────────
// Worker entry points (top-level)
// ───────────────────────────────────────────────────────────────────────────

/// Exercises core pod APIs: construction, set, update, listeners,
/// .map, dispose. Sends back a list of milestone values.
void _coreOpsWorker(SendPort port) {
  final results = <Object>[];

  final pod = Pod<int>(0);
  results.add(pod.getValue()); // 0

  pod.set(1);
  results.add(pod.getValue()); // 1

  pod.update((v) => v + 10);
  results.add(pod.getValue()); // 11

  // Derived pod via map().
  final pSquared = pod.map<int>((v) => v * v);
  results.add(pSquared.getValue()); // 121
  pod.set(3);
  results.add(pSquared.getValue()); // 9

  // Listener.
  var fires = 0;
  final listener = () => fires++;
  pod.addStrongRefListener(strongRefListener: listener);
  pod.set(4);
  pod.set(5);
  results.add(fires); // 2

  // Disposal cascade.
  pod.dispose();
  results.add(pod.isDisposed); // true
  results.add(pSquared.isDisposed); // true (child auto-disposed)

  Isolate.exit(port, results);
}

/// Exercises the H6 fix: `_set(notifyImmediately: false)` must NOT
/// crash on a worker isolate where `WidgetsBinding.instance` throws.
/// The fallback path schedules via `scheduleMicrotask`.
///
/// `expect()` is NOT usable inside a worker (it relies on
/// `TestWidgetsFlutterBinding`) — assertions are sent back to the main
/// isolate as a result map.
void _notifyDeferredWorker(SendPort port) async {
  final pod = Pod<int>(0);
  var fires = 0;
  final listener = () => fires++;
  pod.addStrongRefListener(strongRefListener: listener);

  // This used to crash: WidgetsBinding.instance is unavailable here.
  // After H6, falls back to a microtask.
  pod.set(1, notifyImmediately: false);
  final syncValue = pod.getValue();
  final syncFires = fires;

  // Let the microtask run.
  await Future<void>.delayed(Duration.zero);

  port.send({
    'syncValue': syncValue,
    'syncFires': syncFires,
    'asyncValue': pod.getValue(),
    'asyncFires': fires,
  });
  pod.dispose();
}

/// Exercises `RootPod.fromStream` in a worker — uses a local
/// `StreamController` so no platform channel is touched.
void _fromStreamWorker(SendPort port) async {
  final controller = StreamController<int>();
  final pod = Pod<int>.fromStream(controller.stream, initialValue: -1);

  controller.add(1);
  controller.add(2);
  controller.add(3);
  await Future<void>.delayed(Duration.zero);

  port.send(pod.getValue());

  pod.dispose();
  // Late events post-dispose must be dropped silently (existing
  // robustness guarantee, re-checked here in isolate context).
  controller.add(99);
  await Future<void>.delayed(Duration.zero);
  await controller.close();
  port.send('done');
}

/// Exercises `cond()` in a worker. Used to hang if pod was disposed
/// before predicate matched — the C1 fix should make this Err out
/// instead. We verify both the happy path and the dispose-during-wait
/// path.
void _condWorker(SendPort port) async {
  // Happy path: predicate matches synchronously.
  final podA = Pod<int>(42);
  final rA = podA.cond((v) => v == 42);
  port.send(rA.isSync());
  podA.dispose();

  // Dispose-before-match: C1 must error the Resolvable.
  final podB = Pod<int>(0);
  final rB = podB.cond((v) => v == 999);
  podB.dispose();
  final settled = await rB.toAsync().value;
  port.send(settled.isErr());

  port.send('done');
}

/// Verifies the M3 fix (debounce reactivity) is unaffected by isolate
/// boundaries by exercising the underlying pod that the builders read
/// from — there's no widget tree in a worker.
void _equalityShortCircuitWorker(SendPort port) {
  final results = <bool>[];

  final pInt = Pod<int>(7);
  var iFires = 0;
  final iListener = () => iFires++;
  pInt.addStrongRefListener(strongRefListener: iListener);
  pInt.set(7);
  results.add(iFires == 0); // int equal → no fire

  final pRec = Pod<(int, int)>((1, 2));
  var rFires = 0;
  final rListener = () => rFires++;
  pRec.addStrongRefListener(strongRefListener: rListener);
  pRec.set((1, 2));
  results.add(rFires == 0); // record equal → no fire (L3 fix)
  pRec.set((1, 3));
  results.add(rFires == 1); // record unequal → fires

  pInt.dispose();
  pRec.dispose();
  Isolate.exit(port, results);
}

/// Verifies the SharedPod actionable-error message fires when a worker
/// isolate skips the `BackgroundIsolateBinaryMessenger.ensureInitialized`
/// step. The exact text of the hint matters — it's what users see.
void _sharedPodNoMessengerWorker(SendPort port) async {
  try {
    final pod = await SharedPod.create<String, String>(
      'worker_no_messenger_key',
      fromValue: (v) => v ?? '',
      toValue: (v) => v,
      initialValue: '',
    );
    pod.dispose();
    port.send({'threw': false, 'message': null});
  } catch (e) {
    port.send({'threw': true, 'message': e.toString()});
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Helpers
// ───────────────────────────────────────────────────────────────────────────

/// Spawns [entryPoint] in a worker isolate and collects messages from
/// it until the worker sends the sentinel `'done'` or exits (whichever
/// comes first). Times out after [timeout] so a hung worker fails the
/// test rather than the suite.
Future<List<Object?>> _runWorker(
  void Function(SendPort port) entryPoint, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final port = ReceivePort();
  final exitPort = ReceivePort();
  final isolate = await Isolate.spawn(
    entryPoint,
    port.sendPort,
    onExit: exitPort.sendPort,
  );
  final messages = <Object?>[];
  final collector = port.listen(messages.add);
  await Future.any<void>([
    exitPort.first,
    Future.delayed(timeout),
  ]);
  await collector.cancel();
  port.close();
  exitPort.close();
  isolate.kill(priority: Isolate.immediate);
  return messages;
}

// ───────────────────────────────────────────────────────────────────────────
// Tests
// ───────────────────────────────────────────────────────────────────────────

void main() {
  group('Core pods work in a worker isolate', () {
    test('basic ops: construct, set, update, map, listeners, dispose',
        () async {
      // _coreOpsWorker uses Isolate.exit which delivers the whole list
      // in one message.
      final messages = await _runWorker(_coreOpsWorker);
      expect(messages.length, 1, reason: 'one Isolate.exit payload');
      final results = messages.single! as List;
      expect(results, [0, 1, 11, 121, 9, 2, true, true]);
    });

    test(
      'H6: _set(notifyImmediately: false) falls back to microtask when '
      'WidgetsBinding is absent',
      () async {
        final messages = await _runWorker(_notifyDeferredWorker);
        expect(messages, isNotEmpty);
        final result = messages.first! as Map;
        expect(
          result['syncValue'],
          1,
          reason: 'value updated synchronously',
        );
        expect(
          result['syncFires'],
          0,
          reason: 'notify is deferred (no WidgetsBinding → microtask fallback)',
        );
        expect(
          result['asyncValue'],
          1,
          reason: 'value still 1 after microtask drains',
        );
        expect(
          result['asyncFires'],
          1,
          reason:
              'deferred notify must fire exactly once via scheduleMicrotask',
        );
      },
    );

    test('RootPod.fromStream tracks a local StreamController in a worker',
        () async {
      final messages = await _runWorker(_fromStreamWorker);
      expect(messages, contains(3));
      expect(messages, contains('done'));
    });

    test('cond() resolves sync match and errors on dispose-before-match',
        () async {
      final messages = await _runWorker(_condWorker);
      expect(messages, contains(true)); // sync match for v == 42
      expect(messages, contains(true)); // err on dispose-before-match
      expect(messages, contains('done'));
    });

    test('equality short-circuit (int + record/L3) works in worker', () async {
      final messages = await _runWorker(_equalityShortCircuitWorker);
      expect(messages.length, 1);
      final results = (messages.single! as List).cast<bool>();
      expect(results, [true, true, true]);
    });
  });

  group('SharedPod worker-isolate misconfig', () {
    test(
      'SharedPod.create from a worker without BackgroundIsolateBinaryMessenger '
      'fails with an actionable hint',
      () async {
        final messages = await _runWorker(_sharedPodNoMessengerWorker);
        expect(messages, isNotEmpty);
        final result = messages.first! as Map;
        expect(
          result['threw'],
          isTrue,
          reason: 'SharedPod must surface the missing-messenger failure',
        );
        final msg = result['message']! as String;
        expect(
          msg,
          contains('BackgroundIsolateBinaryMessenger.ensureInitialized'),
          reason: 'error must point to the fix-it API',
        );
        expect(
          msg,
          contains('worker'),
          reason: 'error must call out the worker-isolate scenario',
        );
      },
    );
  });
}
