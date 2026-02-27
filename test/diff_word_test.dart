import 'package:dartdiff/dartdiff.dart';
import 'package:test/test.dart';

void main() {
  group('diffWords', () {
    test('ignores whitespace changes around unchanged tokens', () {
      final diffResult = diffWords('New    Value', 'New \n \t Value')!;
      expect(convertChangesToXML(diffResult), 'New \n \t Value');
    });

    test('ignoreCase works', () {
      final diffResult = diffWords('Foo Bar', 'foo bar', ignoreCase: true)!;
      expect(convertChangesToXML(diffResult), 'foo bar');
    });

    test('diffWordsWithSpace treats newline as explicit token', () {
      final diffResult = diffWordsWithSpace('foo\nbar', 'foo bar')!;
      expect(diffResult.any((c) => c.added || c.removed), isTrue);
    });
  });
}
