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

import 'dart:async';

import '_dependency.dart';
import '_di_key.dart';
import '_exceptions.dart';
import '_type_safe_registry.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Shorthand for [DI.global].
DI get di => DI.global;

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A simple Dependencu Injection (DI) class for managing dependencies across
/// an application.
class DI {
  //
  //
  //

  /// Dependency registry.
  final registry = TypeSafeRegistry();

  /// Default global instance of the DI class.
  static final DI global = DI.newInstance();

  /// Creates a new instance of the DI class. Prefer using [global], unless
  /// there's a specific need for a separate instance.
  DI.newInstance();

  /// Registers the [dependency] under type [T] and the specified [key], or
  /// under [DIKey.defaultKey] if no key is provided.
  ///
  /// Optionally provide an [onUnregister] callback to be called on [unregister].
  ///
  /// Throws [DependencyAlreadyRegisteredException] if a dependency with the
  /// same type [T] and [key] already exists.
  void register<T>(
    FutureOr<T> dependency, {
    DIKey key = DIKey.defaultKey,
    void Function()? onUnregister,
  }) {
    if (dependency is T) {
      _register<T>(
        dependency,
        key: key,
        onUnregister: onUnregister,
      );
    } else {
      _register<Future<T>>(
        dependency,
        key: key,
        onUnregister: onUnregister,
      );
    }
  }

  /// Registers the [instantiator] function under type [T] and the specified
  /// [key], or under [DIKey.defaultKey] if no key is provided.
  ///
  /// The dependency will be instantiated via [instantiator] when and only when
  /// accessed for the first time.
  ///
  /// Optionally provide an [onUnregister] callback to be called on [unregister].
  ///
  /// Throws [DependencyAlreadyRegisteredException] if a dependency with the
  /// same type [T] and [key] already exists.
  void registerLazy<T>(
    FutureOr<T> Function() instantiator, {
    DIKey key = DIKey.defaultKey,
    void Function()? onUnregister,
  }) {
    if (instantiator is T Function()) {
      _register<T Function()>(
        instantiator,
        key: key,
        onUnregister: onUnregister,
      );
    } else if (instantiator is Future<T> Function()) {
      _register<Future<T> Function()>(
        instantiator,
        key: key,
        onUnregister: onUnregister,
      );
    }
  }

  void _register<T>(
    T dependency, {
    DIKey key = DIKey.defaultKey,
    void Function()? onUnregister,
  }) {
    final existingDependencies = registry.getAllDependenciesOfType<T>();
    final depMap = {for (var dep in existingDependencies) dep.key: dep};

    // Check if the dependency is already registered.
    if (depMap.containsKey(key)) {
      throw DependencyAlreadyRegisteredException(T, key);
    }

    // Store the dependency in the type map.
    final newDependency = Dependency<T>(
      dependency,
      key: key,
      unregister: onUnregister,
    );
    registry.setDependency<T>(key, newDependency);
  }

  /// A shorthand for [get], allowing you to retrieve a dependency using call
  /// syntax.
  T call<T>([
    DIKey key = DIKey.defaultKey,
  ]) {
    return get<T>() as T;
  }

  /// Calls [get] and returns the instance of type [T] if found, otherwise
  /// returns `null`.
  T? getOrNull<T>([
    DIKey key = DIKey.defaultKey,
  ]) {
    try {
      return get<T>(key) as T;
    } on DependencyNotFoundException {
      return null;
    }
  }

  /// Gets a dependency as a [Future] or [T], registered under type [T] and the
  /// specified [key], or under [DIKey.defaultKey] if no key is provided.
  ///
  /// If the dependency was registered lazily via [registerLazy] and is not yet
  /// instantiated, it will be instantiated. Subsequent calls  of [get] will
  /// return the already instantiated instance.
  ///
  /// Throws [DependencyNotFoundException] if the dependency is not found.
  FutureOr<T> get<T>([
    DIKey key = DIKey.defaultKey,
  ]) {
    final try1 = registry.getDependency<T>(key);
    if (try1 != null) {
      final dependency = try1.value;
      return dependency;
    }

    final try2 = registry.getDependency<Future<T>>(key);
    if (try2 != null) {
      final dependency = try2.value;
      dependency.then((e) {
        unregister<T>(key);
        register<T>(e);
      });
      return dependency;
    }

    final try3 = registry.getDependency<T Function()>(key);
    if (try3 != null) {
      final instantiator = try3.value;
      final dependency = instantiator();
      unregister<T>(key);
      register<T>(dependency);
      return dependency;
    }

    final try4 = registry.getDependency<Future<T> Function()>(key);
    if (try4 != null) {
      final instantiator = try4.value;
      final dependency = instantiator();
      unregister<T>(key);
      register<T>(dependency);
      dependency.then((e) {
        unregister<T>(key);
        register<T>(e);
      });
      return dependency;
    }

    throw DependencyNotFoundException(T, key);
  }

  /// Unregisters a dependency registered under type [T] and the
  /// specified [key], or under [DIKey.defaultKey] if no key is provided.
  ///
  /// Throws [DependencyNotFoundException] if the dependency is not found.
  void unregister<T>([
    DIKey key = DIKey.defaultKey,
  ]) {
    final a = registry.removeDependency<T>(key);
    if (a != null) return;
    final b = registry.removeDependency<Future<T>>(key);
    if (b != null) return;
    final c = registry.removeDependency<T Function()>(key);
    if (c != null) return;
    final d = registry.removeDependency<Future<T> Function()>(key);
    if (d != null) return;
    throw DependencyNotFoundException(T, key);
  }

  /// Clears all registered dependencies, calling the [unregister] callback for
  /// each one before removal.
  void clear() {
    for (var depMap in registry.pRegistry.value.values) {
      for (var dependency in depMap.values) {
        dependency.unregister?.call();
      }
    }
    registry.clearRegistry();
  }
}
