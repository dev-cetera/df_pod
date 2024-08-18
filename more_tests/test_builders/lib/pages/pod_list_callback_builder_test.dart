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
      _pAppServices.value.pHelloWorldService.value.pMessage,
    ];
  }

  // Create a shortcut to the message Pod for convenience. This will be null
  // until HelloWorldService is initialised.
  Pod<String>? get pMessage => _pAppServices.value.pHelloWorldService.value.pMessage;

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
            listCallback: _messageCallback,
            builder: (context, snapshot) {
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

class AppServices extends PodService {
  late Pod<HelloWorldService> pHelloWorldService;
  @override
  provideDataPods() {
    return {
      pHelloWorldService = Pod(HelloWorldService()),
    };
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class HelloWorldService extends PodService {
  Timer? _timer;
  late Pod<String> pMessage;

  @override
  void onInitService() {
    _timer = Timer.periodic(const Duration(seconds: 2), _updateMessage);
  }

  void _updateMessage(Timer timer) {
    pMessage.update((e) => '$e, ${timer.tick}');
  }

  @override
  provideDataPods() {
    return {
      pMessage = Pod<String>('Hello World!'),
    };
  }

  @override
  void onDispose() {
    _timer?.cancel();
    _timer = null;
  }
}
