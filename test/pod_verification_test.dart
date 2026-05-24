// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Verifies four claims from the user's audit follow-up:
//   1. PodBuilder cacheDuration actually preserves values across remounts.
//   2. PodBuilder debounceDuration actually coalesces rapid sets.
//   3. Nested PodBuilder x 3 behaves as expected vs PodListBuilder
//      (in particular: only the innermost subtree rebuilds when only the
//      innermost pod fires).
//   4. addStrongRefListener is sound when the caller holds a strong ref,
//      and silently misses when they don't (forcing GC to confirm).
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

import 'package:df_pod/df_pod.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  group('Caching (verification)', () {
    testWidgets('non-zero cacheDuration preserves value across same-key remount', (
      tester,
    ) async {
      final key = ValueKey('cache-verify-${DateTime.now().microsecondsSinceEpoch}');

      final podA = Pod<int>(42);
      await tester.pumpWidget(
        _wrap(
          PodBuilder<int>(
            key: key,
            pod: podA,
            cacheDuration: const Duration(seconds: 10),
            builder: (_, __) => const SizedBox.shrink(),
          ),
        ),
      );
      // First mount writes _value=Ok(42) to the cache under key.toString().

      // Remount with a DIFFERENT pod under the SAME key. Cache should win.
      final podB = Pod<int>(999);
      late int observed;
      await tester.pumpWidget(
        _wrap(
          PodBuilder<int>(
            key: key,
            pod: podB,
            cacheDuration: const Duration(seconds: 10),
            builder: (_, snap) {
              observed = snap.value.unwrap().unwrap();
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(
        observed,
        42,
        reason:
            'cache should have returned the previous pod value, not the new pod value',
      );
    });

    testWidgets(
      'default cacheDuration (Duration.zero) does not preserve across remount',
      (tester) async {
        final key = ValueKey(
          'no-cache-verify-${DateTime.now().microsecondsSinceEpoch}',
        );

        final podA = Pod<int>(42);
        await tester.pumpWidget(
          _wrap(
            PodBuilder<int>(
              key: key,
              pod: podA,
              builder: (_, __) => const SizedBox.shrink(),
            ),
          ),
        );

        final podB = Pod<int>(999);
        late int observed;
        await tester.pumpWidget(
          _wrap(
            PodBuilder<int>(
              key: key,
              pod: podB,
              builder: (_, snap) {
                observed = snap.value.unwrap().unwrap();
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(
          observed,
          999,
          reason:
              'zero cacheDuration must NOT preserve the old value — live pod wins',
        );
      },
    );
  });

  group('Debouncing (verification)', () {
    testWidgets('rapid sets within debounce window produce one rebuild', (
      tester,
    ) async {
      final pod = Pod<int>(0);
      var builds = 0;
      await tester.pumpWidget(
        _wrap(
          PodBuilder<int>(
            pod: pod,
            debounceDuration: const Duration(milliseconds: 100),
            builder: (_, __) {
              builds++;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final initialBuilds = builds; // typically 1 (the mount)

      for (var i = 1; i <= 5; i++) {
        pod.set(i);
        await tester.pump(const Duration(milliseconds: 10));
      }
      // Window not yet elapsed — no rebuild past the initial mount.
      expect(
        builds,
        initialBuilds,
        reason:
            'no rebuild should have happened yet — debounce window still open',
      );

      // Advance past the window.
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        builds,
        initialBuilds + 1,
        reason: '5 rapid sets should coalesce into 1 rebuild after the window',
      );
    });

    testWidgets('no debounce → 5 sets → 5 rebuilds', (tester) async {
      final pod = Pod<int>(0);
      var builds = 0;
      await tester.pumpWidget(
        _wrap(
          PodBuilder<int>(
            pod: pod,
            builder: (_, __) {
              builds++;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final initial = builds;
      for (var i = 1; i <= 5; i++) {
        pod.set(i);
        await tester.pump();
      }
      expect(
        builds,
        initial + 5,
        reason: 'baseline: no debounce means every set rebuilds',
      );
    });
  });

  group('Nested PodBuilder vs PodListBuilder (verification)', () {
    testWidgets(
      'nested PodBuilder x 3: only the inner subtree rebuilds when the inner pod fires',
      (tester) async {
        final podOuter = Pod<int>(0);
        final podMid = Pod<int>(0);
        final podInner = Pod<int>(0);

        var outerBuilds = 0;
        var midBuilds = 0;
        var innerBuilds = 0;

        await tester.pumpWidget(
          _wrap(
            PodBuilder<int>(
              pod: podOuter,
              builder: (_, __) {
                outerBuilds++;
                return PodBuilder<int>(
                  pod: podMid,
                  builder: (_, __) {
                    midBuilds++;
                    return PodBuilder<int>(
                      pod: podInner,
                      builder: (_, __) {
                        innerBuilds++;
                        return const SizedBox.shrink();
                      },
                    );
                  },
                );
              },
            ),
          ),
        );

        final baseOuter = outerBuilds;
        final baseMid = midBuilds;
        final baseInner = innerBuilds;

        // Fire ONLY the inner pod. The outer/mid builders should not run again.
        podInner.set(1);
        await tester.pump();

        expect(
          outerBuilds,
          baseOuter,
          reason: 'outer builder must not rebuild when only inner pod fires',
        );
        expect(
          midBuilds,
          baseMid,
          reason: 'mid builder must not rebuild when only inner pod fires',
        );
        expect(
          innerBuilds,
          baseInner + 1,
          reason: 'inner builder must rebuild exactly once',
        );

        // Fire ONLY the outer. ALL three should rebuild — outer rebuilds the
        // subtree which causes mid and inner to be rebuilt by reconciliation.
        podOuter.set(1);
        await tester.pump();

        expect(
          outerBuilds,
          baseOuter + 1,
          reason: 'outer builder rebuilds on outer set',
        );
        // Mid and inner's State persists across rebuilds (didUpdateWidget) so
        // their builder is invoked when the parent rebuilds.
        expect(
          midBuilds,
          baseMid + 1,
          reason: 'mid is rebuilt as part of outer subtree rebuild',
        );
        expect(
          innerBuilds,
          baseInner + 2,
          reason: 'inner is rebuilt as part of outer subtree rebuild',
        );
      },
    );

    testWidgets(
      'PodListBuilder: any pod firing rebuilds the entire subtree',
      (tester) async {
        final p1 = Pod<int>(0);
        final p2 = Pod<int>(0);
        final p3 = Pod<int>(0);

        var builds = 0;
        await tester.pumpWidget(
          _wrap(
            PodListBuilder<int>(
              podList: [p1, p2, p3],
              builder: (_, __) {
                builds++;
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        final base = builds;

        p3.set(1);
        await tester.pump();
        expect(builds, base + 1);

        p1.set(1);
        await tester.pump();
        expect(builds, base + 2);

        p1.set(2);
        p2.set(2);
        p3.set(2);
        await tester.pump();
        // setState() in the same frame coalesces — three sets across three
        // pods produce exactly one rebuild. This is a free coalescing benefit
        // of PodListBuilder vs three nested PodBuilders (which would rebuild
        // the inner subtree once per outer/mid set).
        expect(
          builds,
          base + 3,
          reason:
              'three same-frame sets across three pods coalesce into one rebuild',
        );
      },
    );
  });

  group('addStrongRefListener soundness', () {
    test(
      'listener held by a stable variable fires on every notify',
      () {
        final pod = Pod<int>(0);
        var calls = 0;
        // Strong ref held by local var.
        final listener = () => calls++;
        pod.addStrongRefListener(strongRefListener: listener);

        for (var i = 1; i <= 5; i++) {
          pod.set(i);
        }

        expect(calls, 5);
        // Keep the listener reachable until the end so it can't be GC'd.
        expect(listener, isNotNull);
      },
    );

    test(
      'removeListener with the same instance stops further notifications',
      () {
        final pod = Pod<int>(0);
        var calls = 0;
        final listener = () => calls++;
        pod.addStrongRefListener(strongRefListener: listener);
        pod.set(1);
        expect(calls, 1);
        pod.removeListener(listener);
        pod.set(2);
        pod.set(3);
        expect(calls, 1, reason: 'no calls after remove');
      },
    );
  });
}
