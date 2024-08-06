// // .title
// // ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

// // Dart/Flutter (DF) Packages by DevCetra.com & contributors. See LICENSE file
// // in root directory.

// // ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
// // .title~

// import 'package:analyzer/dart/ast/token.dart';
// import 'package:analyzer/error/error.dart';
// import 'package:analyzer/error/listener.dart';
// import 'package:custom_lint_builder/custom_lint_builder.dart';

// // ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// class MustDisposePodsRule extends DartLintRule {
//   //
//   //
//   //

//   const MustDisposePodsRule()
//       : super(
//           code: const LintCode(
//             name: 'must_dispose_pods',
//             problemMessage: 'Instances of Pod must call dispose().',
//             correctionMessage:
//                 'Ensure that dispose() is called for each Pod instance.',
//             errorSeverity: ErrorSeverity.WARNING,
//           ),
//         );

//   //
//   //
//   //

//   static final _instances = <String, Set<Token>>{};
//   static final _methods = <String, Set<Token>>{};

//   //
//   //
//   //

//   @override
//   void run(
//     CustomLintResolver resolver,
//     ErrorReporter reporter,
//     CustomLintContext context,
//   ) {
//     // Get the path of the file to check.
//     final p = resolver.path;

//     // Clear instances and methods for the current file.
//     _instances[p] = {};
//     _methods[p] = {};

//     context.registry.addInstanceCreationExpression((node) {
//       final notDisposable = node.toString().contains('disposable: false');
//       if (_isPodType(node.constructorName.type) && !notDisposable) {
//         final t = node.parent?.beginToken;
//         if (t != null) {
//           // Save the instance token.
//           _instances[p]!.add(t);
//         }
//       }
//     });

//     context.registry.addMethodInvocation((node) {
//       if (_isPodType(node.target?.staticType) &&
//           node.methodName.name == 'dispose') {
//         final t = node.target?.beginToken;
//         if (t != null) {
//           // Save the method's target token. This is an instance token too.
//           _methods[p]!.add(t);
//         }
//       }
//     });

//     context.addPostRunCallback(() {
//       // Get all instances and methods from all files to check.
//       final instances = _instances.values.expand((e) => e);
//       final methods = _methods.values.expand((e) => e);
//       final methodStrings = methods.map((e) => e.toString()).toSet();
//       // Get offsets for current file to check. Offsets for other files are not available.
//       final methodOffsets = _methods[p]!.map((e) => e.offset).toSet();
//       for (final t in instances) {
//         if (!methodStrings.contains(t.toString()) &&
//             !methodOffsets.contains(t.offset)) {
//           reporter.reportErrorForToken(
//             code,
//             t,
//           );
//         }
//       }
//     });
//   }
// }

// // ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// bool _isPodType(dynamic type) {
//   final typeName = type.toString();
//   final typeMatcher = RegExp(r'Pod(\<\w+\>)?');
//   return typeMatcher.hasMatch(typeName);
// }
