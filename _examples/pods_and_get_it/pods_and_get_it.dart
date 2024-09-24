// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// State Management Example using Pods and GetIt. This example is presented
// in a single file for simplicity, but in a real project, the code would be
// organized across multiple files to maintain clarity and scalability.
// This code can be easily integrated with GoRouter or other routing solutions
// in your Flutter application.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

import 'package:df_pod/df_pod.dart';
import 'package:get_it/get_it.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// 1. Create the pages for your app, for example:
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. Create an "Interpreted Builder" for your page. This is a wrapper
    // that binds the "Page Interpreter" with your page. Continue reading to
    // understand the purpose of the Interpreter.
    return HomePageInterpretedBuilder(
      builder: (context, interpreter) {
        return Column(
          children: [
            // 3. Use the Pods provided by the Interpreter here. Pods are like
            // ValueNotifiers, and PodBuilder functions similarly to a
            // ValueListenableBuilder.
            PodBuilder(
              pod: interpreter.pUserId,
              builder: (context, userIdSnapshot) {
                return Text('UserId: ${userIdSnapshot.value}');
              },
            ),
            // 4. It's generally recommended to avoid placing logic directly
            // within your Page widget, but if necessary, you can use a
            // PodListBuilder like this:
            PodListBuilder(
              podList: [
                interpreter.pConnectionCount,
                interpreter.pNotificationCount,
              ],
              builder: (context, podListSnapshot) {
                final [connectionCount!, notificationCount!] = podListSnapshot.value.toList();
                final notificationRatio = notificationCount / connectionCount;
                return Text('Notification ratio: $notificationRatio');
              },
            ),
            // 5. You way want to consider placing all the logic in the Services
            // or Interpreter instead, to maintain clearer separation between
            // logic and UI code.
            PodBuilder(
              pod: interpreter.pNotificationRatio,
              builder: (context, notificationRatioSnapshot) {
                return Text(
                  'Notification ratio: ${notificationRatioSnapshot.value}',
                );
              },
            ),
            // 6. The above examples show how to bring "Points of Data" (PODS)
            // into the UI. If you need to send updates back to the Services,
            // you can access the Interpreter's Services and invoke their
            // methods:
            OutlinedButton(
              onPressed: () {
                interpreter.authService.login();
              },
              child: const Text('Login'),
            ),
            OutlinedButton(
              onPressed: () {
                interpreter.authService.logout();
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// 7. Create an Interpreted Builder for your page. This widget passes a specific
// Interpreter to a builder function, simplifying the connection between your
// page and its associated data.
class HomePageInterpretedBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    HomePageInterpreter interpreter,
  ) builder;

  const HomePageInterpretedBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return builder(
      context,
      HomePageInterpreter(
        OtherInterpreter(),
        GetIt.I<AuthService>(),
        GetIt.I<ConnectionService>(),
        GetIt.I<NotificationService>(),
      ),
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// 8. Create an Interpreter. An Interpreter is a class that interprets Services
// and consolodates/transforms their Pods via mapping or reduction, into simpler
// Pods, that we can directly use in the Page.
class HomePageInterpreter {
  // 9. You can also combine interpreters by passing another interpreter
  // to the constructor.
  final OtherInterpreter otherInterpreter;
  final AuthService authService;
  final ConnectionService connectionService;
  final NotificationService notificationService;

  HomePageInterpreter(
    this.otherInterpreter,
    this.authService,
    this.connectionService,
    this.notificationService,
  );

  // 10. Simplify Pods from Services so the relevant Page can use them
  // without needing to simplify them in the widget code.
  late final pUserId = authService.pUser.map((e) => e!.id);
  late final pNotificationCount = notificationService.pNotifications.map((e) => e!.length);
  late final pConnectionCount = connectionService.pConnections.map((e) => e!.length);
  late final pNotificationRatio =
      pNotificationCount.reduce(pConnectionCount, (a, b) => a.value / b.value);
  late final pPriorityNotifications =
      notificationService.pNotifications.map((e) => e!.where((e) => e.startsWith('priority:')));

  // 11. Avoid putting anything but Pods such as methods in the Interpreter. The
  // Interpreter is not a Controller. Its sole purpose is to interpret Services
  // and produce Pods for the relevant Page to use.
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class OtherInterpreter {}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// 12. Define your Services within your app, typically in a directory like
// 'lib/src/services'. Services are responsible for handling the core features
// of your app, such as authentication, push notifications, messaging, API calls,
// and more. The majority of your app's logic should be encapsulated within
// these services. Services manage Pods, which they automatically update
// throughout their lifecycle based on incoming data, state changes, and other
// factors. Interpreters then transform and combine Pods from one or more
// services into simplified Pods that are easy for your pages to use.

// 13. Create a Service for handling authentication.
class AuthService {
  final pUser = Pod<User?>(null);

  // Create a simpler Pod from pUser that indicates whether the user is logged in.
  late final pIsLoggedIn = pUser.map((e) => e != null);

  Future<void> login() async {
    // Simulate logging in.
    await Future.delayed(
      const Duration(seconds: 1),
      () async {
        pUser.set(const User('123'));

        // Register the connection service when a user logs in.
        GetIt.I.registerLazySingleton<ConnectionService>(
          () => ConnectionService(GetIt.I<AuthService>()),
          dispose: (e) => e.dispose(),
        );
      },
    );
  }

  Future<void> logout() async {
    // Simulate logging out.
    await Future.delayed(
      const Duration(seconds: 1),
      () => pUser.set(null),
    );
    // Unregister the connection service when a user logs out.
    GetIt.I.unregister<ConnectionService>();
  }

  // Dispose all Pods to free up resources.
  void dispose() {
    pUser.dispose();
    // ChildPods do not need to be diposed of. pIsLoggedIn is a ChildPod
    // because it depends on pUser.
    //pIsLoggedIn.dispose();
  }
}

// 13. Imagine this is some kind of social app, we have a service for managing
// the current user's connections.
class ConnectionService {
  final AuthService authService;
  final pConnections = Pod(<User>[]);

  ConnectionService(this.authService);

  void dispose() {
    pConnections.dispose();
  }
}

// Define your data models somewhere in your app, e.g., lib/src/models
class User {
  final String id;
  const User(this.id);
}

// 14. Imagine this app receives notifications from some API, we have a service
// for managing notifications.
class NotificationService {
  StreamSubscription<String>? _streamSubscription;

  final pNotifications = Pod(Queue<String>.from([]));

  NotificationService() {
    _startSteam();
  }

  void _startSteam() {
    _stopStream();
    _streamSubscription = Stream.periodic(const Duration(seconds: 5), (count) {
      return [
        'priority: I love Pods',
        'GetIt is nice',
        'I like Streams.',
      ][count % 3];
    }).listen(_pushMessage);
  }

  void _pushMessage(String message) {
    pNotifications.update((messages) {
      messages.add(message);
      if (messages.length > 100) {
        messages.removeFirst();
      }
      return messages;
    });
  }

  void _stopStream() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
  }

  void dispose() {
    _stopStream();
    pNotifications.dispose();
  }
}

// 15. Register services that should persist throughout the duration of the app.
// This can be called in main.dart.
void onAppStart() {
  GetIt.I
    ..registerLazySingleton<AuthService>(
      () => AuthService(),
      dispose: (e) => e.dispose(),
    )
    ..registerLazySingleton<NotificationService>(
      () => NotificationService(),
      dispose: (e) => e.dispose(),
    );
}
