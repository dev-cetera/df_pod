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

class FuturePodBuilder<T> extends StatelessWidget {
  //
  //
  //

  final FutureOr<PodListenable<T>?>? pod;

  //
  //
  //

  final Widget Function(
    BuildContext context,
    Widget? child,
    T? data,
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

  const FuturePodBuilder({
    super.key,
    this.pod,
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
        return await pod;
      }(),
      builder: (context, snapshot) {
        return PodBuilder(
          pod: snapshot.data,
          builder: builder,
          onDispose: onDispose,
          child: child,
        );
      },
    );
  }
}
