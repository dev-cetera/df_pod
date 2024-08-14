//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Test Questions:
//
// Does "dispose" work?
// What happens if we call "set" after disposal?
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:flutter/material.dart';

import 'package:df_log/df_log.dart';
import 'package:df_pod/df_pod.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class DisposeTest extends StatefulWidget {
  const DisposeTest({super.key});

  @override
  State<DisposeTest> createState() => _DisposeTestState();
}

class _DisposeTestState extends State<DisposeTest> {
  //
  //
  //

  final _pTest = Pod('Test');

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red.shade200,
      width: double.infinity,
      height: double.infinity,
      child: const Column(
        children: [
          Text('Dispose Test'),
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
    // Check if setting the Pod after it's been dispose throws an error.
    () async {
      try {
        await _pTest.set('');
      } catch (e) {
        printLightPurple('[SUCCESS]: $e');
      }
    }();
    super.dispose();
  }
}
