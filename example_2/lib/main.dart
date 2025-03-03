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

import 'package:flutter/material.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: PageView(
          onPageChanged: (value) {
            setState(() {});
          },
          children: [PodBuilderTest(key: UniqueKey())],
        ),
      ),
    );
  }
}

final _pCounter1 = ProtectedPod<int>(1);

class PodBuilderTest extends StatefulWidget {
  const PodBuilderTest({super.key});

  @override
  State<PodBuilderTest> createState() => _PodBuilderTestState();
}

class _PodBuilderTestState extends State<PodBuilderTest> {
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
            debounceDuration: const Duration(milliseconds: 500),
            builder: (context, snapshot) {
              return Text('Count (delay): ${_pCounter1.value}');
            },
          ),
          PodBuilder(
            pod: _pCounter1,
            builder: (context, snapshot) {
              return Text('Count: ${snapshot.value}');
            },
          ),
          OutlinedButton(
            onPressed: () {
              _pCounter1.update((e) => e + 1);
              //setState(() {});
            },
            child: const Text('Increase with "update"'),
          ),
          OutlinedButton(
            onPressed: () {
              _pCounter1.set(_pCounter1.value + 1);
              setState(() {});
            },
            child: const Text('Increase with "set"'),
          ),
        ],
      ),
    );
  }
}
