//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Test Questions:
//
// What happens if we try to dispose a "global" Pod?
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:flutter/material.dart';

import 'package:df_log/df_log.dart';
import 'package:df_pod/df_pod.dart';

final _pGlobal = Pod.global('Global');

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class GlobalDisposeTest extends StatefulWidget {
  const GlobalDisposeTest({super.key});

  @override
  State<GlobalDisposeTest> createState() => _GlobalDisposeTestState();
}

class _GlobalDisposeTestState extends State<GlobalDisposeTest> {
  //
  //
  //

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green.shade200,
      width: double.infinity,
      height: double.infinity,
      child: const Column(
        children: [
          Text('Global Dispose Test'),
        ],
      ),
    );
  }

  //
  //
  //

  @override
  void dispose() {
    // Check if this throws an error.
    () async {
      try {
        _pGlobal.dispose();
      } catch (e) {
        printLightPurple('[SUCCESS]: $e');
      }
    }();
    super.dispose();
  }
}
