library source_gen.test.annotation_test;

import 'dart:async';

import 'package:analyzer/src/generated/element.dart';
import 'package:path/path.dart' as p;
import 'package:unittest/unittest.dart';

import 'package:source_gen/json_serial/json_annotation.dart';
import 'package:source_gen/src/annotation.dart';
import 'package:source_gen/src/io.dart';
import 'package:source_gen/src/utils.dart';

import 'test_files/annotations.dart' as defs;

import 'test_utils.dart';

void main() {
  LibraryElement libElement;

  setUp(() async {
    if (libElement == null) {
      libElement = await _getTestLibElement();
    }
  });

  group('create', () {
    group('with field annotations', () {
      test('annotated with typed field', () {
        var annotatedClass =
            _getAnnotationForClass(libElement, 'WithTypedField');
        var annotation = annotatedClass.metadata.single;
        var instance = instantiateAnnotation(annotation);
        expect(instance is defs.PublicAnnotationClass, isTrue);
        expect(instance.anInt, 0);
      });

      test('annotated with untyped field', () {
        var annotatedClass =
            _getAnnotationForClass(libElement, 'WithUntypedField');
        var annotation = annotatedClass.metadata.single;
        var instance = instantiateAnnotation(annotation);
        expect(instance is defs.PublicAnnotationClass, isTrue);
        expect(instance.anInt, 0);
      });

      test('annotated with local typed field', () {
        var annotatedClass =
            _getAnnotationForClass(libElement, 'WithLocalTypedField');
        var annotation = annotatedClass.metadata.single;
        var instance = instantiateAnnotation(annotation);
        expect(instance is defs.PublicAnnotationClass, isTrue);
        expect(instance.anInt, 0);
      });

      test('annotated with local untyped field', () {
        var annotatedClass =
            _getAnnotationForClass(libElement, 'WithLocalUntypedField');
        var annotation = annotatedClass.metadata.single;
        var instance = instantiateAnnotation(annotation);
        expect(instance is defs.PublicAnnotationClass, isTrue);
        expect(instance.anInt, 0);
      });
    });

    test('annotated with class', () {
      var annotatedClass = _getAnnotationForClass(libElement, 'CtorNoParams');
      var annotation = annotatedClass.metadata.single;
      var instance = instantiateAnnotation(annotation);
      expect(instance is defs.PublicAnnotationClass, isTrue);
      expect(instance.anInt, 0);
      expect(instance.aBool, isFalse);
    });

    test('annotated with class using a non-default ctor', () {
      var annotatedClass =
          _getAnnotationForClass(libElement, 'NonDefaultCtorNoParams');
      var annotation = annotatedClass.metadata.single;
      var instance = instantiateAnnotation(annotation);
      expect(instance is defs.PublicAnnotationClass, isTrue);
      expect(instance.anInt, 1);
      expect(instance.aBool, isFalse);
    });

    test('using a non-default ctor with potional args', () {
      var annotatedClass = _getAnnotationForClass(
          libElement, 'NonDefaultCtorWithPositionalParams');
      var annotation = annotatedClass.metadata.single;
      var instance =
          instantiateAnnotation(annotation) as defs.PublicAnnotationClass;
      expect(instance.anInt, 42);
      expect(instance.aString, 'custom value');
      expect(instance.aBool, isFalse);
    });

    test('using a non-default ctor with potional and named args', () {
      var annotatedClass = _getAnnotationForClass(
          libElement, 'NonDefaultCtorWithPositionalAndNamedParams');
      var annotation = annotatedClass.metadata.single;
      var instance =
          instantiateAnnotation(annotation) as defs.PublicAnnotationClass;
      expect(instance.anInt, 43);
      expect(instance.aString, 'another value');
      expect(instance.aBool, isTrue);
    });
  });

  group('matchAnnotation', () {
    group('with field annotations', () {
      test('annotated with typed field', () {
        var annotatedClass =
            _getAnnotationForClass(libElement, 'WithTypedField');
        var annotation = annotatedClass.metadata.single;
        var matched = matchAnnotation(defs.PublicAnnotationClass, annotation);
        expect(matched, isTrue);
      });

      test('annotated with untyped field', () {
        var annotatedClass =
            _getAnnotationForClass(libElement, 'WithUntypedField');
        var annotation = annotatedClass.metadata.single;
        var matched = matchAnnotation(defs.PublicAnnotationClass, annotation);
        expect(matched, isTrue);
      });

      test('annotated with local typed field', () {
        var annotatedClass =
            _getAnnotationForClass(libElement, 'WithLocalTypedField');
        var annotation = annotatedClass.metadata.single;
        var matched = matchAnnotation(defs.PublicAnnotationClass, annotation);
        expect(matched, isTrue);
      });

      test('annotated with local untyped field', () {
        var annotatedClass =
            _getAnnotationForClass(libElement, 'WithLocalUntypedField');
        var annotation = annotatedClass.metadata.single;
        var matched = matchAnnotation(defs.PublicAnnotationClass, annotation);
        expect(matched, isTrue);
      });
    });

    group('with class annotations', () {
      test('annotated with class', () {
        var annotatedClass = _getAnnotationForClass(libElement, 'CtorNoParams');
        var annotation = annotatedClass.metadata.single;
        var matched = matchAnnotation(defs.PublicAnnotationClass, annotation);
        expect(matched, isTrue);
      });

      test('annotated with class in a part', () {
        ClassElement annotatedClass =
            _getAnnotationForClass(libElement, 'CtorNoParamsInPart');
        var annotation = annotatedClass.metadata.single;
        var matched = matchAnnotation(defs.PublicAnnotationClass, annotation);
        expect(matched, isTrue);
      });

      test('class in a part annotated with class', () {
        var annotatedClass = _getAnnotationForClass(libElement, 'CtorNoParams');
        var annotation = annotatedClass.metadata.single;
        var matched =
            matchAnnotation(defs.PublicAnnotationClassInPart, annotation);
        expect(matched, isFalse, reason: 'not annotated with that type');
      });

      test('class in a part annotated with class in a part', () {
        ClassElement annotatedClass =
            _getAnnotationForClass(libElement, 'CtorNoParamsInPart');
        var annotation = annotatedClass.metadata.single;
        var matched =
            matchAnnotation(defs.PublicAnnotationClassInPart, annotation);
        expect(matched, isFalse);
      });

      test('class annotated with type defined via package uri', () {
        ClassElement annotatedClass =
            _getAnnotationForClass(libElement, 'AnnotatedWithJson');
        var annotation = annotatedClass.metadata.single;
        var matched = matchAnnotation(JsonSerializable, annotation);
        expect(matched, isTrue);
      });
    });
  });
}

Future<LibraryElement> _getTestLibElement() async {
  var testFilesRelativePath = p.join('test', 'test_files');

  var projectPath = getPackagePath();

  var foundFiles =
      await getDartFiles(projectPath, searchList: [testFilesRelativePath]);

  var context = await getAnalysisContextForProjectPath(projectPath, foundFiles);

  var annotatedClassesFilePath =
      p.join(getPackagePath(), testFilesRelativePath, 'annotated_classes.dart');

  return getLibraryElementForSourceFile(context, annotatedClassesFilePath);
}

ClassElement _getAnnotationForClass(LibraryElement lib, String className) =>
    lib.units
        .expand((cu) => cu.types)
        .singleWhere((cd) => cd.name == className);
