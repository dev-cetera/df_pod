// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// The use of this source code is governed by an MIT-style license described in
// the LICENSE file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

// Deep-dive tests for the PodBuilder family — async resolution, debouncing,
// caching, onDispose callback, pod swap edge cases, and snapshot shape. The
// existing pod_builder_test.dart covers the happy path; this file covers the
// state interactions where bugs hide.

import 'dart:async';

import 'package:df_pod/df_pod.dart';
import 'package:df_safer_dart/df_safer_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  group('PodBuilder snapshot shape', () {
    testWidgets('sync pod yields Some(Ok(value))', (tester) async {
      final pod = Pod<int>(7);
      late Option<Result<int>> capturedValue;
      late Option<Result<ValueListenable<int>>> capturedPod;

      await tester.pumpWidget(
        _wrap(
          PodBuilder<int>(
            pod: pod,
            builder: (context, snapshot) {
              capturedValue = snapshot.value;
              capturedPod = snapshot.pod;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(capturedValue.isSome(), isTrue);
      UNSAFE:
      {
        expect(capturedValue.unwrap().isOk(), isTrue);
        expect(capturedValue.unwrap().unwrap(), 7);
      }
      expect(capturedPod.isSome(), isTrue);
    });

    testWidgets('async pod yields None until the future completes', (
      tester,
    ) async {
      final completer = Completer<Pod<int>>();
      final builds = <Option<Result<int>>>[];

      await tester.pumpWidget(
        _wrap(
          PodBuilder<int>(
            pod: completer.future,
            builder: (context, snapshot) {
              builds.add(snapshot.value);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(
        builds.first.isNone(),
        isTrue,
        reason: 'before the future resolves, value should be None',
      );
      expect(
        builds.first.isNone(),
        isTrue,
        reason: 'before the future resolves, value should be None',
      );

      completer.complete(Pod<int>(99));
      await tester.pumpAndSettle();

      expect(
        builds.last.isSome(),
        isTrue,
        reason: 'after the future resolves, the last build must have a value',
      );
      UNSAFE:
      expect(builds.last.unwrap().unwrap(), 99);
    });

    testWidgets('async pod with rejected future leaves snapshot as None', (
      tester,
    ) async {
      final completer = Completer<Pod<int>>();
      final builds = <Option<Result<int>>>[];

      await tester.pumpWidget(
        _wrap(
          PodBuilder<int>(
            pod: completer.future,
            builder: (context, snapshot) {
              builds.add(snapshot.value);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      completer.completeError(StateError('async pod failed'));
      // FutureBuilder will report the error; we just verify we don't crash.
      final prevHandler = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pump();
      } finally {
        FlutterError.onError = prevHandler;
      }
      // Snapshot's `value` should remain None on the error path.
      expect(builds.last.isNone(), isTrue);
    });
  });

  group('debounceDuration', () {
    testWidgets('debounce coalesces rapid sets into one rebuild', (
      tester,
    ) async {
      final pod = Pod<int>(0);
      var buildCount = 0;

      await tester.pumpWidget(
        _wrap(
          PodBuilder<int>(
            pod: pod,
            debounceDuration: const Duration(milliseconds: 100),
            builder: (context, _) {
              buildCount++;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(buildCount, 1);

      // Fire 5 sets within the debounce window.
      for (var i = 1; i <= 5; i++) {
        pod.set(i);
        await tester.pump(const Duration(milliseconds: 10));
      }
      // No rebuild yet — timer still pending.
      expect(buildCount, 1);

      // Advance past the debounce window.
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        buildCount,
        2,
        reason: 'exactly one rebuild after the debounce window',
      );
    });

    testWidgets('disposing during a pending debounce cancels the timer', (
      tester,
    ) async {
      final pod = Pod<int>(0);
      var buildCount = 0;

      await tester.pumpWidget(
        _wrap(
          PodBuilder<int>(
            pod: pod,
            debounceDuration: const Duration(milliseconds: 100),
            builder: (context, _) {
              buildCount++;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(buildCount, 1);

      pod.set(42);
      // Tear down the widget before debounce fires.
      await tester.pumpWidget(_wrap(const SizedBox.shrink()));

      // Drain the timer.
      await tester.pump(const Duration(milliseconds: 200));
      expect(buildCount, 1, reason: 'no rebuild after widget disposed');
    });

    testWidgets('subsequent set restarts the debounce window', (tester) async {
      final pod = Pod<int>(0);
      var buildCount = 0;

      await tester.pumpWidget(
        _wrap(
          PodBuilder<int>(
            pod: pod,
            debounceDuration: const Duration(milliseconds: 100),
            builder: (context, _) {
              buildCount++;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(buildCount, 1);

      pod.set(1);
      await tester.pump(const Duration(milliseconds: 80));
      pod.set(2); // restart the timer
      await tester.pump(const Duration(milliseconds: 80));
      // 160ms total, but each set restarts the 100ms window.
      expect(buildCount, 1, reason: 'still inside the restarted window');

      await tester.pump(const Duration(milliseconds: 100));
      expect(buildCount, 2);
    });
  });

  group('onDispose callback', () {
    testWidgets('onDispose receives the pod when widget tears down', (
      tester,
    ) async {
      final pod = Pod<int>(0);
      ValueListenable<int>? disposedWith;

      await tester.pumpWidget(
        _wrap(
          PodBuilder<int>(
            pod: pod,
            onDispose: (p) => disposedWith = p,
            builder: (context, _) => const SizedBox.shrink(),
          ),
        ),
      );

      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
      expect(identical(disposedWith, pod), isTrue);
    });

    testWidgets('onDispose is NOT called when pod is swapped', (tester) async {
      final podA = Pod<int>(0);
      final podB = Pod<int>(0);
      var disposeCalls = 0;

      Widget make(Pod<int> p) => _wrap(
        PodBuilder<int>(
          pod: p,
          onDispose: (_) => disposeCalls++,
          builder: (context, _) => const SizedBox.shrink(),
        ),
      );

      await tester.pumpWidget(make(podA));
      await tester.pumpWidget(make(podB));
      expect(
        disposeCalls,
        0,
        reason: 'pod swap is didUpdateWidget, not dispose',
      );

      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
      expect(
        disposeCalls,
        1,
        reason: 'onDispose fires when the widget is removed',
      );
    });
  });

  group('PodBuilder pod-swap edge cases', () {
    testWidgets('swapping to the same pod instance does not double-attach', (
      tester,
    ) async {
      // Re-attaching a listener while it is still attached would cause it to
      // fire twice on every set. We probe by checking the per-set rebuild
      // count.
      final pod = Pod<int>(0);
      var buildCount = 0;

      // Wrap in a stateful builder so we can rebuild without changing pod.
      var marker = 0;
      late StateSetter setMarker;

      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) {
              setMarker = setState;
              // Reference `marker` so the build closure isn't const-folded.
              marker.toString();
              return PodBuilder<int>(
                pod: pod,
                builder: (context, _) {
                  buildCount++;
                  return const SizedBox.shrink();
                },
              );
            },
          ),
        ),
      );
      expect(buildCount, 1);

      // Force the parent to rebuild without changing the pod.
      setMarker(() => marker++);
      await tester.pump();
      // PodBuilder rebuilds because parent rebuilt (StatelessWidget),
      // but the inner PodResultBuilder's didUpdateWidget should not
      // double-attach the listener.

      final priorCount = buildCount;
      pod.set(1);
      await tester.pump();
      expect(
        buildCount,
        priorCount + 1,
        reason: 'one rebuild per set, not two — listener not duplicated',
      );
    });

    testWidgets('rapidly swapping pods routes events to the latest only', (
      tester,
    ) async {
      final podA = Pod<int>(0);
      final podB = Pod<int>(100);
      final podC = Pod<int>(200);
      var lastBuiltValue = -1;

      Widget make(Pod<int> p) => _wrap(
        PodBuilder<int>(
          pod: p,
          builder: (context, snapshot) {
            UNSAFE:
            lastBuiltValue = snapshot.value.unwrap().unwrap();
            return const SizedBox.shrink();
          },
        ),
      );

      await tester.pumpWidget(make(podA));
      expect(lastBuiltValue, 0);

      await tester.pumpWidget(make(podB));
      await tester.pumpWidget(make(podC));
      expect(lastBuiltValue, 200);

      // Old pods firing must NOT update the UI.
      podA.set(1);
      podB.set(101);
      await tester.pump();
      expect(lastBuiltValue, 200);

      podC.set(201);
      await tester.pump();
      expect(lastBuiltValue, 201);
    });
  });

  group('PodBuilder cache (key + cacheDuration)', () {
    testWidgets('cache survives a same-key remount within TTL', (tester) async {
      final podA = Pod<int>(111);
      const key = ValueKey('cache_test_ttl');
      var buildSnapshot = -1;

      Widget make(Pod<int> p) => _wrap(
        PodBuilder<int>(
          key: key,
          pod: p,
          cacheDuration: const Duration(seconds: 30),
          builder: (context, snapshot) {
            UNSAFE:
            buildSnapshot = snapshot.value.unwrap().unwrap();
            return const SizedBox.shrink();
          },
        ),
      );

      await tester.pumpWidget(make(podA));
      expect(buildSnapshot, 111);

      await tester.pumpWidget(_wrap(const SizedBox.shrink()));

      // Re-mount with a DIFFERENT pod but the SAME key — the cache should
      // serve the previous value initially.
      final podB = Pod<int>(222);
      await tester.pumpWidget(make(podB));
      expect(
        buildSnapshot,
        111,
        reason: 'first build after remount serves the cached value',
      );

      // After podB fires once, the live value wins (cache shadowing was the
      // bug fixed in pass 4).
      podB.set(333);
      await tester.pump();
      expect(buildSnapshot, 333);
    });

    testWidgets('cache miss for a different key — live pod value wins', (
      tester,
    ) async {
      final pod = Pod<int>(50);

      Widget make(Key k) => _wrap(
        PodBuilder<int>(
          key: k,
          pod: pod,
          cacheDuration: const Duration(seconds: 30),
          builder: (context, snapshot) {
            UNSAFE:
            final v = snapshot.value.unwrap().unwrap();
            return Text('$v');
          },
        ),
      );

      await tester.pumpWidget(make(const ValueKey('cache_a')));
      expect(find.text('50'), findsOneWidget);

      pod.set(60);
      await tester.pump();
      expect(
        find.text('60'),
        findsOneWidget,
        reason: 'live pod fire must reach the UI even with a key + cache',
      );

      // Different key — cache lookup misses; first build uses pod's current
      // value (60).
      await tester.pumpWidget(make(const ValueKey('cache_b')));
      expect(find.text('60'), findsOneWidget);
    });

    testWidgets('cache with zero cacheDuration never caches', (tester) async {
      const key = ValueKey('zero_cache_test');
      var buildSnapshot = -1;

      Widget make(Pod<int> p) => _wrap(
        PodBuilder<int>(
          key: key,
          pod: p,
          cacheDuration: Duration.zero,
          builder: (context, snapshot) {
            UNSAFE:
            buildSnapshot = snapshot.value.unwrap().unwrap();
            return const SizedBox.shrink();
          },
        ),
      );

      final podA = Pod<int>(111);
      await tester.pumpWidget(make(podA));
      expect(buildSnapshot, 111);

      await tester.pumpWidget(_wrap(const SizedBox.shrink()));

      final podB = Pod<int>(222);
      await tester.pumpWidget(make(podB));
      // Zero cacheDuration means no caching — fresh value always.
      expect(buildSnapshot, 222);
    });
  });
}
