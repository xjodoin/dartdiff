import '../core/diff_base.dart';
import '../core/diff_options.dart';
import '../models/change.dart';
import '../util/string_utils.dart';

class CssDiff extends DiffBase<String, String, String> {
  const CssDiff();

  @override
  List<String> tokenize(String value, DiffComputationOptions<String> options) {
    return splitKeepingDelimiters(value, RegExp(r'[{}:;,]|\s+'));
  }
}

const cssDiff = CssDiff();

List<Change<String>>? diffCss(
  String oldStr,
  String newStr, {
  bool oneChangePerToken = false,
  int? timeout,
  int? maxEditLength,
}) {
  return cssDiff.diff(
    oldStr,
    newStr,
    options: DiffComputationOptions<String>(
      oneChangePerToken: oneChangePerToken,
      timeout: timeout,
      maxEditLength: maxEditLength,
    ),
  );
}
