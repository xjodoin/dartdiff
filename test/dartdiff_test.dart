import 'package:dartdiff/dartdiff.dart';
import 'package:test/test.dart';

void main() {
  test('diffChars basic smoke test', () {
    final changes = diffChars('Old Value.', 'New ValueMoreData.');
    expect(changes, isNotNull);
    expect(
      convertChangesToXml(changes!),
      '<del>Old</del><ins>New</ins> Value<ins>MoreData</ins>.',
    );
  });
}
