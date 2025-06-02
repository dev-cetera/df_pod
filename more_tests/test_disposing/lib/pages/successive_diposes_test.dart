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

class SuccessiveDisposesTest extends StatefulWidget {
  const SuccessiveDisposesTest({super.key});

  @override
  State<SuccessiveDisposesTest> createState() => _SuccessiveDisposesTestState();
}

class _SuccessiveDisposesTestState extends State<SuccessiveDisposesTest> {
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
      color: Colors.indigo.shade200,
      width: double.infinity,
      height: double.infinity,
      child: const Column(children: [Text('Successive Disposes Test')]),
    );
  }

  //
  //
  //

  @override
  void dispose() {
    super.dispose();
    _pTest.dispose();
    // Check if the Pod is already disposed.
    if (_pTest.isDisposed) {
      Log.printYellow('[SUCCESS] Pod is already disposed!');
    } else {
      Log.printRed('[FAIL] Pod is NOT already disposed!');
    }
    // Check to see if redundant dispose calls are ignored.
    _pTest.dispose();
    _pTest.dispose();
    _pTest.dispose();
    _pTest.dispose();
    _pTest.dispose();
    _pTest.dispose();
  }
}
