//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

part of 'pod.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class ChildPod<A, B> extends Pod<B> {
  //
  //
  //

  final List<Pod<A>> parents;
  final B Function(List<A> parentValues) reducer;
  final List<A> Function(List<A> parentValues, B childValue)? updateParents;

  //
  //
  //

  ChildPod({
    required this.parents,
    required this.reducer,
    required this.updateParents,
  }) : super(
          reducer(parents.map((p) => p.value).toList()),
        ) {
    for (var parent in parents) {
      parent._addChild(this);
      parent.addListener(refresh);
    }
  }

  //
  //
  //

  ChildPod.temp({
    required this.parents,
    required this.reducer,
    required this.updateParents,
  }) : super.temp(
          reducer(parents.map((p) => p.value).toList()),
        ) {
    for (var parent in parents) {
      parent._addChild(this);
      parent.addListener(refresh);
    }
  }

  //
  //
  //

  @override
  Future<void> refresh() async {
    final newValue = reducer(parents.map((p) => p.value).toList());
    await set(newValue);
  }

  //
  //
  //

  @override
  void notifyListeners() {
    super.notifyListeners();
    if (this.updateParents != null) {
      final oldParentValues = parents.map((e) => e.value).toList();
      final newParentValues = updateParents!(oldParentValues, value);
      for (var n = 0; n < parents.length; n++) {
        parents.elementAt(n).set(newParentValues.elementAt(n));
      }
    }
  }

  //
  //
  //

  @override
  void dispose() {
    for (var parent in parents) {
      parent._removeChild(this);
      parent.removeListener(refresh);
    }
    super.dispose();
  }
}
