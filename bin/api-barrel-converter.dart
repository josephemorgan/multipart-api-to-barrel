import 'dart:io';

import 'package:api_barrel_file_converter/converter.dart';
import 'package:args/args.dart';

void main(List<String> arguments) {
  exitCode = 0;
  final parser = ArgParser()..addOption('library-path', abbr: 'l');
  final args = parser.parse(arguments);

  final libraryPath = args.option('library-path');
  if (libraryPath != null) {
    Converter(libraryPath).convert();
  } else {
    print('Usage: api-barrel-converter --library-path <path>');
    exitCode = 2;
  }
}
