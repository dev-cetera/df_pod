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

// TODO: Add a child class PodDataService designed to Stream data from backend and write data to backend
abstract class PodService<TKey> {
  //
  //
  //

  Map<dynamic, AnyPod> _dataPods = {};
  Map<dynamic, AnyPod<PodService>> _servicePods = {};

  P getDataPod<P extends AnyPod>([TKey? key]) {
    if (key != null) {
      return _dataPods[key] as P;
    } else {
      return _dataPods.values.whereType<P>().first;
    }
  }

  P getServicePod<P extends AnyPod<PodService>>([TKey? key]) {
    if (key != null) {
      return _servicePods[key] as P;
    } else {
      return _servicePods.values.whereType<P>().first;
    }
  }

  //
  //
  //

  Set<AnyPod> provideDataPods() => {};

  Map<dynamic, AnyPod> provideDataPodsAsMap() => {};

  Set<AnyPod<PodService>> provideServicePods() => {};

  Map<dynamic, AnyPod<PodService>> provideServicePodsAsMap() => {};

  //
  //
  //

  bool _isInitialised = false;

  bool get isInitialised => _isInitialised;

  //
  //
  //

  /// Creates an instance of [PodService] and immediately calls [initService]
  /// to initialize all necessary pods and sub-services.
  PodService() {
    this.initService();
  }

  /// Creates an instance of [PodService] without calling [initService],
  /// allowing for deferred initialization.
  PodService.defer();

  //
  //
  //

  /// Initializes the service by setting up all necessary [setDataPodsAsMap] and
  /// initialises all [setServicePods]. This method should be called before using
  /// the service to ensure that all dependencies are properly initialized.
  ///
  /// Sets [isInitialised] to `true` upon successful completion.
  @nonVirtual
  void initService() {
    assert(
      !_isInitialised,
      '[PodServiceMixin] Ensure dispose() is called before initService().',
    );
    if (!_isInitialised) {
      _initService();
    }
  }

  void _initService() {
    _dispose();
    _dataPods = _mergeCollections<AnyPod>(
      provideDataPods(),
      provideDataPodsAsMap(),
    );
    _servicePods = _mergeCollections<AnyPod<PodService>>(
      provideServicePods(),
      provideServicePodsAsMap(),
    );
    for (final servicePod in _servicePods.values) {
      servicePod.value.initService();
    }
    onInitService();
    _isInitialised = true;
  }

  void onInitService() {}

  //
  //
  //

  /// Disposes every Pod from [provideDataPods] and [provideDataPodsAsMap] and
  /// every Service from [provideServicePods] and [provideServicePodsAsMap].
  @nonVirtual
  void dispose() {
    assert(
      _isInitialised,
      '[PodServiceMixin] Ensure initService() is called before dispose().',
    );
    if (_isInitialised) {
      _dispose();
    }
  }

  void _dispose() {
    if (_dataPods.isNotEmpty) {
      for (var dataPod in _dataPods.values) {
        dataPod.dispose();
      }
      _dataPods.clear();
    }
    if (_servicePods.isNotEmpty) {
      for (var servicePod in _servicePods.values) {
        servicePod.value.dispose();
        servicePod.dispose();
      }
      _servicePods.clear();
    }
    _isInitialised = false;
  }

  onDispose() {}
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

Map<dynamic, TValue> _mergeCollections<TValue>(
  Iterable<TValue> iterable,
  Map<dynamic, TValue> map,
) {
  final result = Map<dynamic, TValue>.from(map);
  for (var value in iterable) {
    result[UniqueKey()] = value;
  }
  return result;
}
