import 'dart:io';

import 'package:path/path.dart' as p;

class Converter {
  static const subdirectories = [
    'api',
    'auth',
    'model',
  ];

  // These are the files that are in the root of the `lib` directory, and some
  // of them use private APIs from `api.dart`, so they're going to included
  // using `part of`.
  static const apiFiles = [
    'api_exception.dart',
    'api_helper.dart',
    'api_client.dart',
  ];

  const Converter(this.libraryPath);

  final String libraryPath;

  // The list of all files in the `lib` directory that should be considered
  // libraries, and therefore should be exported by the `api.dart` file. It's
  // created by taking all of the files in each of the 3 subdirectories, plus
  // the 3 files in the root of the `lib` directory.
  Iterable<File> get libraryFiles => subdirectories.expand(
        (dir) => Directory(p.joinAll([libraryPath, 'lib', dir]))
            .listSync()
            .whereType<File>(),
      );

  convert() {
    _fixApiHelperFile(File(p.joinAll([libraryPath, 'lib', 'api_helper.dart'])));

    print("Writing barrel file to ${p.joinAll([
          libraryPath,
          'lib',
          'api.dart'
        ])}...");

    _buildBarrelFile();

    print("Done.");

    print("Replacing 'part of' with imports in library files...");

    libraryFiles.forEach(_updateLibraryFileContent);

    print("Done.");
  }

  _buildBarrelFile() {
    final barrelFile = File(p.joinAll([libraryPath, 'lib', 'api.dart']));

    // Creates an export statement for each library file.
    final exportStatements = libraryFiles.map(
      (file) => file.path
          .split(Platform.pathSeparator)
          .skipWhile((part) => part != 'lib')
          .skip(1)
          .join('/'),
    );

    // Reads the barrel file, removes all of the part statements except for
    // those that are in the `apiFiles` list.
    final removedPartDirectives = barrelFile
        .readAsStringSync()
        .split('\n')
        .where(
            (line) => !line.startsWith('part ') || apiFiles.any(line.contains));

    barrelFile.writeAsStringSync(
      // We have to insert the export statements before any of the part
      // statements.
      [
        ...removedPartDirectives.takeWhile((line) => !line.startsWith('part ')),
        // THIS MIGHT CAUSE ISSUES - it's probably better to actually import the
        // files that the parts need, but I'm struggling to figure out how to
        // automate that, so I'm testing this for now.
        "import 'package:CAFDExGOServer/api.dart';",
        ...exportStatements.map((export) => "export '$export';"),
        ...removedPartDirectives.skipWhile((line) => !line.startsWith('part ')),
      ].join('\n'),
      mode: FileMode.write,
    );
  }

  // The `api_helper.dart` file declares some private functions that are used by
  // a bunch of other files. Since we're not using `part of`, we have to make those
  // declarations public.
  _fixApiHelperFile(File file) {
    final inputLines = file.readAsLinesSync();

    final withReplacedText = inputLines.map((line) => line
        .replaceAll('_queryParams', 'helperQueryParams')
        .replaceAll('_decodeBodyBytes', 'helperDecodeBodyBytes'));

    file.writeAsStringSync(withReplacedText.join('\n'));
  }

  _fixApiHelperReferences(String line) {
    return line
        .replaceAll('_queryParams', 'helperQueryParams')
        .replaceAll('_decodeBodyBytes', 'helperDecodeBodyBytes');
  }

  _updateLibraryFileContent(File file) {
    // Since we're not getting our imports from `api.dart` using `part of`, each
    // file has to have its own imports. This isn't a perfrect solution, since
    // it means that each file will likely have some unused imports. I don't
    // think this is a big problem though, since we know that each import is
    // used at least once, so no unnecessary imports are added to the final app
    // bundle.
    final imports = '''
import 'package:CAFDExGOServer/api.dart';
import 'package:CAFDExGOServer/model_base.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
''';

    file.writeAsStringSync(
      imports +
          file
              .readAsStringSync()
              .split('\n')
              .where((line) => !line.startsWith('part of'))
              .map(_fixApiHelperReferences)
              .join('\n'),
    );
  }
}
