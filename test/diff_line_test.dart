import 'package:dartdiff/dartdiff.dart';
import 'package:test/test.dart';

void main() {
  group('diffLines', () {
    test('diffs lines', () {
      final changes = diffLines('line1\nline2\n', 'line1\nlineX\n')!;
      expect(changes.where((c) => c.removed).single.value, 'line2\n');
      expect(changes.where((c) => c.added).single.value, 'lineX\n');
    });

    test('ignoreWhitespace', () {
      final changes = diffLines(
        'line1   \n',
        'line1\n',
        ignoreWhitespace: true,
      )!;
      expect(changes.length, 1);
      expect(changes.single.added || changes.single.removed, isFalse);
    });

    test('ignoreNewlineAtEof', () {
      final changes = diffLines('a\nb\n', 'a\nb', ignoreNewlineAtEof: true)!;
      expect(changes.length, 1);
    });

    test('maxEditLength aborts on changes', () {
      final changed = diffLines('a', 'b', maxEditLength: 0);
      final identical = diffLines('a', 'a', maxEditLength: 0);
      expect(changed, isNull);
      expect(identical, isNotNull);
    });
  });
}
