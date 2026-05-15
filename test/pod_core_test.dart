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

import 'dart:async';
import 'dart:ui' show VoidCallback;

import 'package:df_pod/df_pod.dart';
import 'package:df_safer_dart/df_safer_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Pod creation and getValue', () {
    test('stores initial value', () {
      final pod = Pod<int>(42);
      expect(pod.getValue(), 42);
    });

    test('set updates value', () {
      final pod = Pod<String>('hello');
      pod.set('world');
      expect(pod.getValue(), 'world');
    });

    test('update transforms current value', () {
      final pod = Pod<int>(10);
      pod.update((old) => old + 5);
      expect(pod.getValue(), 15);
    });
  });

  group('Equality short-circuit — notification matrix', () {
    test('int: same value does NOT notify', () {
      final pod = Pod<int>(1);
      var notifyCount = 0;
      late final listener = () => notifyCount++;
      pod.addStrongRefListener(strongRefListener: listener);

      pod.set(1); // same value
      expect(notifyCount, 0);

      pod.set(2); // different value
      expect(notifyCount, 1);
    });

    test('String: same value does NOT notify', () {
      final pod = Pod<String>('abc');
      var notifyCount = 0;
      late final listener = () => notifyCount++;
      pod.addStrongRefListener(strongRefListener: listener);

      pod.set('abc');
      expect(notifyCount, 0);

      pod.set('def');
      expect(notifyCount, 1);
    });

    test('bool: same value does NOT notify', () {
      final pod = Pod<bool>(true);
      var notifyCount = 0;
      late final listener = () => notifyCount++;
      pod.addStrongRefListener(strongRefListener: listener);

      pod.set(true);
      expect(notifyCount, 0);

      pod.set(false);
      expect(notifyCount, 1);
    });

    test('double: same value does NOT notify', () {
      final pod = Pod<double>(3.14);
      var notifyCount = 0;
      late final listener = () => notifyCount++;
      pod.addStrongRefListener(strongRefListener: listener);

      pod.set(3.14);
      expect(notifyCount, 0);

      pod.set(2.71);
      expect(notifyCount, 1);
    });

    test('List: same-content list DOES notify (identity, not equality)', () {
      final pod = Pod<List<int>>([1, 2, 3]);
      var notifyCount = 0;
      late final listener = () => notifyCount++;
      pod.addStrongRefListener(strongRefListener: listener);

      // A different List instance with the same content — should still notify
      // because List is not Comparable/Equatable.
      pod.set([1, 2, 3]);
      expect(notifyCount, 1);
    });

    test('Map: same-content map DOES notify', () {
      final pod = Pod<Map<String, int>>({'a': 1});
      var notifyCount = 0;
      late final listener = () => notifyCount++;
      pod.addStrongRefListener(strongRefListener: listener);

      pod.set({'a': 1});
      expect(notifyCount, 1);
    });

    test('enum: same value does NOT notify', () {
      final pod = Pod<_TestEnum>(_TestEnum.a);
      var notifyCount = 0;
      late final listener = () => notifyCount++;
      pod.addStrongRefListener(strongRefListener: listener);

      pod.set(_TestEnum.a);
      expect(notifyCount, 0);

      pod.set(_TestEnum.b);
      expect(notifyCount, 1);
    });
  });

  group('Listener lifecycle', () {
    test('addStrongRefListener receives notifications', () {
      final pod = Pod<int>(0);
      var notifyCount = 0;
      late final listener = () => notifyCount++;
      pod.addStrongRefListener(strongRefListener: listener);

      pod.set(1);
      pod.set(2);
      pod.set(3);
      expect(notifyCount, 3);
    });

    test('removeListener stops notifications', () {
      final pod = Pod<int>(0);
      var notifyCount = 0;
      late final listener = () => notifyCount++;
      pod.addStrongRefListener(strongRefListener: listener);

      pod.set(1);
      expect(notifyCount, 1);

      pod.removeListener(listener);
      pod.set(2);
      expect(notifyCount, 1); // no further notifications
    });

    test('multiple listeners all receive notifications', () {
      final pod = Pod<int>(0);
      var countA = 0;
      var countB = 0;
      late final listenerA = () => countA++;
      late final listenerB = () => countB++;
      pod.addStrongRefListener(strongRefListener: listenerA);
      pod.addStrongRefListener(strongRefListener: listenerB);

      pod.set(1);
      expect(countA, 1);
      expect(countB, 1);
    });

    test('removing one listener does not affect the other', () {
      final pod = Pod<int>(0);
      var countA = 0;
      var countB = 0;
      late final listenerA = () => countA++;
      late final listenerB = () => countB++;
      pod.addStrongRefListener(strongRefListener: listenerA);
      pod.addStrongRefListener(strongRefListener: listenerB);

      pod.removeListener(listenerA);
      pod.set(1);
      expect(countA, 0);
      expect(countB, 1);
    });
  });

  group('Dispose', () {
    test('dispose prevents further set calls from notifying', () {
      final pod = Pod<int>(0);
      var notifyCount = 0;
      late final listener = () => notifyCount++;
      pod.addStrongRefListener(strongRefListener: listener);

      pod.dispose();

      // After dispose, the pod is in a broken state; set may throw or
      // silently do nothing. We just verify no listener fires.
      try {
        pod.set(1);
      } catch (_) {
        // Expected — some implementations throw after dispose.
      }
      expect(notifyCount, 0);
    });

    test('removeListener is safe to call after dispose', () {
      final pod = Pod<int>(0);
      late final listener = () {};
      pod.addStrongRefListener(strongRefListener: listener);

      pod.dispose();
      // Should not throw.
      pod.removeListener(listener);
    });
  });

  group('Reentrant removal during notify', () {
    test('addSingleExecutionListener fires once and is auto-removed', () {
      final pod = Pod<int>(0);
      var fireCount = 0;
      final userListener = () => fireCount++;
      pod.addSingleExecutionListener(userListener);

      pod.set(1);
      expect(fireCount, 1, reason: 'one-shot should fire on first notify');

      pod.set(2);
      expect(fireCount, 1, reason: 'one-shot must not fire a second time');
    });

    test('removing one listener mid-notify keeps the others firing', () {
      final pod = Pod<int>(0);
      var aCount = 0;
      var bCount = 0;
      var cCount = 0;
      final listenerA = () => aCount++;
      late final VoidCallback listenerB;
      listenerB = () {
        bCount++;
        pod.removeListener(listenerB);
      };
      final listenerC = () => cCount++;
      pod.addStrongRefListener(strongRefListener: listenerA);
      pod.addStrongRefListener(strongRefListener: listenerB);
      pod.addStrongRefListener(strongRefListener: listenerC);

      pod.set(1);
      expect(aCount, 1);
      expect(bCount, 1);
      expect(cCount, 1, reason: 'C must still fire even after B self-removes');

      pod.set(2);
      expect(aCount, 2);
      expect(bCount, 1, reason: 'B was removed during the previous notify');
      expect(cCount, 2);
    });

    test('addSingleExecutionListener coexists with regular listeners', () {
      final pod = Pod<int>(0);
      var oneShotCount = 0;
      var regularCount = 0;
      final regular = () => regularCount++;
      final oneShot = () => oneShotCount++;
      pod.addStrongRefListener(strongRefListener: regular);
      pod.addSingleExecutionListener(oneShot);

      pod.set(1);
      expect(oneShotCount, 1);
      expect(regularCount, 1);

      pod.set(2);
      expect(oneShotCount, 1, reason: 'one-shot is gone');
      expect(regularCount, 2, reason: 'regular keeps firing');
    });
  });

  group('refresh() lifecycle', () {
    test(
      'refresh() before dispose does not throw on the scheduled tick',
      () async {
        final pod = Pod<int>(0);
        pod.refresh();
        pod.dispose();
        // Drain the Future.delayed(Duration.zero) the refresh enqueued.
        await Future<void>.delayed(Duration.zero);
        // No assert/throw — the post-dispose tick is a no-op.
      },
    );
  });

  group('ChildPod (map)', () {
    test('derives value from parent', () {
      final parent = Pod<int>(5);
      final child = parent.map((v) => 'value=$v');
      expect(child.getValue(), 'value=5');
    });
  });

  group('ReducerPod construction', () {
    test('ReducerPod<String> initializes without LateInitializationError', () {
      final pa = Pod<String>('hello');
      final pb = Pod<String>('world');
      final pSum = ReducerPod<String>(
        responder: () => [Some(pa), Some(pb)],
        reducer: (vs) => Some('${vs[0].unwrapOr("")} ${vs[1].unwrapOr("")}'),
      );
      expect(pSum.getValue(), 'hello world');
    });

    test(
      'ReducerPod<int>.single initializes without LateInitializationError',
      () {
        final source = Pod<int>(42);
        final mirror = ReducerPod<int>.single(() => Some(source));
        expect(mirror.getValue(), 42);
      },
    );

    test('ReducerPod<int> propagates parent updates after initial value', () {
      final pa = Pod<int>(1);
      final pb = Pod<int>(2);
      final pSum = ReducerPod<int>(
        responder: () => [Some(pa), Some(pb)],
        reducer: (vs) {
          final a = vs[0].unwrapOr(0) as int;
          final b = vs[1].unwrapOr(0) as int;
          return Some(a + b);
        },
      );
      expect(pSum.getValue(), 3);
      pa.set(10);
      expect(pSum.getValue(), 12);
    });
  });

  group('Pod.fromStream', () {
    test('survives an error event without propagating to the zone', () async {
      final controller = StreamController<int>();
      final pod = Pod<int>.fromStream(controller.stream, initialValue: 0);
      controller.add(1);
      await Future<void>.delayed(Duration.zero);
      expect(pod.getValue(), 1);

      controller.addError(Exception('intentional'));
      await Future<void>.delayed(Duration.zero);

      controller.add(2);
      await Future<void>.delayed(Duration.zero);
      expect(
        pod.getValue(),
        2,
        reason: 'pod still processes values after a stream error',
      );

      await controller.close();
      pod.dispose();
    });
  });

  group('cond()', () {
    test('removes its internal listener once the condition is met', () {
      final pod = Pod<int>(0);
      var testCallCount = 0;

      // Drop the returned Resolvable — the leak fix means the internal
      // listener must clean itself up regardless of whether the caller awaits.
      // ignore: unused_local_variable
      final unused = pod.cond((v) {
        testCallCount++;
        return v >= 5;
      });

      expect(testCallCount, 1, reason: 'cond runs the test synchronously once');

      pod.set(2);
      expect(testCallCount, 2);

      pod.set(5); // condition met — listener should self-remove
      expect(testCallCount, 3);

      pod.set(6); // pod fires, but the cond listener is gone
      expect(
        testCallCount,
        3,
        reason: 'cond listener was removed when condition was first met',
      );
    });
  });

  group('Dispose-during-notify', () {
    test('disposing inside a listener does not fire later listeners', () {
      final pod = Pod<int>(0);
      var firstFired = false;
      var secondFired = false;
      final firstListener = () {
        firstFired = true;
        pod.dispose();
      };
      final secondListener = () {
        secondFired = true;
      };
      pod.addStrongRefListener(strongRefListener: firstListener);
      pod.addStrongRefListener(strongRefListener: secondListener);

      pod.set(1);

      expect(firstFired, isTrue);
      expect(
        secondFired,
        isFalse,
        reason: 'a listener that dispose()s the pod should halt the cycle',
      );
    });
  });

  group('SharedPod lifecycle', () {
    test('queued task that resolves after dispose() is a no-op', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final pod = await SharedPod.create<String, String>(
        'pass3_dispose_key',
        fromValue: (v) => v ?? '',
        toValue: (v) => v,
        initialValue: '',
      );

      final pending = pod.set('A');
      pod.dispose();

      // Task is now in the queue and will run after dispose. It must not
      // crash with the disposed-pod assertion.
      await pending;
    });

    test('SharedJsonPod recovers from corrupted storage value', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'pass3_corrupt_key': 'not valid json {',
      });
      // Should not throw on construction even though storage is corrupted.
      final pod = await SharedJsonPodCreator.create(
        'pass3_corrupt_key',
        initialValue: const <String, Object>{'fallback': 1},
      );
      expect(pod.getValue(), {'fallback': 1});
    });
  });

  group('PodReducer arity helpers', () {
    test('PodReducer2.reduce calls the responder once per refresh', () {
      final pa = Pod<int>(1);
      final pb = Pod<int>(2);
      var responderCalls = 0;
      final sum = PodReducer2.reduce<int, int, int>(() {
        responderCalls++;
        return (pa, pb);
      }, (a, b) => a.getValue() + b.getValue());
      // Construction does one refresh.
      final initialCalls = responderCalls;
      expect(sum.getValue(), 3);

      pa.set(10);
      // After one parent update we expect exactly one additional responder
      // call. Earlier versions of the helper invoked the responder twice
      // per refresh (once for parents, once for values).
      expect(
        responderCalls - initialCalls,
        1,
        reason: 'responder should be called once per refresh, not twice',
      );
      expect(sum.getValue(), 12);
    });
  });
}

enum _TestEnum { a, b }
