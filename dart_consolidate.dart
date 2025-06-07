import 'dart:io';

void main(List<String> arguments) async {
  final sourceDirPath = arguments.firstOrNull ?? '.';
  final sourceDir = Directory(sourceDirPath);

  if (!await sourceDir.exists()) {
    print('Directory does not exist: $sourceDirPath');
    return;
  }

  final outputFile = File('consolidated_output.dart.txt');
  final sink = outputFile.openWrite();
  final imports = <String>{}; // Set to store unique non-local imports

  // Process all files and collect imports
  await _processDirectory(sourceDir, sink, imports);

  // Write imports at the top
  sink.writeln('// Consolidated Imports');
  for (var import in imports) {
    sink.writeln(import);
  }
  sink.writeln();

  // Reprocess files to write their content with commented imports and part directives
  await _writeFileContents(sourceDir, sink);

  await sink.flush();
  await sink.close();
  print('Consolidation complete. Output written to ${outputFile.path}');
}

Future<void> _processDirectory(Directory dir, IOSink sink, Set<String> imports) async {
  await for (final entity in dir.list(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      await _collectImports(entity, imports);
    }
  }
}

Future<void> _collectImports(File file, Set<String> imports) async {
  final lines = await file.readAsLines();
  for (var line in lines) {
    final trimmedLine = line.trim();
    if (trimmedLine.startsWith('import ')) {
      if (trimmedLine.startsWith("import 'package:") || trimmedLine.startsWith("import 'dart:")) {
        imports.add(line); // Store non-local imports
      }
    }
  }
}

Future<void> _writeFileContents(Directory dir, IOSink sink) async {
  await for (final entity in dir.list(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      await _processFile(entity, sink);
    }
  }
}

Future<void> _processFile(File file, IOSink sink) async {
  // Write comment with original file path
  sink.writeln('// Source: ${file.path}');

  final lines = await file.readAsLines();
  for (var line in lines) {
    final trimmedLine = line.trim();
    // Comment out import statements and part directives
    if (trimmedLine.startsWith('import ') ||
        trimmedLine.startsWith('part ') ||
        trimmedLine.startsWith('part of ')) {
      sink.writeln('// $line');
    } else {
      sink.writeln(line);
    }
  }
  // Add a newline after each file's content
  sink.writeln();
}
