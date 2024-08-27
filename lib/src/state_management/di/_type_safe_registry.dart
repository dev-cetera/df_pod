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

import '/src/_index.g.dart';

import '_dependency.dart';
import '_di_key.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A type-safe registry for storing and managing dependencies of various types
/// within [DI]. This class provides methods for adding, retrieving, updating,
/// and removing dependencies, as well as checking if a specific dependency
/// exists.
final class TypeSafeRegistry {
  //
  //
  //

  /// Dependencies, organized by their type.
  final _pRegistry = Pod<Map<Type, DependencyMap<dynamic>>>({});

  P<Map<Type, DependencyMap<dynamic>>> get pRegistry => _pRegistry;

  TypeSafeRegistry();

  /// Retrieves a dependency of type [T] with the specified [key].
  ///
  /// Returns the dependency of type [T] if found, otherwise returns `null`.
  Dependency<T>? getDependency<T>(DIKey key) {
    return _pRegistry.value[T]?[key] as Dependency<T>?;
  }

  /// Adds or updates a dependency of type [T] with the specified [key].
  ///
  /// If a dependency with the same type [T] and [key] already exists, it will
  /// be overwritten.
  void setDependency<T>(DIKey key, Dependency<T> dependency) {
    final deps = getDependencyMap<T>() ?? <DIKey, Dependency<T>>{};
    deps[key] = dependency;
    setDependencyMap<T>(deps);
  }

  /// Removes a dependency of type [T] with the specified [key].
  ///
  /// Returns the removed dependency if it existed, otherwise returns `null`.
  Dependency<T>? removeDependency<T>(DIKey key) {
    final typeMap = getDependencyMap<T>();
    if (typeMap != null) {
      final removed = typeMap.remove(key);
      if (typeMap.isEmpty) {
        removeDependencyMap<T>();
      } else {
        setDependencyMap<T>(typeMap);
      }
      return removed;
    }
    return null;
  }

  /// Checks if a dependency of type [T] with the specified [key] exists.
  ///
  /// Returns `true` if the dependency exists, otherwise `false`.
  bool containsDependency<T>(DIKey key) {
    return getDependencyMap<T>()?.containsKey(key) ?? false;
  }

  /// Retrieves all dependencies of type [T].
  ///
  /// Returns an iterable of all registered dependencies of type [T]. If none
  /// exist, an empty iterable is returned.
  Iterable<Dependency<dynamic>> getAllDependenciesOfType<T>() {
    return getDependencyMap<T>()?.values ?? const Iterable.empty();
  }

  /// Sets the map of dependencies for type [T].
  ///
  /// This method is used internally to update the stored dependencies for a
  /// specific type [T].
  void setDependencyMap<T>(DependencyMap<T> deps) {
    _pRegistry.update((e) => e..[T] = deps);
  }

  /// Retrieves the map of dependencies for type [T].
  ///
  /// Returns the map of dependencies for the specified type [T], or `null` if
  /// no dependencies of this type are registered.
  DependencyMap<T>? getDependencyMap<T>() {
    return _pRegistry.value[T] as DependencyMap<T>?;
  }

  /// Removes the entire map of dependencies for type [T].
  ///
  /// This method is used internally to remove all dependencies of a specific
  /// type [T].
  void removeDependencyMap<T>() {
    _pRegistry.update((e) => e..remove(T));
  }

  /// Clears all registered dependencies.
  ///
  /// This method removes all entries from the registry, effectively resetting
  /// it.
  void clearRegistry() {
    _pRegistry.set({});
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Type alias for a map of dependencies, keyed by [DIKey].
typedef DependencyMap<T> = Map<DIKey, Dependency<T>>;
