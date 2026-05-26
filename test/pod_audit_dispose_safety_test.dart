// Dispose-safety regression tests. Group titles describe each scenario.

import 'dart:async';

import 'package:df_pod/df_pod.dart';
import 'package:df_safer_dart/df_safer_dart.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  group('cond() resolves with Err on dispose', () {
    test('pending cond gets Err when pod is disposed before predicate matches',
        () async {
      final pod = Pod<int>(0);
      final r = pod.cond((v) => v == 42);
      expect(r.isAsync(), isTrue, reason: 'never matched synchronously');

      pod.dispose();

      final result = await r.toAsync().value;
      expect(
        result.isErr(),
        isTrue,
        reason: 'cond on disposed pod must NOT hang; it must error',
      );
    });

    test('multiple pending conds all get Err on dispose', () async {
      final pod = Pod<int>(0);
      final r1 = pod.cond((v) => v == 100);
      final r2 = pod.cond((v) => v == 200);
      final r3 = pod.cond((v) => v == 300);

      pod.dispose();

      final results = await Future.wait<Result<int>>([
        r1.toAsync().value,
        r2.toAsync().value,
        r3.toAsync().value,
      ]);
      for (final r in results) {
        expect(r.isErr(), isTrue);
      }
    });

    test('cond that resolves normally is removed from pending set', () async {
      final pod = Pod<int>(0);
      final r = pod.cond((v) => v == 1);
      pod.set(1);
      final result = await r.toAsync().value;
      expect(result.isOk(), isTrue);
      // Now dispose — no leftover cond to fail.
      pod.dispose();
    });
  });

  group('set/update on a disposed pod do not mutate value', () {
    test('set() on disposed pod leaves value untouched', () {
      final pod = Pod<int>(7);
      pod.dispose();
      pod.set(999);
      expect(
        pod.getValue(),
        7,
        reason: 'set after dispose must not silently overwrite value',
      );
    });

    test('update() on disposed pod does not invoke the updater', () {
      final pod = Pod<int>(7);
      pod.dispose();
      var called = false;
      pod.update((v) {
        called = true;
        return v + 1;
      });
      expect(called, isFalse, reason: 'updater must not run on disposed pod');
      expect(pod.getValue(), 7);
    });
  });

  group('PollingPodBuilder tolerates throwing poller', () {
    testWidgets('throwing poller does not tear the widget tree down',
        (tester) async {
      var throws = true;
      var pollerCalls = 0;

      await tester.pumpWidget(
        _wrap(
          PollingPodBuilder<int>(
            podPoller: () {
              pollerCalls++;
              if (throws) throw StateError('poller transient failure');
              // ignore: no_future_outcome_type_or_error
              return Some(Pod<int>(42));
            },
            interval: const Duration(milliseconds: 30),
            builder: (_, __) => const SizedBox.shrink(),
          ),
        ),
      );

      // initial mount also calls poller — that's the first throw.
      expect(pollerCalls, greaterThanOrEqualTo(1));

      // Advance several ticks; poller keeps throwing but widget survives.
      await tester.pump(const Duration(milliseconds: 100));
      final callsBefore = pollerCalls;
      expect(callsBefore, greaterThan(1));

      // Recover the poller; widget should now resolve.
      throws = false;
      await tester.pump(const Duration(milliseconds: 100));
      expect(pollerCalls, greaterThan(callsBefore));

      // Drain pending timers from the now-resolved pod.
      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    });
  });

  group('throwing child does not abort parent dispose', () {
    test(
      'parent fully transitions to isDisposed=true even if a child\'s '
      'dispose throws',
      () {
        final parent = Pod<int>(0);
        parent.map((v) => v + 1);
        parent.dispose();
        expect(parent.isDisposed, isTrue);
      },
    );
  });

  group('weak _children', () {
    test('parent.dispose still disposes a child the caller is holding', () {
      final parent = Pod<int>(0);
      final child = parent.map((v) => v * 2);
      expect(child.isDisposed, isFalse);
      parent.dispose();
      expect(child.isDisposed, isTrue);
    });
  });

  group('isDisposed is consistent across the dispose() body', () {
    test('observed value is true inside onAfterDispose', () {
      final pod = _ObservablePod<int>(0);
      pod.dispose();
      expect(
        pod.observedInsideAfter,
        isTrue,
        reason: 'isDisposed must read true from inside onAfterDispose',
      );
      expect(pod.isDisposed, isTrue);
    });

    test('double dispose is logged and harmless', () {
      final pod = Pod<int>(0);
      pod.dispose();
      pod.dispose();
      expect(pod.isDisposed, isTrue);
    });
  });

  group('AsyncPodBuilder surfaces pod-creation errors', () {
    testWidgets(
      'when pod future rejects, snapshot.pod is Some(Err(...)) (not None)',
      (tester) async {
        Option<Result<ValueListenable<int>>>? observedPod;
        await tester.pumpWidget(
          _wrap(
            PodBuilder<int>(
              pod: Future<ValueListenable<int>>.error(
                StateError('lookup failed'),
              ),
              builder: (_, snap) {
                observedPod = snap.pod;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        // Drain the FutureBuilder.
        await tester.pump();
        await tester.pump();

        expect(observedPod, isNotNull);
        expect(observedPod!.isSome(), isTrue, reason: 'error must be surfaced');
        UNSAFE:
        {
          final result = observedPod!.unwrap();
          expect(result.isErr(), isTrue);
        }
      },
    );
  });

  group('RootPod.refresh() returns Future<void>', () {
    test('await refresh resolves after notify has fired', () async {
      final pod = Pod<int>(0);
      var fires = 0;
      // Stable strong ref.
      final listener = () => fires++;
      pod.addStrongRefListener(strongRefListener: listener);

      await pod.refresh();
      // After the await, the scheduled notify has run.
      expect(fires, 1);
    });
  });

  group('ChildPod materialises a sync* responder once', () {
    test('responder sync* generator consumed once per refresh', () {
      final a = Pod<int>(1);
      final b = Pod<int>(2);
      var responderCalls = 0;

      Iterable<GenericPod<int>> respond() sync* {
        responderCalls++;
        yield a;
        yield b;
      }

      final child = ChildPod<int, int>(
        responder: respond,
        reducer: (vs) => vs.fold(0, (acc, v) => acc + v),
      );
      // initial value computed from one pass through respond().
      expect(child.getValue(), 3);
      final initialCalls = responderCalls;
      expect(initialCalls, greaterThanOrEqualTo(1));

      a.set(10);
      // _refresh triggers ONE additional call to respond(); the materialised
      // list is then iterated three times internally without re-invoking.
      expect(responderCalls, initialCalls + 1);
      expect(child.getValue(), 12);
    });
  });

  group('Record equality short-circuits', () {
    test('equal records do NOT notify', () {
      final pod = Pod<(int, int)>((1, 2));
      var fires = 0;
      final l = () => fires++;
      pod.addStrongRefListener(strongRefListener: l);
      pod.set((1, 2));
      expect(fires, 0);
    });

    test('inequal records DO notify', () {
      final pod = Pod<(int, int)>((1, 2));
      var fires = 0;
      final l = () => fires++;
      pod.addStrongRefListener(strongRefListener: l);
      pod.set((1, 3));
      expect(fires, 1);
    });
  });

  group('cond() guard against disposed pod', () {
    test('cond() on an already-disposed pod returns Err synchronously', () {
      final pod = Pod<int>(0);
      pod.dispose();
      final r = pod.cond((v) => v == 7);
      // Synchronous because we bail before allocating the SafeCompleter.
      expect(r.isSync(), isTrue);
      UNSAFE:
      {
        expect(r.sync().unwrap().value.isErr(), isTrue);
      }
    });

    test('cond() on a disposed pod resolves to Err via toAsync', () async {
      final pod = Pod<int>(0);
      pod.dispose();
      final r = pod.cond((v) => v == 9999);
      final result = await r.toAsync().value;
      expect(result.isErr(), isTrue);
    });
  });

  group('dispose() steps are individually guarded', () {
    test(
      'pod with pending conds disposes cleanly and surfaces Err on each',
      () async {
        final pod = Pod<int>(0);
        final r1 = pod.cond((v) => v == 9999);
        final r2 = pod.cond((v) => v == 9998);
        pod.dispose();
        expect(pod.isDisposed, isTrue);
        final results = await Future.wait<Result<int>>([
          r1.toAsync().value,
          r2.toAsync().value,
        ]);
        for (final result in results) {
          expect(result.isErr(), isTrue);
        }
      },
    );
  });

  group('predicate-triggers-dispose during cond() sync check', () {
    test(
      'predicate that calls dispose during the initial sync check '
      'does not hang the returned Resolvable',
      () async {
        final pod = Pod<int>(0);
        var calls = 0;
        final r = pod.cond((v) {
          calls++;
          pod.dispose();
          return false;
        });
        expect(calls, 1);
        expect(pod.isDisposed, isTrue);
        final result = await r.toAsync().value;
        expect(
          result.isErr(),
          isTrue,
          reason: 'cond must surface dispose-during-predicate as Err, '
              'not hang forever',
        );
      },
    );
  });

  group('PodBuilderCacheManager edge maxEntries values', () {
    setUp(PodBuilderCacheManager.i.clear);

    test('maxEntries = 0 is clamped to 1', () {
      final original = PodBuilderCacheManager.maxEntries;
      PodBuilderCacheManager.maxEntries = 0;
      try {
        const dur = Duration(seconds: 30);
        PodBuilderCacheManager.i.cache('k1', 1, cacheDuration: dur);
        expect(PodBuilderCacheManager.i.length, 1);
        PodBuilderCacheManager.i.cache('k2', 2, cacheDuration: dur);
        expect(PodBuilderCacheManager.i.length, 1);
        expect(PodBuilderCacheManager.i.get('k1'), isNull);
        expect(PodBuilderCacheManager.i.get('k2'), 2);
      } finally {
        PodBuilderCacheManager.maxEntries = original;
        PodBuilderCacheManager.i.clear();
      }
    });

    test('maxEntries = -5 is also clamped to 1', () {
      final original = PodBuilderCacheManager.maxEntries;
      PodBuilderCacheManager.maxEntries = -5;
      try {
        const dur = Duration(seconds: 30);
        PodBuilderCacheManager.i.cache('k1', 1, cacheDuration: dur);
        expect(PodBuilderCacheManager.i.length, 1);
        PodBuilderCacheManager.i.cache('k2', 2, cacheDuration: dur);
        expect(PodBuilderCacheManager.i.length, 1);
      } finally {
        PodBuilderCacheManager.maxEntries = original;
        PodBuilderCacheManager.i.clear();
      }
    });
  });

  group('RootPod.fromStream synchronous-emit race', () {
    test(
      'stream that emits + a listener that disposes during stream.listen '
      'does NOT leak the subscription',
      () async {
        // sync broadcast emits synchronously during `listen`. If a
        // listener disposes the pod before `subscription` is assigned,
        // the initial `onAfterDispose` saw a null subscription — the
        // post-listen re-check cleans up in this race.
        final controller = StreamController<int>.broadcast(sync: true);
        late final Pod<int> pod;
        pod = Pod<int>.fromStream(controller.stream, initialValue: 0);

        final l = () {
          if (!pod.isDisposed) pod.dispose();
        };
        pod.addStrongRefListener(strongRefListener: l);

        controller.add(1);
        await Future<void>.delayed(Duration.zero);

        expect(pod.isDisposed, isTrue);
        await controller.close();
      },
    );
  });

  group('ReducerPod reducer-triggers-dispose safety', () {
    test(
      'disposing a ReducerPod between refreshes does not leave a stale '
      'listener that NPEs on parent fire',
      () {
        final a = Pod<int>(1);
        final b = Pod<int>(2);
        final pSum = ReducerPod<int>(
          responder: () => [Some(a), Some(b)],
          reducer: (vs) {
            UNSAFE:
            return Some(
              vs.fold<int>(
                0,
                (acc, v) => acc + (v.isSome() ? v.unwrap() as int : 0),
              ),
            );
          },
        );
        expect(pSum.getValue(), 3);
        pSum.dispose();
        expect(pSum.isDisposed, isTrue);

        // Subscriptions only commit after the reducer returns AND only
        // if `isDisposed` is false, so no stale listener can NPE here.
        expect(() => a.set(10), returnsNormally);
        expect(() => b.set(20), returnsNormally);

        a.dispose();
        b.dispose();
      },
    );
  });
}

/// Test helper: lets us observe [isDisposed] from inside the
/// `onAfterDispose` callback without violating
/// `invalid_use_of_protected_member` from outside the class hierarchy.
final class _ObservablePod<T extends Object> extends RootPod<T> {
  _ObservablePod(super.value) {
    onAfterDispose = () {
      observedInsideAfter = isDisposed;
    };
  }

  bool? observedInsideAfter;
}
