//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file located in this project's root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:flutter/foundation.dart';

import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Manages the lifecycle of Pods and dependent services, ensuring proper
/// initialization and disposal.
abstract class PodService {
  //
  //
  //

  /// Gets all the initialised Data Pods of this service.
  Map<dynamic, GenericPod<dynamic>> get dataPods {
    return Map.unmodifiable(_dataPods);
  }

  Map<dynamic, GenericPod<dynamic>> _dataPods = {};

  /// Gets all the initialised child service Pods of this service.
  Map<dynamic, GenericPod<PodService>> get childServicePods {
    return Map.unmodifiable(_childServicePods);
  }

  Map<dynamic, GenericPod<PodService>> _childServicePods = {};

  /// Returns `true` if initialized via [initService], or `false` by default or
  /// if disposed via [closeService].
  bool get isInitialised => _isInitialised;

  bool _isInitialised = false;

  /// Creates an instance of [PodService] and immediately calls [initService]
  /// to initialize all necessary pods and sub-services.
  PodService() {
    initService();
  }

  /// Creates an instance of [PodService] without calling [initService],
  /// allowing for deferred initialization.
  @visibleForTesting
  PodService.defer();

  /// If [key] is not provided, retrieves the first Pod of type [P] from
  /// [provideDataPods] and [provideDataPodsAsMap]. If [key] is provided, it
  /// returns the Pod associated with that key from [provideDataPodsAsMap].
  P getDataPod<P extends GenericPod<dynamic>>([dynamic key]) {
    if (key != null) {
      return _dataPods[key] as P;
    } else {
      return _dataPods.values.whereType<P>().first;
    }
  }

  /// If [key] is not provided, retrieves the first Pod of type [P] from
  /// [provideChildServicePods] and [provideChildServicePodsAsMap]. If [key] is
  /// provided, it returns the Pod associated with that key from
  /// [provideChildServicePodsAsMap].
  P getChildServicePod<P extends GenericPod<PodService>>([dynamic key]) {
    if (key != null) {
      return _childServicePods[key] as P;
    } else {
      return _childServicePods.values.whereType<P>().first;
    }
  }

  /// Override to specify the data pods that should be provided by this
  /// service.
  /// ---
  /// ### Example:
  /// ```dart
  /// late RootPod<User?> pUser;
  /// late ChildPod<User?, String?> pToken;
  /// late ChildPod<String?, bool> pIsLoggedIn;
  ///
  /// provideDataPods() => {
  ///   pUser = Pod<User?>(null),
  ///   pToken = pUser.map((e) => e?.token),
  ///   pIsLoggedIn = pToken.map((e) => e.token != null && e.token.isNotEmpty),
  /// };
  ///
  ///
  /// // This will get the first Pod returned by [provideDataPods] of type
  /// // `RootPod<User?>`
  /// RootPod<User?> get getUserPod() => getDataPod();
  /// ```
  Set<GenericPod<dynamic>> provideDataPods() => {};

  /// Override to specify the data pods that should be provided by this
  /// service.
  /// ---
  /// ### Example:
  /// ```dart
  /// RootPod<User?> get pUser => getDataPod(#pUser);
  ///
  /// provideDataPodsAsMap() => {
  ///   #pUser: Pod<User?>(null),
  /// };
  /// ```
  ///
  /// You may also wish to use the alternative method, [provideDataPods].
  Map<dynamic, GenericPod<dynamic>> provideDataPodsAsMap() => {};

  /// Override to provide child services that depend on this service.
  /// These services have a lifecycle tied to this service.
  ///
  /// You may also wish to use the alternative method,
  /// [provideChildServicePodsAsMap].
  Set<GenericPod<PodService>> provideChildServicePods() => {};

  /// Override to provide child services that depend on this service.
  /// These services have a lifecycle tied to this service.
  ///
  /// You may also wish to use the alternative method,
  /// [provideChildServicePods].
  Map<dynamic, GenericPod<PodService>> provideChildServicePodsAsMap() => {};

  /// Initializes the service by setting up every Pod from [provideDataPods]
  /// and [provideDataPodsAsMap] and ever service from
  /// [provideChildServicePods] and [provideChildServicePodsAsMap]. This method
  /// should be called before using the service to ensure that all dependencies
  /// are properly initialized.
  ///
  /// Sets [isInitialised] to `true` upon successful completion.
  @nonVirtual
  @mustCallSuper
  void initService() {
    assert(
      !_isInitialised,
      '[PodService] Ensure closeService() is called before initService().',
    );
    if (!_isInitialised) {
      _init();
    }
  }

  void _init() {
    _close();
    _dataPods = _mergeCollections<GenericPod<dynamic>>(
      provideDataPods(),
      provideDataPodsAsMap(),
    );
    _childServicePods = _mergeCollections<GenericPod<PodService>>(
      provideChildServicePods(),
      provideChildServicePodsAsMap(),
    );
    for (final servicePod in _childServicePods.values) {
      servicePod.value.initService();
    }
    _isInitialised = true;
    onInitService();
  }

  /// Override to specify what should happen immediately after this service
  /// has been successfully initialized via [initService].
  void onInitService() {}

  /// Disposes every Pod from [provideDataPods] and [provideDataPodsAsMap] and
  /// every child service from [provideChildServicePods] and
  /// [provideChildServicePodsAsMap].
  @nonVirtual
  @mustCallSuper
  void closeService() {
    assert(
      _isInitialised,
      '[PodService] Ensure initService() is called before closeService().',
    );
    if (_isInitialised) {
      _close();
    }
  }

  void _close() {
    if (_dataPods.isNotEmpty) {
      for (var dataPod in _dataPods.values) {
        dataPod.dispose();
      }
      _dataPods.clear();
    }
    if (_childServicePods.isNotEmpty) {
      for (var servicePod in _childServicePods.values) {
        servicePod.value.closeService();
        servicePod.dispose();
      }
      _childServicePods.clear();
    }
    _isInitialised = false;
    onCloseService();
  }

  /// Override to specify what should happen immediately after this service
  /// has been successfully closed via [closeService].
  void onCloseService() {}
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Combines an Iterable and a Map into a single Map, assigning each item
/// from the Iterable a unique key and preserving the original Map entries.
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
