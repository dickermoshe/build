library source_gen.io;

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Skips symbolic links and any item in [directryPath] recursively that begins
/// with `.`.
///
/// [searchList] is a list of relative paths within [directoryPath].
/// Returned results will be those files that match file paths or are within
/// directories defined in the list.
Future<List<String>> getDartFiles(String directoryPath, {List<String> searchList}) {
  return getFiles(directoryPath, searchList: searchList)
      .where((path) => p.extension(path) == '.dart')
      .toList();
}

/// Skips symbolic links and any item in [directryPath] recursively that begins
/// with `.`.
///
/// [searchList] is a list of relative paths within [directoryPath].
/// Returned results will be those files that match file paths or are within
/// directories defined in the list.
Stream<String> getFiles(String directoryPath, {List<String> searchList}) {
  var controller = new StreamController<String>();
  if (searchList == null) {
    searchList = <String>[];
  }

  _expandSearchList(directoryPath, searchList).then((map) async {
    var searchDirs = <String>[];

    map.forEach((path, type) {
      if (type == FileSystemEntityType.FILE) {
        controller.add(path);
      } else {
        searchDirs.add(path);
      }
    });

    await Future.forEach(searchDirs, (path) {
      var rootDir = new Directory(path);

      return _populateFiles(rootDir, controller);
    });
  }).catchError((error, stack) {
    controller.addError(error, stack);
  }).whenComplete(() {
    controller.close();
  });

  return controller.stream;
}

Future<Map<String, FileSystemEntityType>> _expandSearchList(
    String basePath, List<String> searchList) async {
  List<String> searchPaths;

  if (searchList.isEmpty) {
    searchPaths = <String>[basePath];
  } else {
    searchPaths = searchList.map((path) => p.join(basePath, path)).toList();
  }

  var items = <String, FileSystemEntityType>{};

  await Future.forEach(searchPaths, (path) async {
    var type = await FileSystemEntity.type(path);

    if (type != FileSystemEntityType.FILE &&
        type != FileSystemEntityType.DIRECTORY) {
      return;
    }

    /// If there is overlap with the provided paths, just fail.
    /// For instance, providing x and x/y or x/z.dart is a failure
    items.forEach((ePath, eType) {
      // if a file or a directory, check to see if it's a child of ePath - dir
      if (eType == FileSystemEntityType.DIRECTORY) {
        if (p.isWithin(ePath, path)) {
          throw new ArgumentError(
              'Redundant entry: "$path" is within "$ePath"');
        }
      }

      if (type == FileSystemEntityType.DIRECTORY) {
        // check to see if existing items are in this directory
        if (p.isWithin(path, ePath)) {
          throw new ArgumentError(
              'Redundant entry: "$ePath" is within "$path"');
        }
      }
    });

    items[path] = type;
  });

  return items;
}

Future _populateFiles(
    Directory directory, StreamController<String> controller) async {
  return directory.list(recursive: false, followLinks: false).asyncMap((fse) {
    if (p.basename(fse.path).startsWith('.')) {
      return null;
    }

    if (fse is File) {
      controller.add(fse.path);
    } else if (fse is Directory) {
      return _populateFiles(fse, controller);
    }
  }).drain();
}
