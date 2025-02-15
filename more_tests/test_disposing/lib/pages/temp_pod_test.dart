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

import 'package:df_pod/df_pod.dart';

final _pAnotherGlobalPod = ProtectedPod('Another Global Pod');

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class TempDisposeTest extends StatefulWidget {
  const TempDisposeTest({super.key});

  @override
  State<TempDisposeTest> createState() => _TempDisposeTestState();
}

class _TempDisposeTestState extends State<TempDisposeTest> {
  //
  //
  //

  final _pNotTempPod = Pod('Not Temp Pod');
  late final _pAnotherTempPod = _pNotTempPod.map((_) => 'Another Temp Pod');

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green.shade200,
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          MyLabel(pText: ProtectedPod('Temp Pod')),
          MyLabel(pText: _pAnotherGlobalPod),
          MyLabel(pText: _pNotTempPod),
          MyLabel(pText: _pAnotherTempPod),
        ],
      ),
    );
  }

  //
  //
  //

  @override
  void dispose() {
    _pNotTempPod.dispose();
    super.dispose();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class MyLabel extends StatefulWidget {
  final GenericPod<String> pText;

  const MyLabel({super.key, required this.pText});

  @override
  State<MyLabel> createState() => _MyLabelState();
}

class _MyLabelState extends State<MyLabel> {
  @override
  Widget build(BuildContext context) {
    return PodBuilder(
      pod: widget.pText,
      builder: (context, textSnapshot) {
        return Text(textSnapshot.value!);
      },
    );
  }
}
