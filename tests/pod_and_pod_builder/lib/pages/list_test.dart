import 'dart:math';

import 'package:df_pod/df_pod.dart';
import 'package:flutter/material.dart';

final _pList = Pod<List>.global([]);

class ListTest extends StatelessWidget {
  const ListTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.yellow.shade200,
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          const Text('List Test'),
          PodBuilder(
            pod: _pList,
            builder: (context, value, child) => Text('List: $value'),
          ),
          OutlinedButton(
            onPressed: () => _pList.update((e) => e..add(e.length)),
            child: const Text('Add with "update"'),
          ),
          OutlinedButton(
            onPressed: () => _pList.set(_pList.value.sublist(0, max(_pList.value.length - 1, 0))),
            child: const Text('Remove with "set"'),
          ),
          OutlinedButton(
            onPressed: () => _pList.updateValue.add(_pList.value.length),
            child: const Text('Add with "updateValue"'),
          ),
        ],
      ),
    );
  }
}
