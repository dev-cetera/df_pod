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

import 'package:flutter/foundation.dart';

import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Manages the lifecycle of Pods and dependent services, ensuring proper
/// initialization and disposal.
abstract class PodService {
  //
  //
  //

  /// Gets all the initialised Pods.
  Map<dynamic, GenericPod<dynamic>> get pods {
    return Map.unmodifiable(_pods);
  }

  Map<dynamic, GenericPod<dynamic>> _pods = {};

  /// Gets all the initialised services.
  Map<dynamic, PodService> get childServices {
    return Map.unmodifiable(_childServices);
  }

  Map<dynamic, PodService> _childServices = {};

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

  /// If [key] is not provided, retrieves the first Pod of type [TPod] from
  /// [providePods] and [providePodsAsMap]. If [key] is provided, it
  /// returns the Pod associated with that key from [providePodsAsMap].
  TPod getPod<TPod extends GenericPod<dynamic>>([dynamic key]) {
    if (key != null) {
      return _pods[key] as TPod;
    } else {
      return _pods.values.whereType<TPod>().first;
    }
  }

  /// If [key] is not provided, retrieves the first [TPodService] from
  /// [provideChildServices] and [provideChildServicesAsMap]. If [key] is
  /// provided, it returns the [TPodService] associated with that key from
  /// [provideChildServicesAsMap].
  TPodService getChildService<TPodService extends PodService>([dynamic key]) {
    if (key != null) {
      return _childServices[key] as TPodService;
    } else {
      return _childServices.values.whereType<TPodService>().first;
    }
  }

  /// Override to specify the Pods that should be provided by this [service.
  /// ---
  /// ### Example:
  /// ```dart
  /// late RootPod<User?> pUser;
  /// late ChildPod<User?, String?> pToken;
  /// late ChildPod<String?, bool> pIsLoggedIn;
  ///
  /// providePods() => {
  ///   pUser = Pod<User?>(null),
  ///   pToken = pUser.map((e) => e?.token),
  ///   pIsLoggedIn = pToken.map((e) => e.token != null && e.token.isNotEmpty),
  /// };
  ///
  ///
  /// // This will get the first Pod returned by [providePods] of type
  /// // `RootPod<User?>`
  /// RootPod<User?> get getUserPod() => getPod();
  /// ```
  Set<GenericPod<dynamic>> providePods() => {};

  /// Override to specify the Pods that should be provided by this
  /// service.
  /// ---
  /// ### Example:
  /// ```dart
  /// RootPod<User?> get pUser => getPod(#pUser);
  ///
  /// provideDataPodsAsMap() => {
  ///   #pUser: Pod<User?>(null),
  /// };
  /// ```
  ///
  /// You may also wish to use the alternative method, [providePods].
  Map<dynamic, GenericPod<dynamic>> providePodsAsMap() => {};

  /// Override to provide child services that depend on this service.
  /// These services have a lifecycle tied to this service.
  ///
  /// You may also wish to use the alternative method,
  /// [provideChildServicesAsMap].
  Set<PodService> provideChildServices() => {};

  /// Override to provide child services that depend on this service.
  /// These services have a lifecycle tied to this service.
  ///
  /// You may also wish to use the alternative method,
  /// [provideChildServices].
  Map<dynamic, PodService> provideChildServicesAsMap() => {};

  /// Initializes the service by setting up every Pod from [providePods]
  /// and [providePodsAsMap] and every service from [provideChildServices] and
  /// [provideChildServicesAsMap].
  ///
  /// This method should be called before using the service to ensure that all
  /// ependencies are properly initialized.
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
    _pods = _mergeCollections<GenericPod<dynamic>>(
      providePods(),
      providePodsAsMap(),
    );
    _childServices = _mergeCollections<PodService>(
      provideChildServices(),
      provideChildServicesAsMap(),
    );
    for (final servicePod in _childServices.values) {
      servicePod.initService();
    }
    _isInitialised = true;
    onInitService();
  }

  /// Override to specify what should happen immediately after this service
  /// has been successfully initialized via [initService].
  void onInitService() {}

  /// Disposes every Pod from [providePods] and [providePodsAsMap] and
  /// every child service from [provideChildServices] and
  /// [provideChildServicesAsMap].
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
    if (_pods.isNotEmpty) {
      for (var dataPod in _pods.values) {
        dataPod.dispose();
      }
      _pods.clear();
    }
    if (_childServices.isNotEmpty) {
      for (var servicePod in _childServices.values) {
        servicePod.closeService();
      }
      _childServices.clear();
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
