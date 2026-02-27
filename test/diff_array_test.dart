import 'package:dartdiff/dartdiff.dart';
import 'package:test/test.dart';

void main() {
  group('diffArrays', () {
    test('diffs arrays', () {
      final changes = diffArrays<int>([1, 2, 3], [1, 4, 3]);
      expect(changes, isNotNull);
      expect(changes!.where((c) => c.removed).single.value, [2]);
      expect(changes.where((c) => c.added).single.value, [4]);
    });

    test('keeps falsey values', () {
      final changes = diffArrays<Object?>([0, false, ''], [0, false, '', 1]);
      expect(changes, isNotNull);
      expect(changes!.last.added, isTrue);
      expect(changes.last.value, [1]);
    });

    test('comparator gets left/right in old/new order', () {
      final seen = <String>[];
      diffArrays<int>(
        [1, 2],
        [1, 3],
        comparator: (left, right) {
          seen.add('$left:$right');
          return left == right;
        },
      );
      expect(seen, contains('2:3'));
    });
  });
}
