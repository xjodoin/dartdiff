import 'package:dartdiff/dartdiff.dart';
import 'package:test/test.dart';

void main() {
  test('convertChangesToDMP and XML', () {
    final changes = diffChars('abc', 'axc')!;

    final dmp = convertChangesToDMP(changes);
    expect(dmp, isNotEmpty);

    final xml = convertChangesToXML(changes);
    expect(xml, 'a<del>b</del><ins>x</ins>c');
  });
}
