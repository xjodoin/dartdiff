import 'package:dartdiff/dartdiff.dart';

void main() {
  final changes = diffChars('Old Value.', 'New ValueMoreData.');
  if (changes == null) {
    print('Diff aborted');
    return;
  }
  print(convertChangesToXml(changes));
}
