import '../core/diff_base.dart';
import '../core/diff_options.dart';
import '../models/change.dart';

class LineDiff extends DiffBase<String, String, String> {
  const LineDiff();

  @override
  bool equals(
    String left,
    String right,
    DiffComputationOptions<String> options,
  ) {
    final ignoreWhitespace = options.extra<bool>('ignoreWhitespace') ?? false;
    final ignoreNewlineAtEof =
        options.extra<bool>('ignoreNewlineAtEof') ?? false;
    final newlineIsToken = options.extra<bool>('newlineIsToken') ?? false;

    if (ignoreWhitespace) {
      if (!newlineIsToken || !left.contains('\n')) {
        left = left.trim();
      }
      if (!newlineIsToken || !right.contains('\n')) {
        right = right.trim();
      }
    } else if (ignoreNewlineAtEof && !newlineIsToken) {
      if (left.endsWith('\n')) {
        left = left.substring(0, left.length - 1);
      }
      if (right.endsWith('\n')) {
        right = right.substring(0, right.length - 1);
      }
    }

    return super.equals(left, right, options);
  }

  @override
  List<String> tokenize(String value, DiffComputationOptions<String> options) {
    return tokenizeLines(
      value,
      stripTrailingCr: options.extra<bool>('stripTrailingCr') ?? false,
      newlineIsToken: options.extra<bool>('newlineIsToken') ?? false,
    );
  }
}

const lineDiff = LineDiff();

List<String> tokenizeLines(
  String value, {
  bool stripTrailingCr = false,
  bool newlineIsToken = false,
}) {
  if (stripTrailingCr) {
    value = value.replaceAll('\r\n', '\n');
  }

  final linesAndNewlines = <String>[];
  var start = 0;
  for (final match in RegExp(r'\r\n|\n').allMatches(value)) {
    linesAndNewlines.add(value.substring(start, match.start));
    linesAndNewlines.add(match.group(0)!);
    start = match.end;
  }
  linesAndNewlines.add(value.substring(start));

  if (linesAndNewlines.isNotEmpty && linesAndNewlines.last.isEmpty) {
    linesAndNewlines.removeLast();
  }

  final retLines = <String>[];

  for (var i = 0; i < linesAndNewlines.length; i++) {
    final line = linesAndNewlines[i];

    if (i.isOdd && !newlineIsToken) {
      if (retLines.isEmpty) {
        retLines.add(line);
      } else {
        retLines[retLines.length - 1] = retLines.last + line;
      }
    } else {
      retLines.add(line);
    }
  }

  return retLines;
}

List<Change<String>>? diffLines(
  String oldStr,
  String newStr, {
  bool oneChangePerToken = false,
  bool ignoreCase = false,
  bool ignoreWhitespace = false,
  bool ignoreNewlineAtEof = false,
  bool stripTrailingCr = false,
  bool newlineIsToken = false,
  int? timeout,
  int? maxEditLength,
}) {
  return lineDiff.diff(
    oldStr,
    newStr,
    options: DiffComputationOptions<String>(
      oneChangePerToken: oneChangePerToken,
      ignoreCase: ignoreCase,
      timeout: timeout,
      maxEditLength: maxEditLength,
      extras: {
        'ignoreWhitespace': ignoreWhitespace,
        'ignoreNewlineAtEof': ignoreNewlineAtEof,
        'stripTrailingCr': stripTrailingCr,
        'newlineIsToken': newlineIsToken,
      },
    ),
  );
}

List<Change<String>>? diffTrimmedLines(
  String oldStr,
  String newStr, {
  bool oneChangePerToken = false,
  bool ignoreCase = false,
  bool ignoreNewlineAtEof = false,
  bool stripTrailingCr = false,
  bool newlineIsToken = false,
  int? timeout,
  int? maxEditLength,
}) {
  return diffLines(
    oldStr,
    newStr,
    oneChangePerToken: oneChangePerToken,
    ignoreCase: ignoreCase,
    ignoreWhitespace: true,
    ignoreNewlineAtEof: ignoreNewlineAtEof,
    stripTrailingCr: stripTrailingCr,
    newlineIsToken: newlineIsToken,
    timeout: timeout,
    maxEditLength: maxEditLength,
  );
}
