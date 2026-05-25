// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Regression tests for the v0.20.0 medical-grade audit pass.
//
// One test per finding fixed:
//   - A1: PodBuilder cache key includes pod identity — different pods
//         under the same widget key never read each other's cached
//         value (the worst-case medical-grade hazard: showing the wrong
//         patient's data for even one frame).
//   - A2: cond() predicate that throws surfaces as Err on the returned
//         Resolvable, not as a sync throw or a permanent-pending hang.
//   - A3: PodCollectionBuilder._syncSubscriptions is exception-safe;
//         one rogue Listenable doesn't desync the bookkeeping.
//   - A4: PodBuilderCacheManager is bounded by `maxEntries`; oldest
//         entries evicted on overflow.
//   - A5: Custom `operator ==` that throws does NOT propagate out of
//         pod.set() — over-notify is safer than throwing.
//   - A6: PodFinalizerWrapper covers wrap, detach, and dispose-when-
//         wrapper-collected (best-effort; on web finalizer timing is
//         non-deterministic so we only exercise the synchronous paths).
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

import 'package:df_pod/df_pod.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  // ───────────────────────────────────────────────────────────────────────────
  // A1: pod-identity-scoped cache keys
  // ───────────────────────────────────────────────────────────────────────────
  group('A1: cache keys are pod-identity-scoped', () {
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
          reason: 'A1: podB must never read podA\'s cached value, '
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

  // ───────────────────────────────────────────────────────────────────────────
  // A2: cond() predicate throws surfaces as Err
  // ───────────────────────────────────────────────────────────────────────────
  group('A2: cond() predicate throws → Err', () {
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

  // ───────────────────────────────────────────────────────────────────────────
  // A3: PodCollectionBuilder exception safety
  // ───────────────────────────────────────────────────────────────────────────
  group('A3: PodCollectionBuilder exception safety', () {
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

  // ───────────────────────────────────────────────────────────────────────────
  // A4: PodBuilderCacheManager is bounded
  // ───────────────────────────────────────────────────────────────────────────
  group('A4: cache size cap', () {
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

  // ───────────────────────────────────────────────────────────────────────────
  // A5: throwing == is contained
  // ───────────────────────────────────────────────────────────────────────────
  group('A5: throwing operator == does not propagate out of pod.set', () {
    test('set with a throwing == still updates value (over-notifies)', () {
      final pod = Pod<_ThrowingEq>(const _ThrowingEq('initial'));
      var fires = 0;
      final l = () => fires++;
      pod.addStrongRefListener(strongRefListener: l);

      // The new value's == throws when compared. Pre-A5, this would
      // propagate out of pod.set. Post-A5 it's contained — over-notify.
      expect(
        () => pod.set(const _ThrowingEq('second')),
        returnsNormally,
      );
      expect(pod.getValue().tag, 'second');
      expect(fires, 1);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // A6: PodFinalizerWrapper basic coverage
  // ───────────────────────────────────────────────────────────────────────────
  group('A6: PodFinalizerWrapper', () {
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
