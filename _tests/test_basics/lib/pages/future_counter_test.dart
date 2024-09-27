//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Test Questions:
//
// 1. ???
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:df_pod/df_pod.dart';
import 'package:flutter/material.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final _pFutureCounter =
    Future.delayed(const Duration(seconds: 3), () => ProtectedPod<int>(1));

class FutureCounterTest extends StatelessWidget {
  const FutureCounterTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.indigo.shade200,
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          const Text('Future Counter Test'),
          PodBuilder(
            pod: _pFutureCounter,
            builder: (context, counterSnapshot) {
              return Text('Count: ${counterSnapshot.value}');
            },
          ),
          OutlinedButton(
            onPressed: () =>
                _pFutureCounter.then((e) => e.update((e) => e + 1)),
            child: const Text('Increase with "update"'),
          ),
          OutlinedButton(
            onPressed: () => _pFutureCounter.then((e) => e.set(e.value + 1)),
            child: const Text('Increase with "set"'),
          ),
        ],
      ),
    );
  }
}
