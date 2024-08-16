//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Test Questions:
//
// 1. ???
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'dart:async';
import 'dart:math';

import 'package:df_pod/df_pod.dart';

import 'package:flutter/material.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class PodListCallbackBuilderTest extends StatefulWidget {
  const PodListCallbackBuilderTest({super.key});

  @override
  State<PodListCallbackBuilderTest> createState() => _PodListCallbackBuilderTestState();
}

class _PodListCallbackBuilderTestState extends State<PodListCallbackBuilderTest> {
  //
  //
  //

  late final _pAppServices = Pod<AppServices>(AppServices(), onBeforeDispose: (e) => e.dispose());

  //
  //
  //

  @override
  void initState() {
    // Simulate a login or intitialisation delay.
    Future.delayed(const Duration(seconds: 2), () {
      _pAppServices.update((e) => e..initService());
    });
    super.initState();
  }

  //
  //
  //

  // Create Callback to pass to a PodListCallbackBuilder so that we can
  // detect changes to the last Pod in the chain, pMessage;
  TPodListN _messageCallback() {
    return [
      _pAppServices,
      _pAppServices.value.pHelloWorldService,
      _pAppServices.value.pHelloWorldService?.value.pMessage,
    ];
  }

  // Create a shortcut to the message Pod for convenience. This will be null
  // until HelloWorldService is initialised.
  Pod<String>? get pMessage => _pAppServices.value.pHelloWorldService?.value.pMessage;

  // Create a message Snapshot. his will be null until HelloWorldService is
  // initialised.
  String? _messageSnapshot() => pMessage?.value;

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.brown.shade200,
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          const Text('PodListCallbackBuilder Test'),
          PodListCallbackBuilder(
            podListCallback: _messageCallback,
            builder: (context, values, child) {
              final message = _messageSnapshot();
              if (message == null) {
                return const CircularProgressIndicator();
              }
              return Column(
                children: [
                  Text(message),
                  OutlinedButton(
                    onPressed: () {
                      pMessage!.update((e) => e.substring(0, max(e.length - 1, 0)));
                    },
                    child: const Text('Backspace'),
                  ),
                ],
              );
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
    super.dispose();
    _pAppServices.dispose();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class AppServices with PodServiceMixin {
  Pod<HelloWorldService>? pHelloWorldService;
  @override
  servicePods() {
    return [
      pHelloWorldService = Pod(HelloWorldService()),
    ];
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class HelloWorldService with PodServiceMixin {
  Timer? _timer;
  Pod<String>? pMessage;

  @override
  void initService() {
    super.initService();
    _timer = Timer.periodic(const Duration(seconds: 2), _updateMessage);
  }

  void _updateMessage(Timer timer) {
    pMessage?.update((e) => '$e, ${timer.tick}');
  }

  @override
  dataPods() {
    return [
      pMessage = Pod<String>('Hello World!'),
    ];
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
    _timer = null;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

mixin PodServiceMixin {
  List<Pod<PodServiceMixin>?>? _servicePods;
  List<Pod?>? _dataPods;

  List<Pod> dataPods() => [];
  List<Pod<PodServiceMixin>> servicePods() => [];

  void initService() {
    dispose();
    _dataPods = dataPods();
    _servicePods = servicePods();
    for (final servicePod in _servicePods!) {
      servicePod!.value.initService();
    }
  }

  @mustCallSuper
  void dispose() {
    if (_dataPods != null) {
      for (var pod in _dataPods!) {
        pod?.dispose();
        pod = null;
      }
    }
    if (_servicePods != null) {
      for (var servicePod in _servicePods!) {
        servicePod?.value.dispose();
        servicePod?.dispose();
        servicePod = null;
      }
    }
  }
}
