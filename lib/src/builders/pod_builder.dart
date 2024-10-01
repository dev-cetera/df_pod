//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:flutter/foundation.dart' show ValueListenable;

import 'package:flutter/widgets.dart';

import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class PodBuilder<T> extends StatelessWidget {
  //
  //
  //

  final FutureListenable<T> pod;

  //
  //
  //

  final TOnValueBuilder<T?, PodBuilderSnapshot<T>> builder;

  //
  //
  //

  final Widget? child;

  //
  //
  //

  final void Function(ValueListenable<T> pod)? onDispose;

  //
  //
  //

  const PodBuilder({
    super.key,
    required this.pod,
    required this.builder,
    this.child,
    this.onDispose,
  });

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    final temp = pod;
    if (temp is ValueListenable<T>) {
      return _PodBuilder(
        key: key,
        pod: temp,
        builder: builder,
        onDispose: onDispose,
        child: child,
      );
    }
    return FutureBuilder(
      future: temp,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data != null) {
          return _PodBuilder(
            key: key,
            pod: data,
            builder: builder,
            onDispose: onDispose,
            child: child,
          );
        } else {
          return builder(
            context,
            PodBuilderSnapshot<T>(
              pod: null,
              value: null,
              child: child,
            ),
          );
        }
      },
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class _PodBuilder<T> extends StatefulWidget {
  //
  //
  //

  final ValueListenable<T> pod;

  //
  //
  //

  final TOnValueBuilder<T?, PodBuilderSnapshot<T>> builder;

  //
  //
  //

  final Widget? child;

  //
  //
  //

  final void Function(ValueListenable<T> pod)? onDispose;

  //
  //
  //

  const _PodBuilder({
    super.key,
    required this.pod,
    required this.builder,
    this.child,
    this.onDispose,
  });

  //
  //
  //

  @override
  State<_PodBuilder<T>> createState() => _PodBuilderState<T>();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class _PodBuilderState<T> extends State<_PodBuilder<T>> {
  //
  //
  //

  late final Widget? _staticChild;
  late T _value;

  //
  //
  //

  @override
  void initState() {
    super.initState();
    _staticChild = widget.child;
    _value = widget.pod.value;
    widget.pod.addListener(_valueChanged!);
  }

  //
  //
  //

  @override
  void didUpdateWidget(_PodBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pod != widget.pod) {
      oldWidget.pod.removeListener(_valueChanged!);
      _value = widget.pod.value;
      widget.pod.addListener(_valueChanged!);
    }
  }

  //
  //
  //

  // ignore: prefer_final_fields
  late void Function()? _valueChanged = () {
    if (mounted) {
      setState(() {
        _value = widget.pod.value;
      });
    }
  };

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    final snapshot = PodBuilderSnapshot(
      pod: widget.pod,
      value: _value,
      child: _staticChild,
    );
    final result = widget.builder(context, snapshot);
    return result;
  }

  //
  //
  //

  @override
  void dispose() {
    widget.pod.removeListener(_valueChanged!);
    _valueChanged = null;
    widget.onDispose?.call(widget.pod);
    super.dispose();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class PodBuilderSnapshot<T> extends OnValueSnapshot<T?> {
  //
  //
  //

  final ValueListenable<T>? pod;

  //
  //
  //

  PodBuilderSnapshot({
    required this.pod,
    required super.value,
    required super.child,
  });

  //
  //
  //

  bool get hasValue => pod != null;
}
