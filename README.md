<a href="https://www.buymeacoffee.com/dev_cetera" target="_blank"><img align="right" src="https://cdn.buymeacoffee.com/buttons/default-orange.png" height="48"></a>
<a href="https://discord.gg/gEQ8y2nfyX" target="_blank"><img align="right" src="https://raw.githubusercontent.com/dev-cetera/resources/refs/heads/main/assets/discord_icon/discord_icon.svg" height="48"></a>

Dart & Flutter Packages by dev-cetera.com & contributors.

[![Pub Package](https://img.shields.io/pub/v/df_pod.svg)](https://pub.dev/packages/df_pod)
[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](https://raw.githubusercontent.com/dev-cetera/df_pod/main/LICENSE)

---

// #df_pod

## Summary

This package provides tools for managing app state using ValueNotifier like objects called Pods. For a practical demonstration of how Pods work in conjunction with [GetIt](https://pub.dev/packages/get_it) for state management, refer to [this example](https://pub.dev/packages/df_pod/example). For a full feature set, please refer to the [API reference](https://pub.dev/documentation/df_pod/).

## Quickstart

### ℹ️ Defining a Pod:

```dart
// Define a Pod, similar to how you would define a ValueNotifier.
final pNumbers = Pod<List<int>>([1, 2, 3, 4, 5]);
```

### ℹ️ Using a PodBuilder in the UI:

```dart
final pNumbers = Pod<List<int>>([1, 2, 3, 4, 5]);

// Use the PodBuilder in your UI, similar to a ValueListenableBuilder.
PodBuilder(
  pod: pNumbers,
  builder: (context, snapshot) {
    final numbers = snapshot.value!;
    return Text('Count: ${numbers.length}');
  },
);

// You can also use a regular old ValueListenableBuilder.
ValueListenableBuilder(
  valueListenable: _pCounter1,
  builder: (context, value, child) {
    return Text('Count: $value');
  },
);
```

### ℹ️ Using PodBuilder with Futures:

```dart
// PodBuilders can also take Futures.
final pNumbers = Future.delayed(const Duration(seconds: 3), () => Pod<int>(1));

PodBuilder(
  pod: pNumbers,
  builder: (context, snapshot) {
    final numbers = snapshot.value;
    final completed = numbers != null;
    if (completed) {
      return Text('Count: ${numbers.length}');
    } else {
      return Text('Loading...');
    }
  },
);
```

### ℹ️ Setting and Updating a Pod:

```dart
final pNumbers = Pod<List<int>>([1, 2, 3, 4, 5]);

// Set a Pod with the set function. This will trigger all associated PodBuilders to rebuild.
pNumbers.set([1, 2, 4]);

// Update a Pod with the update function. This will also trigger all associated PodBuilders to rebuild.
pNumbers.update((e) => e..add(5));
```

### ℹ️ Disposing of Pods:

```dart
final pNumbers = Pod<List<int>>([1, 2, 3, 4, 5]);

// Manually dispose of Pods when they are no longer needed.
pNumbers.dispose();
```

### ℹ️ PodBuilder Optimization:

```dart
// If the Pod<T> type T is a primitive type or implements Equatable*,
// the PodBuilder will only rebuild if the Pod's value actually changed.
final pHelloWorld = Pod('Hello World');

// This will NOT trigger a rebuild, as String is a primitive, pass-by-value type.
pHelloWorld.set('Hello World');
```

_\* Find the Equatable package here: https://pub.dev/packages/equatable_

### ℹ️ Transforming a Pod into a ChildPod:

```dart
final pNumbers = Pod<List<int>>([1, 2, 3, 4, 5]);

// A Pod can be transformed into a ChildPod using the map function.
final pLength = pNumbers.map((e) => e!.length);

final ChildPod<List<int>, int> pSum = pNumbers.map((e) => e!.reduce((a, b) => a + b));

PodBuilder(
  pod: pSum,
  // Changing pNumbers will trigger a rebuild.
  builder: (context, snapshot) {
    final sum = snapshot.value!;
    return Text('Sum: ${sum}');
  },
);
```

### ℹ️ Further Mapping a ChildPod:

```dart
final pNumbers = Pod<List<int>>([1, 2, 3, 4, 5]);
final pLength = pNumbers.map((e) => e!.length);

// A ChildPod can be further mapped into another ChildPod.
final pInverseLength = pLength.map((e) => 1 / e!);
```

### ℹ️ Reducing Multiple Pods into a ChildPod:

```dart
final pNumbers = Pod<List<int>>([1, 2, 3, 4, 5]);
final pLength = pNumbers.map((e) => e!.length);
final pInverseLength = pLength.map((e) => 1 / e!);

// Pods can also be reduced into a single ChildPod:
final pZero = pLength.reduce(pInverseLength, (p1, p2) => p1.value * p2.value);
```

### ℹ️ Restrictions on ChildPods:

```dart

final Pod<String> pParent = Pod('I am a Parent');

pParent.update((e) => e.replaceAll('Parent', 'Father')); // ✔️ OK!

final ChildPod<String, String> pChild = pParent.map((e) => e.replaceAll('Father', 'Son'));

// A ChildPod cannot be set or updated directly. When its parent changes,
// its value is immediately updated from its mapping function.
pChild.update((e) => e.replaceAll('Son', 'Daughter')); // ❌ Syntax error!

// Attempting to add listeners or dispose of a ChildPod will result in a syntax
// error if you've set the `protected_member` rule in your
// `analysis_options.yaml` file. This design eliminates the need for direct
// disposal of a ChildPod via the dispose() method.

final listener = () => print('Something changed!');

// These will trigger syntax errors if you've correctly set up your
// analysis_options.yaml:
pChild.addStrongRefListener(strongRefListener: listener); // ❌ ChildPods do not take listeners!


pParent.addStrongRefListener(strongRefListener: listener); // ✔️ OK!
pParent.dispose(); // ✔️ OK! Disposes pChild as well, its children, their children, and so on.
```

### ℹ️ Using Multiple Pods with PodListBuilder:

```dart
// You can use multiple Pods with a PodListBuilder.
PodListBuilder(
  podList: [pLength, pSum],
  builder: (context, snapshot) {
    final [length, sum] = snapshot.value!.toList();
    return Text('Length is $length and sum is $sum');
  },
);
```

### ℹ️ Using PollingPodBuilder for Nullable Pods:

```dart
// Use a PollingPodBuilder when your Pod is initially nullable and will soon be updated to a non-null value.
// This approach is useful for prototyping and quick demonstrations but is not recommended for production code.
// The [podPoller] function is called periodically until it returns a non-null value.

Pod<List<int>>? pNumbers;

PollingPodBuilder(
  podPoller: () => pNumbers,
  builder: (context, snapshot) {
    final numbers = snapshot.value!;
    return Text('Count: ${numbers.length}');
  },
);

pNumbers = Pod<List<int>>([1, 2, 3, 4, 5]);
```

## Pod Type Hierarchy

THe following diagram illustrates how the different Pods are linked to each other and other widgets. An equal amount of "+" means the same hierarchical level. More "+" means lower down in the hierarchy and less "+" means higher up the hierarchy.

```txt
+ EasyPod
+ Listenable
+++ WeakChangeNotifier
+++ ValueListenable
+++++ DisposablePod and ProtectedPodMixin
+++++++ PodNotifier and GenericPodMixin (GenericPod)
+++++++++ _ChildPodBase
+++++++++++ ChildPod
+++++++++ RootPod
+++++++++++ SharedPod
+++++++++++++ SharedProtectedPod
+++++++++ ReducerPod
+++++++++ SafeFuturePod
```

## ⚠️ Installation & Setup

1. Use this package as a dependency by adding it to your `pubspec.yaml` file (see [here](https://pub.dev/packages/df_pod/install)).

2. Update your `analysis_options.yaml` to the following. This is highly recommended because:

- `prefer_function_declarations_over_variables: false`: The `addStrongRefListener` method requires a strong referenced variable function as an argument, so that it can be garbage collected automatically, and disabling this rule will prevent warnings.

- `invalid_use_of_protected_member: error`: Certain methods in this package are protected to ensure they are only used within controlled contexts, preserving the integrity and consistency of the state management pattern. Enforcing this rule helps prevent misuse that could lead to unexpected behavior or security issues.

- `invalid_override_of_non_virtual_member: error`: Non-virtual members are not designed to be overridden, as doing so could compromise the internal logic and functionality of the service. Enforcing this rule ensures that the core behavior of the package remains stable and predictable, preventing accidental or unauthorized changes.

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_function_declarations_over_variables: false

analyzer:
  errors:
    invalid_use_of_protected_member: error
    invalid_override_of_non_virtual_member: error
```

---

## Contributing and Discussions

This is an open-source project, and we warmly welcome contributions from everyone, regardless of experience level. Whether you're a seasoned developer or just starting out, contributing to this project is a fantastic way to learn, share your knowledge, and make a meaningful impact on the community.

### Ways you can contribute:

- **Buy me a coffee:** If you'd like to support the project financially, consider [buying me a coffee](https://www.buymeacoffee.com/dev_cetera). Your support helps cover the costs of development and keeps the project growing.
- **Share your ideas:** Every perspective matters, and your ideas can spark innovation.
- **Report bugs:** Help us identify and fix issues to make the project more robust.
- **Suggest improvements or new features:** Your ideas can help shape the future of the project.
- **Help clarify documentation:** Good documentation is key to accessibility. You can make it easier for others to get started by improving or expanding our documentation.
- **Write articles:** Share your knowledge by writing tutorials, guides, or blog posts about your experiences with the project. It's a great way to contribute and help others learn.

No matter how you choose to contribute, your involvement is greatly appreciated and valued!

### Discord Server

Feel free to ask questions and engage with the community here: https://discord.gg/gEQ8y2nfyX

## Chief Maintainer:

📧 Email _Robert Mollentze_ at robmllze@gmail.com

## Dontations:

If you're enjoying this package and find it valuable, consider showing your appreciation with a small donation. Every bit helps in supporting future development. You can donate here:

https://www.buymeacoffee.com/dev_cetera

## License

This project is released under the MIT License. See [LICENSE](https://raw.githubusercontent.com/dev-cetera/df_pod/main/LICENSE) for more information.
