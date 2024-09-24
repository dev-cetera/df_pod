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
import 'package:df_type/df_type.dart';

import 'package:flutter/material.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final _pCounter1 = GlobalPod<int>(1);

class CounterTest extends StatelessWidget {
  CounterTest({super.key});

  late final pTotal = ReducerPod.create(
    responder: () => {
      Future.value(_pCounter1),
    },
    reducer: (values) => (letIntOrNull(values.first) ?? 0) + 1,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue.shade200,
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          const Text('Counter Test'),
          PodBuilder(
            pod: pTotal,
            builder: (context, totalSnapshot) {
              return Text('Total: ${totalSnapshot.value}');
            },
          ),
          PodBuilder(
            pod: _pCounter1,
            builder: (context, counterSnapshot) {
              return Text('Count: ${counterSnapshot.value}');
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
