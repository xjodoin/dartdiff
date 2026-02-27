import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('upstream converted fixture exists', () {
    final fixturePath = '${Directory.current.path}/test/data/upstream_cases.json';
    final fixture = jsonDecode(
      File(fixturePath).readAsStringSync(),
    ) as Map<String, dynamic>;
    final cases = (fixture['cases'] as List).cast<Map<String, dynamic>>();

    expect(cases.length, equals(395));
  });
}
