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

final _pSharedCounter = SharedIntPodCreator.global('shared_counter');

class SharedCounterPodTest extends StatelessWidget {
  const SharedCounterPodTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green.shade200,
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          const Text('Shared Counter'),
          PodBuilder(
            pod: _pSharedCounter,
            builder: (sharedCounterSnapshot) =>
                Text('Counter: ${sharedCounterSnapshot.value}'),
          ),
          OutlinedButton(
            onPressed: () =>
                _pSharedCounter.then((e) => e.update((e) => (e ?? 0) + 1)),
            child: const Text('Add with "update"'),
          ),
        ],
      ),
    );
  }
}
