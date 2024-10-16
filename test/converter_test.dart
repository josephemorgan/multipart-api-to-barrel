import 'dart:io';

import 'package:api_barrel_file_converter/converter.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('convert', () {
    // Create a temporary directory, and copy the contents of `cafdexgo-server` into it.
    final cafdexgoServer = Directory(p.join('test', 'cafdexgo-server'));
    final tempDir = Directory.systemTemp.createTempSync('cafdexgo-server-copy');

    recursivelyCopyDirectory(cafdexgoServer, tempDir);

    // Run the conversion.
    Converter(tempDir.path).convert();
  });
}

recursivelyCopyDirectory(Directory source, Directory destination) {
  source.listSync().forEach((entity) {
    final newPath = p.join(
        destination.path, entity.path.split(Platform.pathSeparator).last);
    if (entity is File) {
      entity.copySync(newPath);
    } else if (entity is Directory) {
      Directory(newPath).createSync();
      recursivelyCopyDirectory(entity, Directory(newPath));
    }
  });
}
