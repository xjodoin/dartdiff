import 'package:dartdiff/dartdiff.dart';
import 'package:test/test.dart';

void main() {
  group('diffJson', () {
    test('object key order does not affect diff', () {
      final left = {'b': 2, 'a': 1};
      final right = {'a': 1, 'b': 2};
      final diffResult = diffJson(left, right)!;
      expect(diffResult.length, 1);
      expect(diffResult.single.added || diffResult.single.removed, isFalse);
    });

    test('accepts pre-stringified JSON', () {
      final diffResult = diffJson('{"a":1}', '{"a":2}')!;
      expect(diffResult.any((c) => c.added), isTrue);
      expect(diffResult.any((c) => c.removed), isTrue);
    });

    test('canonicalize handles circular references', () {
      final value = <String, Object?>{};
      value['self'] = value;

      final canonical = canonicalize(value) as Map<String, Object?>;
      expect(canonical['self'], same(canonical));
    });
  });
}
