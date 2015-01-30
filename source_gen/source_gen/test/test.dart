library dart_source_gen.test_lib;

import 'package:dart_source_gen/json_serial/json_annotation.dart';

part 'test.g.dart';

@JsonSerializable()
class Person extends Object with _$_PersonSerializerMixin {
  String firstName, middleName, lastName;
  DateTime dob;

  Person();

  factory Person.fromJson(json) => _$_PersonSerializerMixin.fromJson(json);
}
