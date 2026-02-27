import 'package:dartdiff/dartdiff.dart';
import 'package:test/test.dart';

void main() {
  group('patch roundtrip', () {
    test('createPatch -> parsePatch -> applyPatch', () {
      const oldText = 'line1\nline2\nline3\n';
      const newText = 'line1\nlineX\nline3\n';

      final patch = createPatch('file.txt', oldText, newText);
      expect(patch, isNotNull);

      final parsed = parsePatch(patch!);
      expect(parsed.length, 1);

      final applied = applyPatch(oldText, parsed.first);
      expect(applied, newText);
    });

    test('applyPatch returns null on mismatch', () {
      const oldText = 'line1\nline2\n';
      const newText = 'line1\nlineX\n';

      final patch = createPatch('file.txt', oldText, newText)!;
      final applied = applyPatch('totally different', patch);
      expect(applied, isNull);
    });

    test('reversePatch undoes a patch', () {
      const oldText = 'a\nb\n';
      const newText = 'a\nc\n';

      final structured = structuredPatch('f.txt', 'f.txt', oldText, newText)!;
      final applied = applyPatch(oldText, structured);
      expect(applied, newText);

      final reversed = reversePatch(structured);
      final back = applyPatch(newText, reversed);
      expect(back, oldText);
    });

    test('line ending helpers', () {
      final structured = structuredPatch('a.txt', 'a.txt', 'a\nb\n', 'a\nc\n')!;

      final win = unixToWin(structured) as StructuredPatch;
      expect(isWin(win), isTrue);

      final unix = winToUnix(win) as StructuredPatch;
      expect(isUnix(unix), isTrue);
    });

    test('formatPatch supports header options', () {
      final structured = structuredPatch('a.txt', 'a.txt', 'a\n', 'b\n')!;

      final full = formatPatch(structured, headerOptions: INCLUDE_HEADERS);
      final minimal = formatPatch(structured, headerOptions: OMIT_HEADERS);

      expect(full, contains('--- a.txt'));
      expect(minimal, isNot(contains('--- a.txt')));
      expect(minimal, contains('@@ -1,1 +1,1 @@'));
    });
  });
}
