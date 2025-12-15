[![banner](https://github.com/dev-cetera/df_pod/blob/v0.18.13/doc/assets/banner.png?raw=true)](https://github.com/dev-cetera)

[![pub](https://img.shields.io/pub/v/df_pod.svg)](https://pub.dev/packages/df_pod)
[![tag](https://img.shields.io/badge/Tag-v0.18.13-purple?logo=github)](https://github.com/dev-cetera/df_pod/tree/v0.18.13)
[![buymeacoffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-FFDD00?logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/dev_cetera)
[![sponsor](https://img.shields.io/badge/Sponsor-grey?logo=github-sponsors&logoColor=pink)](https://github.com/sponsors/dev-cetera)
[![patreon](https://img.shields.io/badge/Patreon-grey?logo=patreon)](https://www.patreon.com/robelator)
[![discord](https://img.shields.io/badge/Discord-5865F2?logo=discord&logoColor=white)](https://discord.gg/gEQ8y2nfyX)
[![instagram](https://img.shields.io/badge/Instagram-E4405F?logo=instagram&logoColor=white)](https://www.instagram.com/dev_cetera/)
[![license](https://img.shields.io/badge/License-MIT-blue.svg)](https://raw.githubusercontent.com/dev-cetera/df_pod/main/LICENSE)

---

<!-- BEGIN _README_CONTENT -->

## ℹ️ Features

- **Monadic Safety**: Uses `Option` and `Result` from [df_safer_dart](https://pub.dev/packages/df_safer_dart) to explicitly handle loading, data, and error states, eliminating `null` checks.
- **Composable & Declarative**: Create derived state by mapping or reducing pods, with automatic updates when dependencies change.
- **Automatic Memory Management**: Weakly referenced listeners and automatic child pod disposal prevent memory leaks without manual cleanup.
- **Familiar API**: Extends `ValueNotifier` with enhanced capabilities, integrating seamlessly with Flutter's reactive model.
- **Specialized Builder Widgets**: Includes `PodBuilder`, `PodListBuilder`, and `PollingPodBuilder` for efficient UI updates.
- **Performance Controls**: Fine-tune UI rebuilds with `debounceDuration` and `cacheDuration`.
- **Persistent State**: Provides `SharedPod` helpers for easy state persistence with `SharedPreferences`.

## ℹ️ Core Concepts

The core unit of state is a **Pod**. By convention, pod variables are prefixed with `p` (e.g., `pCounter`, `pUser`) for easy identification.

- **`Pod<T>`**: A mutable `ValueListenable<T>` for root state, directly created and updated.
- **`ChildPod<T>`**: A read-only pod derived by mapping or reducing parent pods, updating automatically with parent changes.
- **`ReducerPod`**: A `ChildPod` that combines multiple parent pods, updating when any parent changes.
- **`PodBuilder`**: A widget that listens to a `Pod` and rebuilds the UI on value changes.
- **`PodListBuilder`**: A widget that listens to a list of pods, rebuilding when any pod changes.

## ℹ️ Quickstart

### 1. Define a Root Pod

A `Pod` holds mutable state, from simple values to complex objects.

```dart
final pCounter = Pod<int>(0);
final pItems = Pod<List<String>>(['Apple', 'Banana']);
```

### 2. Build UI with `PodBuilder`

`PodBuilder` listens to a pod and rebuilds the UI, handling synchronous pods, `Future<Pod>`, or error-throwing futures.

```dart
PodBuilder<int>(
  pod: pCounter,
  builder: (context, snapshot) {
    final count = snapshot.value.unwrap().unwrap();
    return Text('Count: $count');
  },
);
```

For asynchronous operations, `PodBuilder` manages loading, success, and error states.

```dart
Future<Pod<String>> fetchUser() async {
  await Future<void>.delayed(const Duration(seconds: 2));
  if (Random().nextBool()) {
    return Pod('Jane Doe');
  } else {
    throw Exception('Failed to load user.');
  }
}

PodBuilder<String>(
  pod: fetchUser(),
  builder: (context, snapshot) {
    final option = snapshot.value;
    if (option.isNone()) {
      return const CircularProgressIndicator();
    }
    final result = option.unwrap();
    if (result.isErr()) {
      final err = result.err().unwrap();
      return Text('Error: ${err.error}');
    }
    final ok = result.unwrap();
    return Text('Hello: $ok');
  },
),
```

### 3. Update a Pod's State

Modify a `Pod` using `.set()` or `.update()`. Listeners like `PodBuilder` or `ChildPod` react automatically.

```dart
pCounter.update((currentCount) => currentCount + 1);
pItems.set(['Orange', 'Grape']);
```

### 4. Create Derived State with `.map()` and `.reduce()`

Create a read-only `ChildPod` by transforming a parent pod.

```dart
final pItems = Pod<List<String>>(['Apple', 'Banana', 'Cherry']);
final pItemCount = pItems.map((itemList) => itemList.length);
final pCountMessage = pItemCount.map((count) => 'You have $count items.');

PodBuilder<String>(
  pod: pCountMessage,
  builder: (context, snapshot) => Text(snapshot.value.unwrap().unwrap()),
);
```

Use `ReducerPod` to combine multiple pods.

```dart
final pFirstName = Pod('John');
final pLastName = Pod('Doe');
final pFullName = pFirstName.reduce(
  pLastName,
  (first, last) => '${first.getValue()} ${last.getValue()}',
);

PodBuilder<String>(
  pod: pFullName,
  builder: (context, snapshot) {
    return Text('Full Name: ${snapshot.value.unwrap()}');
  },
);
```

## ℹ️ A Practical Example: Building a Search UI

### 1. Define Root State

Start with a root pod for the search query.

```dart
final pSearchQuery = Pod('');
```

### 2. Handle Async Operations and Errors

Use `PodBuilder` to handle asynchronous API calls, managing loading, success, and error states.

```dart
PodBuilder<List<String>>(
  pod: searchApi(query),
  builder: (context, snapshot) {
    if (snapshot.value.isNone()) {
      return const CircularProgressIndicator();
    }
    final result = snapshot.value.unwrap();
    if (result.isErr()) {
      final error = result.err().unwrap().error;
      return Text('Error: $error');
    }
    final products = result.unwrap();
    return ListView(children: [for (final product in products) Text(product)]);
  },
);
```

### 3. Create Derived State with `.map()` and `.reduce()`

Build reactive state declaratively.

```dart
final pLatestResults = Pod<List<String>>([]);
final pResultCount = pLatestResults.map((results) => results.length);
final pSummaryMessage = pResultCount.reduce(
  pSearchQuery,
  (count, query) {
    if (query.value.isEmpty) return 'Enter a search term.';
    return 'Found ${count.value} result(s) for "${query.value}".';
  },
);
```

### 4. Build UI from Multiple Pods with `PodListBuilder`

`PodListBuilder` efficiently handles multiple pods, rebuilding when any change.

```dart
PodListBuilder(
  podList: [pResultCount, pSummaryMessage],
  builder: (context, snapshot) {
    final values = snapshot.value.map((e) => e.unwrap());
    final [resultCount as int, summaryMessage as String] = values.toList();
    return Card(child: Text(message));
  },
);
```

For additional pods, such as cart or login status:

```dart
final pProductCount = Pod(10);
final pCartTotal = Pod(99.99);
final pIsLoggedIn = Pod(true);

PodListBuilder(
  podList: [pProductCount, pCartTotal, pIsLoggedIn],
  builder: (context, snapshot) {
    final values = snapshot.value.map((e) => e.unwrap()).toList();
    final count = values[0] as int;
    final total = values[1] as double;
    final loggedIn = values[2] as bool;
    if (!loggedIn) {
      return const Text('Please log in.');
    }
    return Text('You have $count items in your cart. Total: \$$total');
  },
);
```

### 5. Tune Performance with `debounceDuration` and `cacheDuration`

- **debounceDuration**: Delays updates to prevent rapid API calls.
- **cacheDuration**: Caches results for instant display, using a stable `Key`.

```dart
PodBuilder<String>(
  pod: pSearchQuery,
  // Even if pSearchQuery updates every millisecond, the builder will only update every 400ms.
  debounceDuration: const Duration(milliseconds: 400),
  builder: (context, querySnapshot) {
    final query = querySnapshot.value.unwrap().unwrap();
    if (query.isEmpty) return const Text('Enter a search term.');
    return PodBuilder<List<String>>(
      // A stable key is required for caching!
      key: ValueKey(query),
      pod: searchApi(query),
       // Results are cached for 2 minutes of inactivity:
      cacheDuration: const Duration(minutes: 2),
      builder: (context, resultsSnapshot) {
        // Handle loading/error/success
      },
    );
  },
);
```

## ℹ️ Advanced Features

### Automatic Memory Management

`df_pod` ensures safety and prevents leaks:

- **Automatic Listener Cleanup**: Listeners use `WeakReferences`. When a `PodBuilder` is removed from the widget tree, its listener is garbage collected automatically.
- **Automatic Child Disposal**: Disposing a parent pod disposes its derived children.

```dart
final pParent = Pod(0);
final pChild = pParent.map((value) => value * 2);
final pGrandChild = pChild.map((value) => value + 1);
pParent.dispose(); // Disposes pParent, pChild, and pGrandChild.
```

### The `addStrongRefListener` Method

For persistent listeners outside the UI, use `addStrongRefListener`, requiring manual removal.

```dart
void scope() {
  // This is a strong referenced callback. It is tied to myListener. When myListener goes out of scope, pMyPod will tell the garbage collector it's ready to be disposed of.
  final myListener = () => print('Pod changed!');
  pMyPod.addStrongRefListener(strongRefListener: myListener);

  // If you use anonymous functions or weak referenced functions, pMyPod will prematurely dispose these functions since they are not tied to a scope like myListener is.
  pMyPod.addStrongRefListener(strongRefListener: () {
     print('Anonymous weak referenced function!')
  });
  pMyPod.addStrongRefListener(strongRefListener: weakRefFunction);
}

// This is a weak reference.
void weakRefFunction() {
  print('Weak referenced functions should be avoided!')
}
```

**Rule of Thumb**: Use `PodBuilder` for UI; reserve `addStrongRefListener` for non-UI logic.

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

<!-- END _README_CONTENT -->

---

🔍 For more information, refer to the [API reference](https://pub.dev/documentation/df_pod/).

---

## 💬 Contributing and Discussions

This is an open-source project, and we warmly welcome contributions from everyone, regardless of experience level. Whether you're a seasoned developer or just starting out, contributing to this project is a fantastic way to learn, share your knowledge, and make a meaningful impact on the community.

### ☝️ Ways you can contribute

- **Find us on Discord:** Feel free to ask questions and engage with the community here: https://discord.gg/gEQ8y2nfyX.
- **Share your ideas:** Every perspective matters, and your ideas can spark innovation.
- **Help others:** Engage with other users by offering advice, solutions, or troubleshooting assistance.
- **Report bugs:** Help us identify and fix issues to make the project more robust.
- **Suggest improvements or new features:** Your ideas can help shape the future of the project.
- **Help clarify documentation:** Good documentation is key to accessibility. You can make it easier for others to get started by improving or expanding our documentation.
- **Write articles:** Share your knowledge by writing tutorials, guides, or blog posts about your experiences with the project. It's a great way to contribute and help others learn.

No matter how you choose to contribute, your involvement is greatly appreciated and valued!

### ☕ We drink a lot of coffee...

If you're enjoying this package and find it valuable, consider showing your appreciation with a small donation. Every bit helps in supporting future development. You can donate here: https://www.buymeacoffee.com/dev_cetera

<a href="https://www.buymeacoffee.com/dev_cetera" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" height="40"></a>

## LICENSE

This project is released under the [MIT License](https://raw.githubusercontent.com/dev-cetera/df_pod/main/LICENSE). See [LICENSE](https://raw.githubusercontent.com/dev-cetera/df_pod/main/LICENSE) for more information.
