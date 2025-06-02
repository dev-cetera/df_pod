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
      child: const Column(children: [Text('Dispose Test')]),
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
        _pTest.set('');
      } catch (e) {
        Log.printPurple('[SUCCESS]: $e');
      }
    }();
    super.dispose();
  }
}
