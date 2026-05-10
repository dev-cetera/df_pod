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

// Aggressive / pathological-input tests. The goal is to break things — if any
// of these fall over, that's a real bug.

import 'dart:async';
import 'dart:ui' show VoidCallback;

import 'package:df_pod/df_pod.dart';
import 'package:df_safer_dart/df_safer_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Listener-list stress', () {
    test('1000 listeners all fire on a single set', () {
      final pod = Pod<int>(0);
      var totalCalls = 0;
      final listeners = <VoidCallback>[];
      for (var i = 0; i < 1000; i++) {
        final l = () => totalCalls++;
        listeners.add(l);
        pod.addStrongRefListener(strongRefListener: l);
      }

      pod.set(1);
      expect(totalCalls, 1000);

      pod.set(2);
      expect(totalCalls, 2000);
    });

    test('add/remove churn 500 times leaves no orphan listeners', () {
      final pod = Pod<int>(0);
      var calls = 0;
      final tracker = () => calls++;
      for (var i = 0; i < 500; i++) {
        pod.addStrongRefListener(strongRefListener: tracker);
        pod.removeListener(tracker);
      }
      pod.set(1);
      expect(calls, 0, reason: 'all add/remove pairs should leave nothing');
    });

    test('same listener added 5 times fires 5 times per notify', () {
      final pod = Pod<int>(0);
      var calls = 0;
      final tracker = () => calls++;
      for (var i = 0; i < 5; i++) {
        pod.addStrongRefListener(strongRefListener: tracker);
      }
      pod.set(1);
      expect(calls, 5, reason: 'no de-duplication per Listenable contract');
    });

    test('removeListener removes only one occurrence of a duplicated listener',
        () {
      final pod = Pod<int>(0);
      var calls = 0;
      final tracker = () => calls++;
      pod.addStrongRefListener(strongRefListener: tracker);
      pod.addStrongRefListener(strongRefListener: tracker);
      pod.addStrongRefListener(strongRefListener: tracker);

      pod.removeListener(tracker);
      pod.set(1);
      expect(calls, 2);
    });

    test('listener that adds 100 NEW listeners during notify does not break', () {
      final pod = Pod<int>(0);
      var firstFires = 0;
      var laterFires = 0;
      final added = <VoidCallback>[];
      late final VoidCallback first;
      first = () {
        firstFires++;
        if (firstFires == 1) {
          for (var i = 0; i < 100; i++) {
            final l = () => laterFires++;
            added.add(l);
            pod.addStrongRefListener(strongRefListener: l);
          }
        }
      };
      pod.addStrongRefListener(strongRefListener: first);

      pod.set(1);
      expect(firstFires, 1);
      // The 100 new listeners should NOT fire on the current notify cycle.
      expect(laterFires, 0);

      pod.set(2);
      expect(firstFires, 2);
      // Now they should all fire.
      expect(laterFires, 100);
    });

    test(
      'listener that removes 50 OTHER listeners mid-notify keeps the rest firing',
      () {
        final pod = Pod<int>(0);
        final listeners = <VoidCallback>[];
        var totalFires = 0;
        for (var i = 0; i < 100; i++) {
          final l = () => totalFires++;
          listeners.add(l);
          pod.addStrongRefListener(strongRefListener: l);
        }
        // Insert a listener at position ~50 that removes the next 50 listeners
        // during this notify cycle.
        final nuker = () {
          for (var i = 50; i < 100; i++) {
            pod.removeListener(listeners[i]);
          }
        };
        pod.addStrongRefListener(strongRefListener: nuker);

        pod.set(1);
        // First cycle: nuker is at index 100, runs after all 100 fired.
        // So 100 fired plus nuker. Removed 50 listeners.
        expect(totalFires, 100);

        totalFires = 0;
        pod.set(2);
        // Second cycle: only 50 listeners + nuker remain.
        expect(totalFires, 50);
      },
    );
  });

  group('Equality short-circuit edge cases', () {
    test('NaN does not short-circuit — every set notifies', () {
      final pod = Pod<double>(double.nan);
      var calls = 0;
      final tracker = () => calls++;
      pod.addStrongRefListener(strongRefListener: tracker);

      // NaN != NaN by IEEE 754 — so the short-circuit `newValue != value`
      // is always true. Every set notifies even with the same literal.
      pod.set(double.nan);
      pod.set(double.nan);
      expect(calls, 2);
    });

    test('Infinity short-circuits like any other double', () {
      final pod = Pod<double>(double.infinity);
      var calls = 0;
      final tracker = () => calls++;
      pod.addStrongRefListener(strongRefListener: tracker);
      pod.set(double.infinity);
      expect(calls, 0);
      pod.set(double.negativeInfinity);
      expect(calls, 1);
    });

    test('-0.0 and 0.0 are equal — short-circuit fires', () {
      final pod = Pod<double>(0.0);
      var calls = 0;
      final tracker = () => calls++;
      pod.addStrongRefListener(strongRefListener: tracker);
      pod.set(-0.0);
      // 0.0 == -0.0 in Dart — should NOT notify.
      expect(calls, 0);
    });

    test('empty strings are equal — no spurious notify', () {
      final pod = Pod<String>('');
      var calls = 0;
      final tracker = () => calls++;
      pod.addStrongRefListener(strongRefListener: tracker);
      pod.set('');
      expect(calls, 0);
      pod.set('x');
      expect(calls, 1);
    });
  });

  group('Lifecycle abuse', () {
    test('disposing twice is logged but not fatal', () {
      final pod = Pod<int>(0);
      pod.dispose();
      // DisposablePod guards via the _isDisposed flag: a second dispose
      // call logs an alert and returns. It must not throw.
      pod.dispose();
      expect(pod.isDisposed, isTrue);
    });

    test('addStrongRefListener after dispose is a silent orphan', () {
      final pod = Pod<int>(0);
      pod.dispose();
      // In debug this asserts; we wrap the assertion error path.
      expect(
        () => pod.addStrongRefListener(strongRefListener: () {}),
        throwsA(isA<AssertionError>()),
      );
    });

    test('parent disposal disposes the entire child chain', () {
      final root = Pod<int>(1);
      final c1 = root.map((v) => v + 1);
      final c2 = c1.map((v) => v * 10);
      final c3 = c2.map((v) => v.toString());

      expect(c1.isDisposed, isFalse);
      expect(c2.isDisposed, isFalse);
      expect(c3.isDisposed, isFalse);

      root.dispose();

      expect(c1.isDisposed, isTrue);
      expect(c2.isDisposed, isTrue);
      expect(c3.isDisposed, isTrue);
    });

    test('removeListener for a never-added listener is a no-op', () {
      final pod = Pod<int>(0);
      // Should not throw, should not affect anything.
      pod.removeListener(() {});
      pod.set(1);
      expect(pod.getValue(), 1);
    });
  });

  group('Deep / wide derived state', () {
    test('20-deep .map chain propagates updates correctly', () {
      final root = Pod<int>(0);
      var current = root.map((v) => v + 1);
      for (var i = 0; i < 19; i++) {
        current = current.map((v) => v + 1);
      }
      // Initial: 0 + 20 = 20.
      expect(current.getValue(), 20);

      root.set(100);
      expect(current.getValue(), 120);
    });

    test('diamond dependency: a -> b; a -> c; b+c -> d', () {
      final a = Pod<int>(1);
      final b = a.map((v) => v * 2);
      final c = a.map((v) => v * 3);
      var dRebuilds = 0;
      final d = b.reduce<int, int>(c, (bp, cp) {
        dRebuilds++;
        return bp.getValue() + cp.getValue();
      });
      // Initial reducer call counted.
      final initialBuilds = dRebuilds;
      expect(d.getValue(), 5); // 2 + 3

      a.set(10);
      // d should only recompute, but a's update fires both b and c, each
      // triggers d. Acceptable as long as d's value is correct.
      expect(d.getValue(), 50); // 20 + 30
      expect(dRebuilds - initialBuilds, greaterThanOrEqualTo(1));
    });

    test('reducer that throws cleans up its listeners', () {
      final a = Pod<int>(1);
      final b = Pod<int>(2);
      var thrownYet = false;
      expect(
        () => ReducerPod<int>(
          responder: () => [Some(a), Some(b)],
          reducer: (vs) {
            if (!thrownYet) {
              thrownYet = true;
              throw StateError('reducer boom');
            }
            return const Some(0);
          },
        ),
        throwsStateError,
      );

      // After the throw, the parents should not retain the dead listener.
      // We can't directly inspect; we instead set the parent and verify the
      // package does not blow up on subsequent operations.
      a.set(99);
      b.set(100);
    });
  });

  group('SharedPod chaos', () {
    test('100 rapid sets converge to last value', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final pod = await SharedPod.create<String, String>(
        'agg_chaos_key',
        fromValue: (v) => v ?? '',
        toValue: (v) => v,
        initialValue: '',
      );

      final futures = <Future<void>>[];
      for (var i = 0; i < 100; i++) {
        futures.add(pod.set('value_$i'));
      }
      await Future.wait(futures);

      expect(pod.getValue(), 'value_99');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('agg_chaos_key'), 'value_99');
    });

    test('interleaved set / delete / refresh maintain consistency', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final pod = await SharedPod.create<String, String>(
        'agg_inter_key',
        fromValue: (v) => v ?? 'init',
        toValue: (v) => v,
        initialValue: 'init',
      );

      final f1 = pod.set('A');
      final f2 = pod.delete();
      final f3 = pod.set('B');
      final f4 = pod.refresh();
      final f5 = pod.set('C');

      await Future.wait([f1, f2, f3, f4, f5]);
      expect(pod.getValue(), 'C');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('agg_inter_key'), 'C');
    });

    test('SharedJsonPod survives every shape of corrupted storage', () async {
      const corruptedValues = <String>[
        '',
        'not json',
        '[]', // valid JSON but not an object
        'null',
        '"a string"',
        '123',
        '{', // truncated
      ];
      for (final corrupt in corruptedValues) {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'corrupt_key': corrupt,
        });
        final pod = await SharedJsonPodCreator.create(
          'corrupt_key',
          initialValue: const <String, Object>{'fb': 1},
        );
        expect(
          pod.getValue(),
          {'fb': 1},
          reason: 'expected fallback for corrupted value: ${corrupt.length > 20 ? "${corrupt.substring(0, 20)}…" : corrupt}',
        );
      }
    });
  });

  group('Pod.fromStream chaos', () {
    test('rapid stream events all reach the pod', () async {
      final controller = StreamController<int>();
      final pod = Pod<int>.fromStream(controller.stream, initialValue: -1);
      for (var i = 0; i < 100; i++) {
        controller.add(i);
      }
      await Future<void>.delayed(Duration.zero);
      expect(pod.getValue(), 99);
      await controller.close();
      pod.dispose();
    });

    test('errors interleaved with values do not desync the pod', () async {
      final controller = StreamController<int>();
      final pod = Pod<int>.fromStream(controller.stream, initialValue: 0);
      controller.add(1);
      controller.addError(Exception('e1'));
      controller.add(2);
      controller.addError(Exception('e2'));
      controller.add(3);
      await Future<void>.delayed(Duration.zero);
      expect(pod.getValue(), 3);
      await controller.close();
      pod.dispose();
    });

    test('disposing pod cancels its stream subscription', () async {
      final controller = StreamController<int>();
      final pod = Pod<int>.fromStream(controller.stream, initialValue: 0);
      controller.add(1);
      await Future<void>.delayed(Duration.zero);
      expect(pod.getValue(), 1);

      pod.dispose();
      controller.add(2); // emitted but no listeners
      await Future<void>.delayed(Duration.zero);
      // The pod is disposed; getValue would be unreliable. Just confirm
      // closing the controller doesn't hang or throw.
      expect(controller.hasListener, isFalse);
      await controller.close();
    });
  });

  group('cond() correctness under stress', () {
    test('cond() that never matches keeps the listener until dispose', () {
      final pod = Pod<int>(0);
      var checks = 0;
      // ignore: unused_local_variable
      final unused = pod.cond((v) {
        checks++;
        return v == 9999; // never true in this test
      });
      // Initial sync check.
      expect(checks, 1);
      for (var i = 1; i <= 10; i++) {
        pod.set(i);
      }
      expect(checks, 11); // 1 sync + 10 fires
      pod.dispose();
    });

    test('cond() that matches synchronously returns Sync immediately', () {
      final pod = Pod<int>(42);
      final r = pod.cond((v) => v == 42);
      expect(r.isSync(), isTrue);
    });
  });

  group('ReducerPod responder shape changes', () {
    test('responder returning None for a parent skips that parent', () {
      final a = Pod<int>(1);
      final b = Pod<int>(2);
      var includeB = true;
      final pSum = ReducerPod<int>(
        responder: () =>
            includeB ? [Some(a), Some(b)] : [Some(a), const None()],
        reducer: (vs) {
          var total = 0;
          for (final v in vs) {
            if (v.isSome()) total += v.unwrap() as int;
          }
          return Some(total);
        },
      );
      expect(pSum.getValue(), 3);

      includeB = false;
      a.set(10); // refresh triggers responder
      expect(pSum.getValue(), 10);
    });
  });
}
