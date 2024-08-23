//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Test Questions:
//
// 1. ???
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:df_pod/src/experimental/easy_pod.dart';

import 'package:flutter/material.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final _pCounter1 = EasyPod<int>(1);

class EasyPodTest extends StatelessWidget {
  const EasyPodTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.greenAccent.shade200,
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          const Text('EasyPod Test'),
          Builder(
            builder: (context) {
              return Text('Count: ${_pCounter1.get(context)}');
            },
          ),
          OutlinedButton(
            onPressed: () => _pCounter1.update((e) => e + 1),
            child: const Text('Increase!'),
          ),
        ],
      ),
    );
  }
}
