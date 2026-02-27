import 'package:dartdiff/dartdiff.dart';
import 'package:test/test.dart';

void main() {
  group('diffChars', () {
    test('basic diff', () {
      final diffResult = diffChars('Old Value.', 'New ValueMoreData.');
      expect(diffResult, isNotNull);
      expect(
        convertChangesToXML(diffResult!),
        '<del>Old</del><ins>New</ins> Value<ins>MoreData</ins>.',
      );
    });

    test('oneChangePerToken', () {
      final diffResult = diffChars('ab', 'ac', oneChangePerToken: true)!;
      expect(diffResult.length, 3);
      expect(diffResult[0].value, 'a');
      expect(diffResult[1].removed, isTrue);
      expect(diffResult[2].added, isTrue);
    });

    test('unicode code points are handled as characters', () {
      final diffResult = diffChars('𝟘𝟙𝟚𝟛', '𝟘𝟙𝟚𝟜𝟝𝟞')!;
      expect(diffResult.length, 3);
      expect(diffResult[2].count, 3);
      expect(
        convertChangesToXML(diffResult),
        '𝟘𝟙𝟚<del>𝟛</del><ins>𝟜𝟝𝟞</ins>',
      );
    });

    test('ignoreCase option', () {
      final diffResult = diffChars(
        'New Value.',
        'New value.',
        ignoreCase: true,
      )!;
      expect(convertChangesToXML(diffResult), 'New value.');
    });
  });
}
