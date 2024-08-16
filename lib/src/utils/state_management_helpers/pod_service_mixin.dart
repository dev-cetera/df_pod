//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:flutter/foundation.dart';

import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

mixin PodServiceMixin {
  //
  //
  //

  List<AnyPod<PodServiceMixin>?>? _servicePods;
  List<AnyPod?>? _dataPods;

  //
  //
  //

  List<AnyPod> dataPods() => [];
  List<AnyPod<PodServiceMixin>> servicePods() => [];

  //
  //
  //

  void initService() {
    dispose();
    _dataPods = dataPods();
    _servicePods = servicePods();
    for (final servicePod in _servicePods!) {
      servicePod!.value.initService();
    }
  }

  //
  //
  //

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
