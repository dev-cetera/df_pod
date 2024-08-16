//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Test Questions:
//
// 1. Does "disposeIfTemp" dispose "temp" pods and ignore other pods?
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:flutter/material.dart';

import 'package:df_log/df_log.dart';
import 'package:df_pod/df_pod.dart';

final _pAnotherGlobalPod = GlobalPod('Another Global Pod');

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
  late final _pAnotherTempPod = _pNotTempPod.mapToTemp((_) => 'Another Temp Pod');

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
          MyLabel(
            pText: TempPod('Temp Pod'),
          ),
          MyLabel(
            pText: _pAnotherGlobalPod,
          ),
          MyLabel(
            pText: _pNotTempPod,
          ),
          MyLabel(
            pText: _pAnotherTempPod,
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
    _pNotTempPod.dispose();
    super.dispose();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class MyLabel extends StatefulWidget {
  final AnyPod<String> pText;

  const MyLabel({
    super.key,
    required this.pText,
  });

  @override
  State<MyLabel> createState() => _MyLabelState();
}

class _MyLabelState extends State<MyLabel> {
  @override
  Widget build(BuildContext context) {
    return PodBuilder(
      pod: widget.pText,
      builder: (textSnapshot) {
        return Text(textSnapshot.value!);
      },
    );
  }

  @override
  void dispose() {
    // Will only dispose pText if it's marked as temp.
    widget.pText.disposeIfTemp();

    // Check if pText got disposed.
    if (widget.pText.isDisposed) {
      printLightYellow(
        '[SUCCESS]: The Pod with text "${widget.pText.value}" is temp and got disposed by MyLabel',
      );
    } else {
      printLightPurple(
        '[SUCCESS]: The Pod with text "${widget.pText.value}" is NOT temp and did NOT get disposed by MyLabel',
      );
    }
    super.dispose();
  }
}
