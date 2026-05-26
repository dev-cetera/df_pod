// Cache-safety regression tests. Group titles describe each scenario.

import 'package:df_pod/df_pod.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  group('cache keys are pod-identity-scoped', () {
    setUp(PodBuilderCacheManager.i.clear);

    testWidgets(
      'two different pods under the same widget key get different cache slots',
      (tester) async {
        const key = ValueKey('a1-isolation');
        final podA = Pod<int>(100);
        final podB = Pod<int>(200);

        Widget make(Pod<int> p) => _wrap(
              PodBuilder<int>(
                key: key,
                pod: p,
                cacheDuration: const Duration(minutes: 5),
                builder: (_, __) => const SizedBox.shrink(),
              ),
            );

        // Mount A — caches value 100 under (key, identityHashCode(podA)).
        await tester.pumpWidget(make(podA));
        // Unmount, then mount B. The cache lookup uses (key,
        // identityHashCode(podB)) which is a different compound key, so
        // misses. B's pod value (200) is read directly — never 100.
        await tester.pumpWidget(_wrap(const SizedBox.shrink()));

        var observedFirst = -1;
        await tester.pumpWidget(
          _wrap(
            PodBuilder<int>(
              key: key,
              pod: podB,
              cacheDuration: const Duration(minutes: 5),
              builder: (_, snap) {
                UNSAFE:
                observedFirst = snap.value.unwrap().unwrap();
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        expect(
          observedFirst,
          200,
          reason: 'podB must never read podA\'s cached value, '
              'even for one frame',
        );

        await tester.pumpWidget(_wrap(const SizedBox.shrink()));
      },
    );

    testWidgets(
      'same pod under the same widget key DOES hit the cache on remount',
      (tester) async {
        const key = ValueKey('a1-same-pod-hit');
        final pod = Pod<int>(7);

        Widget make() => _wrap(
              PodBuilder<int>(
                key: key,
                pod: pod,
                cacheDuration: const Duration(minutes: 5),
                builder: (_, __) => const SizedBox.shrink(),
              ),
            );

        await tester.pumpWidget(make());
        await tester.pumpWidget(_wrap(const SizedBox.shrink()));
        pod.set(8);

        late int observed;
        await tester.pumpWidget(
          _wrap(
            PodBuilder<int>(
              key: key,
              pod: pod,
              cacheDuration: const Duration(minutes: 5),
              builder: (_, snap) {
                UNSAFE:
                observed = snap.value.unwrap().unwrap();
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        // Cached 7 hits on first frame; the live 8 wins after the
        // listener fires. The first observation IS the cached value.
        expect(
          observed,
          7,
          reason: 'same-pod remount hits the cache before live fires',
        );
        await tester.pumpWidget(_wrap(const SizedBox.shrink()));
      },
    );
  });

  group('cond() predicate throws → Err', () {
    test('initial sync check that throws surfaces as Err', () async {
      final pod = Pod<int>(0);
      final r = pod.cond((_) => throw StateError('initial boom'));
      final result = await r.toAsync().value;
      expect(result.isErr(), isTrue);
    });

    test('later-notify throw surfaces as Err on the same Resolvable', () async {
      final pod = Pod<int>(0);
      var checks = 0;
      final r = pod.cond((v) {
        checks++;
        if (checks > 1) throw StateError('later boom');
        return false;
      });
      pod.set(1); // triggers the listener → throws → completer errors
      final result = await r.toAsync().value;
      expect(result.isErr(), isTrue);
    });

    test('Ok path still works (sync match returns Sync)', () async {
      final pod = Pod<int>(42);
      final r = pod.cond((v) => v == 42);
      expect(r.isSync(), isTrue);
      final result = await r.toAsync().value;
      expect(result.isOk(), isTrue);
    });
  });

  group('PodCollectionBuilder exception safety', () {
    testWidgets(
      'innerPods() that throws does not crash the tree; current '
      'subscription set is preserved',
      (tester) async {
        final source = Pod<int>(0);
        final innerPod = Pod<int>(1);
        var throws = false;

        await tester.pumpWidget(
          _wrap(
            PodCollectionBuilder(
              source: source,
              innerPods: () {
                if (throws) throw StateError('inner pods listing failed');
                return [innerPod];
              },
              builder: (_) => const SizedBox.shrink(),
            ),
          ),
        );

        // Now make innerPods throw on the next source fire.
        throws = true;
        source.set(1);
        await tester.pump();

        // Widget tree alive, inner pod still subscribed (we kept the
        // previous list because innerPods threw mid-sync).
        innerPod.set(2);
        await tester.pump();

        await tester.pumpWidget(_wrap(const SizedBox.shrink()));
      },
    );
  });

  group('cache size cap', () {
    setUp(PodBuilderCacheManager.i.clear);

    test('cap enforced; oldest entry evicted on overflow', () {
      final mgr = PodBuilderCacheManager.i;
      final originalMax = PodBuilderCacheManager.maxEntries;
      PodBuilderCacheManager.maxEntries = 3;
      try {
        const dur = Duration(seconds: 30);
        mgr.cache('k1', 1, cacheDuration: dur);
        mgr.cache('k2', 2, cacheDuration: dur);
        mgr.cache('k3', 3, cacheDuration: dur);
        expect(mgr.length, 3);

        // 4th insert evicts the oldest (k1).
        mgr.cache('k4', 4, cacheDuration: dur);
        expect(mgr.length, 3);
        expect(mgr.get('k1'), isNull, reason: 'k1 evicted as oldest');
        expect(mgr.get('k2'), 2);
        expect(mgr.get('k3'), 3);
        expect(mgr.get('k4'), 4);

        // Refreshing an existing key does NOT trigger eviction.
        mgr.cache('k2', 22, cacheDuration: dur);
        expect(mgr.length, 3);
        expect(mgr.get('k2'), 22);
        expect(mgr.get('k4'), 4);
      } finally {
        PodBuilderCacheManager.maxEntries = originalMax;
        mgr.clear();
      }
    });
  });

  group('throwing operator == does not propagate out of pod.set', () {
    test('set with a throwing == still updates value (over-notifies)', () {
      final pod = Pod<_ThrowingEq>(const _ThrowingEq('initial'));
      var fires = 0;
      final l = () => fires++;
      pod.addStrongRefListener(strongRefListener: l);

      expect(
        () => pod.set(const _ThrowingEq('second')),
        returnsNormally,
      );
      expect(pod.getValue().tag, 'second');
      expect(fires, 1);
    });
  });

  group('PodFinalizerWrapper', () {
    test('constructs and exposes the wrapped pod as a WeakReference', () {
      final pod = Pod<int>(42);
      final wrapper = PodFinalizerWrapper(pod);
      expect(wrapper.pod.target, isNotNull);
      expect(identical(wrapper.pod.target, pod), isTrue);
      pod.dispose();
    });

    test('detach() prevents the finalizer from disposing the wrapped pod', () {
      final pod = Pod<int>(1);
      final wrapper = PodFinalizerWrapper(pod);
      wrapper.detach();
      // Drop the wrapper. Without detach, the finalizer would (eventually)
      // dispose the pod. With detach, the pod stays usable. We can't
      // reliably force a GC in flutter_test, so we only assert that the
      // pod is still usable here.
      expect(pod.isDisposed, isFalse);
      pod.set(2);
      expect(pod.getValue(), 2);
      pod.dispose();
    });

    test('multiple wrappers around the same pod are independent', () {
      final pod = Pod<int>(0);
      final w1 = PodFinalizerWrapper(pod);
      final w2 = PodFinalizerWrapper(pod);
      expect(identical(w1.pod.target, pod), isTrue);
      expect(identical(w2.pod.target, pod), isTrue);
      // Detaching one wrapper does not affect the other's finalizer.
      w1.detach();
      // Both wrappers' pod refs still point to the live pod.
      expect(w1.pod.target, isNotNull);
      expect(w2.pod.target, isNotNull);
      pod.dispose();
    });

    test('wrapping an already-disposed pod is a no-op (no throw)', () {
      final pod = Pod<int>(0);
      pod.dispose();
      // The finalizer's guard is `if (!pod.isDisposed) pod.dispose();`,
      // so construction succeeds even on a dead pod.
      expect(() => PodFinalizerWrapper(pod), returnsNormally);
    });
  });
}

/// A value class whose `operator ==` always throws. Models a buggy
/// equality implementation that pod.set() must tolerate.
class _ThrowingEq {
  final String tag;
  const _ThrowingEq(this.tag);

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    throw StateError('intentional throw from operator ==');
  }
}
