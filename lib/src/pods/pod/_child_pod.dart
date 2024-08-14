//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

part of 'parts.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class ChildPod<P, C> extends BindWithMixinPodNotifier<C> with BasePodMixin<C> {
  //
  //
  //

  final List<BindWithMixinPodNotifier<P>?> Function() responder;
  final C Function(List<P?> parentValues) reducer;

  //
  //
  //

  ChildPod({
    required this.responder,
    required this.reducer,
  }) : super(
          reducer(responder().map((p) => p?.value).toList()),
        ) {
    _initializeParents();
  }

  //
  //
  //

  ChildPod.temp({
    required this.responder,
    required this.reducer,
  }) : super.temp(
          reducer(responder().map((p) => p?.value).toList()),
        ) {
    _initializeParents();
  }

  //
  //
  //

  void _initializeParents() {
    final parents = responder();
    for (var parent in parents) {
      parent?._addChild(this);
      parent?.addListener(_refresh);
    }
  }

  //
  //
  //

  Future<void> _refresh() async {
    final parents = responder();
    final newValue = reducer(parents.map((p) => p?.value).toList());
    await _set(newValue);
  }

  //
  //
  //

  @override
  void dispose() {
    final parents = responder();
    for (var parent in parents) {
      parent?._removeChild(this);
      parent?.removeListener(_refresh);
    }
    super.dispose();
  }
}

// // ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

extension _AddOrRemoveChildren<T> on BindWithMixinPodNotifier<T> {
  //
  //
  //

  void _addChild(ChildPod child) {
    if (!child.responder().contains(this)) {
      throw WrongParentPodException();
    }
    if (_children.contains(child)) {
      throw ChildAlreadyAddedPodException();
    }
    addListener(child._refresh);
    _children.add(child);
  }

  //
  //
  //

  void _removeChild(ChildPod child) {
    final didRemove = _children.remove(child);
    if (!didRemove) {
      throw NoRemoveChildPodException();
    }
    removeListener(child._refresh);
  }
}
