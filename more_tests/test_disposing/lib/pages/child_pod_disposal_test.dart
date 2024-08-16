//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Test Questions:
//
// 1. Will children also dispose if we dispose a parent Pod?
// 2. And what about the children of children?
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:flutter/material.dart';

import 'package:df_log/df_log.dart';
import 'package:df_pod/df_pod.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class ChildPodDisposalTest extends StatefulWidget {
  const ChildPodDisposalTest({super.key});

  @override
  State<ChildPodDisposalTest> createState() => _ChildPodDisposalTestState();
}

class _ChildPodDisposalTestState extends State<ChildPodDisposalTest> {
  //
  //
  //

  final _pTest = Pod('Test');
  late final _pChild1 = _pTest.map((e) => 'Child 1: $e');
  late final _pChild2 = _pChild1.map((e) => 'Child 2: $e');
  late final _pChild3 = _pChild2.map((e) => 'Child 3: $e');

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.cyan.shade200,
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          const Text('ChildPod Disposal Test'),
          PodBuilder(
            pod: _pChild3,
            builder: (context, child3Snapshot) {
              return Text(child3Snapshot.value.toString());
            },
          ),
        ],
      ),
    );
  }

  //
  //
  //

  @override
  void dispose() {
    _pTest.dispose();
    printLightBlue(
      '[${_pChild1.isDisposed == true ? 'SUCCESS' : 'FAIL'}]: _pTest/_pChild1 is disposed.',
    );
    printLightBlue(
      '[${_pChild2.isDisposed == true ? 'SUCCESS' : 'FAIL'}]: _pTest/_pChild1/_pChild2 is disposed.',
    );
    printLightBlue(
      '[${_pChild2.isDisposed == true ? 'SUCCESS' : 'FAIL'}]: _pTest/_pChild1/_pChild2/_pChild3 is disposed.',
    );
    super.dispose();
  }
}
