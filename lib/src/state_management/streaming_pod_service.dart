//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'dart:async';

import 'package:flutter/foundation.dart';

import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

abstract class StreamingPodService<TData> extends PodService {
  //
  //
  //

  StreamController<TData>? _streamController;
  StreamSubscription<TData>? _streamSubscription;

  /// Override to provide an input [Stream] for this service.
  Stream<TData> provideInputStream();

  /// Override to define error handling behavior. Call [closeService] to
  /// immediately shut down this service in response to [e].
  void onError(Object? e, void Function() closeService);

  /// Avoid using Streams directly with [StreamingPodService] to maintain
  /// consistent state management practices.
  @protected
  Stream<TData>? get stream => this._streamController?.stream;

  @override
  @nonVirtual
  // ignore: invalid_override_of_non_virtual_member
  void initService() {
    super.initService();
    if (!isInitialised) {
      _init();
    }
  }

  void _init() {
    _streamController = StreamController<TData>.broadcast();
    _streamSubscription = provideInputStream().listen(
      pushToStream,
      onError: (Object? e) {
        onError(e, this.closeService);
      },
      cancelOnError: false,
    );
  }

  /// Pushes [data] to this [stream] and calls [onPushToStream].
  @nonVirtual
  @mustCallSuper
  Future<void> pushToStream(TData data) async {
    _streamController!.add(data);
    onPushToStream(data);
  }

  /// Override to specify what should happen immediately after data has been,
  /// pushed to this [stream].
  void onPushToStream(TData data);

  @override
  @nonVirtual
  // ignore: invalid_override_of_non_virtual_member
  void closeService() {
    if (isInitialised) {
      _close();
    }
    super.closeService();
  }

  void _close() {
    _streamSubscription?.cancel();
    _streamController?.close();
  }
}
