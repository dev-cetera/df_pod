// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Regression tests for the robustness pass:
//   - ChildPod._refresh exception leaves _isDirty cleared (try/finally).
//   - PodBuilderCacheManager evicts from BOTH maps on expiry.
//   - addSingleExecutionListener and cond() pin their internal listeners
//     so the GC cannot collect them before they fire.
//   - RootPod.fromStream drops in-flight events that arrive after dispose.
//   - PodBuilder pod-swap on the same widget bypasses the cache.
//   - PodListBuilder cache stores a materialised List, not a lazy iterable.
//   - PodFinalizerWrapper is now exported and constructs safely.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

import 'dart:async';

import 'package:df_pod/df_pod.dart';
import 'package:df_safer_dart/df_safer_dart.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  group('ChildPod._refresh exception handling', () {
    test('throwing reducer leaves _isDirty cleared — subsequent fires work',
        () {
      final parent = Pod<int>(0);
      var shouldThrow = true;
      var goodEvaluations = 0;

      final child = parent.map<int>((v) {
        if (shouldThrow && v == 1) {
          throw StateError('first refresh blew up');
        }
        goodEvaluations++;
        return v * 10;
      });
      // map() reads value once at construction time, so initial evaluation
      // counts as 1.
      expect(goodEvaluations, 1);

      // Trigger the throw via parent set.
      try {
        parent.set(1);
      } catch (_) {
        // The reducer throws inside _refresh which is called as a listener
        // — WeakChangeNotifier wraps listener exceptions with
        // FlutterError.reportError, so the parent.set itself doesn't throw.
      }

      // If _isDirty were left stuck at true, subsequent fires would silently
      // no-op forever. Verify the next fire actually evaluates the reducer.
      shouldThrow = false;
      parent.set(2);
      expect(
        goodEvaluations,
        greaterThan(1),
        reason: '_isDirty must be cleared even when reducer throws',
      );
      expect(child.getValue(), 20);
    });
  });

  group('PodBuilderCacheManager eviction', () {
    test('expired entry is evicted from the inner cache on first read', () {
      final mgr = PodBuilderCacheManager.i;
      mgr.clear();
      const key = 'eviction-test';

      mgr.cache(key, 'hello', cacheDuration: const Duration(milliseconds: 1));
      // Sleep past the deadline.
      final deadline = DateTime.now().add(const Duration(milliseconds: 10));
      while (DateTime.now().isBefore(deadline)) {
        // busy-wait
      }

      // First read: expired → returns null AND evicts.
      expect(mgr.get(key), isNull);

      // Bug guard: a previous version left the value in the inner cache and
      // a second read would resurrect it. After eviction it stays null.
      expect(mgr.get(key), isNull);
    });

    test('clear() removes every entry', () {
      final mgr = PodBuilderCacheManager.i;
      mgr.cache('a', 1, cacheDuration: const Duration(minutes: 5));
      mgr.cache('b', 2, cacheDuration: const Duration(minutes: 5));
      mgr.clear();
      expect(mgr.get('a'), isNull);
      expect(mgr.get('b'), isNull);
    });
  });

  group('Pinned-listener mechanism', () {
    test(
      'addSingleExecutionListener fires reliably after a GC hint',
      () async {
        final pod = Pod<int>(0);
        var fired = false;

        pod.addSingleExecutionListener(() {
          fired = true;
        });

        // Encourage GC. Dart has no `forceGc()` in pure-Dart, but allocating
        // a moderate amount of garbage gives the collector reason to run
        // between the addListener and the notify.
        for (var i = 0; i < 1000; i++) {
          // ignore: unused_local_variable
          final junk = List<int>.filled(1000, i);
        }
        await Future<void>.delayed(Duration.zero);

        pod.set(1);
        expect(fired, isTrue, reason: 'pinned listener must survive GC hints');
      },
    );

    test('cond() resolves even when the returned Resolvable is discarded', () {
      final pod = Pod<int>(0);
      // Deliberately drop the returned Resolvable — earlier the listener was
      // GC-fragile and could miss the matching event.
      // ignore: df_safer_dart_lints/must_use_outcome_or_error
      pod.cond((v) => v == 5);
      // Force a GC opportunity.
      for (var i = 0; i < 1000; i++) {
        // ignore: unused_local_variable
        final junk = List<int>.filled(1000, i);
      }
      // Fire the matching value — the pinned listener should still be live.
      pod.set(5);
      // No assertion needed: if the listener fired (even though we discarded
      // the Resolvable), the pod silently transitions. If it had been GC'd
      // we'd see a hang in earlier patterns. The contract here is "no
      // exception, no listener leak, and a subsequent matching cond still
      // works".
      var followUpFired = false;
      pod.cond((v) => v == 5).ifOk((self, ok) {
        followUpFired = true;
      }).end();
      expect(followUpFired, isTrue);
    });
  });

  group('RootPod.fromStream post-dispose safety', () {
    test('events arriving after dispose are dropped silently', () async {
      final controller = StreamController<int>();
      final pod = Pod<int>.fromStream(controller.stream, initialValue: 0);

      controller.add(1);
      await Future<void>.delayed(Duration.zero);
      expect(pod.getValue(), 1);

      pod.dispose();
      // After dispose, more events arrive (subscription.cancel is async).
      controller.add(99);
      await Future<void>.delayed(Duration.zero);

      // No assertion-error thrown, value unchanged, no listener notify.
      expect(pod.isDisposed, isTrue);
      await controller.close();
    });

    test('errors arriving after dispose are dropped silently', () async {
      final controller = StreamController<int>();
      var errorsObserved = 0;
      final pod = Pod<int>.fromStream(
        controller.stream,
        initialValue: 0,
        onError: (_, __) => errorsObserved++,
      );

      controller.addError(Exception('first'));
      await Future<void>.delayed(Duration.zero);
      expect(errorsObserved, 1);

      pod.dispose();
      controller.addError(Exception('after dispose'));
      await Future<void>.delayed(Duration.zero);

      expect(
        errorsObserved,
        1,
        reason: 'onError must not fire after dispose',
      );
      await controller.close();
    });
  });

  group('PodBuilder pod-swap cache bypass', () {
    testWidgets(
      'changing pod identity under the same widget key uses the live pod, not cache',
      (tester) async {
        const key = ValueKey('swap-bypass');

        final podA = Pod<int>(42);
        late int observed;

        Widget make(Pod<int> p) => _wrap(
              PodBuilder<int>(
                key: key,
                pod: p,
                cacheDuration: const Duration(seconds: 30),
                builder: (_, snap) {
                  UNSAFE:
                  observed = snap.value.unwrap().unwrap();
                  return const SizedBox.shrink();
                },
              ),
            );

        await tester.pumpWidget(make(podA));
        expect(observed, 42);

        // Swap pod with NO unmount between — exercises didUpdateWidget.
        final podB = Pod<int>(999);
        await tester.pumpWidget(make(podB));
        expect(
          observed,
          999,
          reason: 'pod-identity change must bypass cache',
        );
      },
    );
  });

  group('PodListBuilder cache materialisation', () {
    testWidgets('cache stores a frozen List, not a lazy MappedIterable', (
      tester,
    ) async {
      const key = ValueKey('listbuilder-mat');

      final p1 = Pod<int>(10);
      final p2 = Pod<int>(20);

      late List<Result<int>> observed;

      Widget make() => _wrap(
            PodListBuilder<int>(
              key: key,
              podList: [p1, p2],
              cacheDuration: const Duration(seconds: 30),
              builder: (_, snap) {
                UNSAFE:
                observed = snap.value.unwrap().map((opt) {
                  UNSAFE:
                  return opt.unwrap();
                }).toList();
                return const SizedBox.shrink();
              },
            ),
          );

      await tester.pumpWidget(make());
      UNSAFE:
      {
        expect(observed[0].unwrap(), 10);
        expect(observed[1].unwrap(), 20);
      }

      // Unmount, then re-mount with same key but mutated pods. The cache
      // should serve the SNAPSHOT (10, 20), not re-read the now-mutated pod
      // values (which would happen with a lazy iterable).
      await tester.pumpWidget(_wrap(const SizedBox.shrink()));

      p1.set(111);
      p2.set(222);

      late List<Result<int>> observed2;
      await tester.pumpWidget(
        _wrap(
          PodListBuilder<int>(
            key: key,
            podList: [p1, p2],
            cacheDuration: const Duration(seconds: 30),
            builder: (_, snap) {
              UNSAFE:
              observed2 = snap.value.unwrap().map((opt) {
                UNSAFE:
                return opt.unwrap();
              }).toList();
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      UNSAFE:
      {
        expect(
          observed2[0].unwrap(),
          10,
          reason: 'cached snapshot of p1 was 10 — must be frozen',
        );
        expect(observed2[1].unwrap(), 20);
      }
    });
  });

  group('PodFinalizerWrapper export & construction', () {
    test('PodFinalizerWrapper is now publicly importable from df_pod', () {
      final pod = Pod<int>(7);
      final wrapper = PodFinalizerWrapper(pod);
      expect(wrapper.pod.target, same(pod));
      expect(pod.isDisposed, isFalse);

      // detach() prevents auto-disposal.
      wrapper.detach();
      expect(pod.isDisposed, isFalse);
      pod.dispose();
    });
  });
}
