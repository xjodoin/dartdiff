import '../core/diff_base.dart';
import '../core/diff_options.dart';
import '../models/change.dart';

bool _isSentenceEndPunct(String char) {
  return char == '.' || char == '!' || char == '?';
}

class SentenceDiff extends DiffBase<String, String, String> {
  const SentenceDiff();

  @override
  List<String> tokenize(String value, DiffComputationOptions<String> options) {
    final result = <String>[];
    var tokenStart = 0;

    for (var i = 0; i < value.length; i++) {
      if (i == value.length - 1) {
        result.add(value.substring(tokenStart));
        break;
      }

      if (_isSentenceEndPunct(value[i]) &&
          RegExp(r'\s').hasMatch(value[i + 1])) {
        result.add(value.substring(tokenStart, i + 1));

        i = tokenStart = i + 1;
        while (i + 1 < value.length && RegExp(r'\s').hasMatch(value[i + 1])) {
          i++;
        }
        result.add(value.substring(tokenStart, i + 1));

        tokenStart = i + 1;
      }
    }

    return result;
  }
}

const sentenceDiff = SentenceDiff();

List<Change<String>>? diffSentences(
  String oldStr,
  String newStr, {
  bool oneChangePerToken = false,
  int? timeout,
  int? maxEditLength,
}) {
  return sentenceDiff.diff(
    oldStr,
    newStr,
    options: DiffComputationOptions<String>(
      oneChangePerToken: oneChangePerToken,
      timeout: timeout,
      maxEditLength: maxEditLength,
    ),
  );
}
