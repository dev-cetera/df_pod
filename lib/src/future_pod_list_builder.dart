//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. See LICENSE file
// in root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'dart:async';

import 'package:flutter/widgets.dart';

import '_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class FuturePodListBuilder<T> extends StatelessWidget {
  //
  //
  //

  final List<FutureOr<PodListenable<T>?>?> podList;

  //
  //
  //

  final Widget Function(
    BuildContext context,
    Widget? child,
    TPodDataList data,
  ) builder;

  //
  //
  //

  final Widget? child;

  //
  //
  //

  final void Function()? onDispose;

  //
  //
  //

  const FuturePodListBuilder({
    super.key,
    required this.podList,
    required this.builder,
    this.child,
    this.onDispose,
  });

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: () async {
        return await Future.wait(this.podList.map((e) => () async {
              return e;
            }()));
      }(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data != null) {
          return PodListBuilder(
            podList: data,
            builder: builder,
            onDispose: onDispose,
            child: child,
          );
        } else {
          return builder(
            context,
            child,
            List<T?>.filled(podList.length, null),
          );
        }
      },
    );
  }
}
