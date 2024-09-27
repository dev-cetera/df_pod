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

final _pCounter1 = ProtectedPod<int>(1);

class ValueListenableBuilderTest extends StatelessWidget {
  ValueListenableBuilderTest({super.key});

  final pNumbers = Pod([1, 2, 3, 4, 5]);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.yellowAccent.shade200,
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          const Text('Counter Test'),
          PodBuilder(
            pod: _pCounter1,
            builder: (context, snapshot) {
              return Text('Count: ${snapshot.value}');
            },
          ),
          OutlinedButton(
            onPressed: () => _pCounter1.update((e) => e + 1),
            child: const Text('Increase with "update"'),
          ),
          OutlinedButton(
            onPressed: () => _pCounter1.set(_pCounter1.value + 1),
            child: const Text('Increase with "set"'),
          ),
        ],
      ),
    );
  }
}
