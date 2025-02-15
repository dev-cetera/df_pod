//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by dev-cetera.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:df_pod/df_pod.dart';
import 'package:df_type/df_type.dart';

import 'package:flutter/material.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final _pCounter1 = ProtectedPod<int>(1);

class CounterTest extends StatelessWidget {
  CounterTest({super.key});

  late final pTotal = Future.value(
    ReducerPod(
      responder: () => {_pCounter1},
      reducer: (values) => (letIntOrNull(values.first) ?? 0) + 1,
    ),
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
