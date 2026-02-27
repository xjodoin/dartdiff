import '../core/diff_base.dart';
import '../core/diff_options.dart';
import '../models/change.dart';

class CharacterDiff extends DiffBase<String, String, String> {
  const CharacterDiff();
}

const characterDiff = CharacterDiff();

List<Change<String>>? diffChars(
  String oldStr,
  String newStr, {
  bool ignoreCase = false,
  bool oneChangePerToken = false,
  int? timeout,
  int? maxEditLength,
}) {
  return characterDiff.diff(
    oldStr,
    newStr,
    options: DiffComputationOptions<String>(
      ignoreCase: ignoreCase,
      oneChangePerToken: oneChangePerToken,
      timeout: timeout,
      maxEditLength: maxEditLength,
    ),
  );
}
