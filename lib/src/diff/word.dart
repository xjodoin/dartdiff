import '../core/diff_base.dart';
import '../core/diff_options.dart';
import '../models/change.dart';
import '../util/string_utils.dart';

const _extendedWordChars =
    r'a-zA-Z0-9_\u00AD\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02C6\u02C8-\u02D7\u02DE-\u02FF\u1E00-\u1EFF';

final _tokenizeIncludingWhitespace = RegExp(
  '[$_extendedWordChars]+|\\s+|[^$_extendedWordChars]',
  unicode: true,
);

class WordDiff extends DiffBase<String, String, String> {
  const WordDiff();

  @override
  bool equals(
    String left,
    String right,
    DiffComputationOptions<String> options,
  ) {
    if (options.ignoreCase) {
      left = left.toLowerCase();
      right = right.toLowerCase();
    }

    return left.trim() == right.trim();
  }

  @override
  List<String> tokenize(String value, DiffComputationOptions<String> options) {
    final customTokenizer = options.extra<List<String> Function(String)>(
      'wordTokenizer',
    );
    final parts = customTokenizer != null
        ? customTokenizer(value)
        : value
              .splitMapJoin(
                _tokenizeIncludingWhitespace,
                onMatch: (match) => '\u0000${match.group(0)}\u0000',
                onNonMatch: (_) => '',
              )
              .split('\u0000')
              .where((part) => part.isNotEmpty)
              .toList();

    final tokens = <String>[];
    String? prevPart;

    for (final part in parts) {
      if (RegExp(r'\s').hasMatch(part)) {
        if (prevPart == null) {
          tokens.add(part);
        } else {
          tokens.add('${tokens.removeLast()}$part');
        }
      } else if (prevPart != null && RegExp(r'\s').hasMatch(prevPart)) {
        if (tokens.last == prevPart) {
          tokens.add('${tokens.removeLast()}$part');
        } else {
          tokens.add('$prevPart$part');
        }
      } else {
        tokens.add(part);
      }

      prevPart = part;
    }

    return tokens;
  }

  @override
  String join(List<String> chars) {
    final buffer = StringBuffer();
    for (var i = 0; i < chars.length; i++) {
      final token = chars[i];
      if (i == 0) {
        buffer.write(token);
      } else {
        buffer.write(token.replaceFirst(RegExp(r'^\s+'), ''));
      }
    }
    return buffer.toString();
  }

  @override
  List<Change<String>> postProcess(
    List<Change<String>> changeObjects,
    DiffComputationOptions<String> options,
  ) {
    if (options.oneChangePerToken) {
      return changeObjects;
    }

    Change<String>? lastKeep;
    Change<String>? insertion;
    Change<String>? deletion;

    for (final change in changeObjects) {
      if (change.added) {
        insertion = change;
      } else if (change.removed) {
        deletion = change;
      } else {
        if (insertion != null || deletion != null) {
          _dedupeWhitespaceInChangeObjects(
            startKeep: lastKeep,
            deletion: deletion,
            insertion: insertion,
            endKeep: change,
          );
        }
        lastKeep = change;
        insertion = null;
        deletion = null;
      }
    }

    if (insertion != null || deletion != null) {
      _dedupeWhitespaceInChangeObjects(
        startKeep: lastKeep,
        deletion: deletion,
        insertion: insertion,
        endKeep: null,
      );
    }

    return changeObjects;
  }
}

const wordDiff = WordDiff();

void _dedupeWhitespaceInChangeObjects({
  required Change<String>? startKeep,
  required Change<String>? deletion,
  required Change<String>? insertion,
  required Change<String>? endKeep,
}) {
  if (deletion != null && insertion != null) {
    final oldPair = leadingAndTrailingWs(deletion.value);
    final newPair = leadingAndTrailingWs(insertion.value);
    final oldWsPrefix = oldPair[0];
    final oldWsSuffix = oldPair[1];
    final newWsPrefix = newPair[0];
    final newWsSuffix = newPair[1];

    if (startKeep != null) {
      final commonWsPrefix = longestCommonPrefix(oldWsPrefix, newWsPrefix);
      startKeep.value = replaceSuffix(
        startKeep.value,
        newWsPrefix,
        commonWsPrefix,
      );
      deletion.value = removePrefix(deletion.value, commonWsPrefix);
      insertion.value = removePrefix(insertion.value, commonWsPrefix);
    }

    if (endKeep != null) {
      final commonWsSuffix = longestCommonSuffix(oldWsSuffix, newWsSuffix);
      endKeep.value = replacePrefix(endKeep.value, newWsSuffix, commonWsSuffix);
      deletion.value = removeSuffix(deletion.value, commonWsSuffix);
      insertion.value = removeSuffix(insertion.value, commonWsSuffix);
    }

    return;
  }

  if (insertion != null) {
    if (startKeep != null) {
      final ws = leadingWs(insertion.value);
      insertion.value = insertion.value.substring(ws.length);
    }

    if (endKeep != null) {
      final ws = leadingWs(endKeep.value);
      endKeep.value = endKeep.value.substring(ws.length);
    }

    return;
  }

  if (deletion == null) {
    return;
  }

  if (startKeep != null && endKeep != null) {
    final newWsFull = leadingWs(endKeep.value);
    final delPair = leadingAndTrailingWs(deletion.value);
    final delWsStart = delPair[0];
    final delWsEnd = delPair[1];

    final newWsStart = longestCommonPrefix(newWsFull, delWsStart);
    deletion.value = removePrefix(deletion.value, newWsStart);

    final newWsEnd = longestCommonSuffix(
      removePrefix(newWsFull, newWsStart),
      delWsEnd,
    );
    deletion.value = removeSuffix(deletion.value, newWsEnd);
    endKeep.value = replacePrefix(endKeep.value, newWsFull, newWsEnd);

    startKeep.value = replaceSuffix(
      startKeep.value,
      newWsFull,
      newWsFull.substring(0, newWsFull.length - newWsEnd.length),
    );
    return;
  }

  if (endKeep != null) {
    final endKeepWsPrefix = leadingWs(endKeep.value);
    final deletionWsSuffix = trailingWs(deletion.value);
    final overlap = maximumOverlap(deletionWsSuffix, endKeepWsPrefix);
    deletion.value = removeSuffix(deletion.value, overlap);
    return;
  }

  if (startKeep != null) {
    final startKeepWsSuffix = trailingWs(startKeep.value);
    final deletionWsPrefix = leadingWs(deletion.value);
    final overlap = maximumOverlap(startKeepWsSuffix, deletionWsPrefix);
    deletion.value = removePrefix(deletion.value, overlap);
  }
}

class WordsWithSpaceDiff extends DiffBase<String, String, String> {
  const WordsWithSpaceDiff();

  @override
  List<String> tokenize(String value, DiffComputationOptions<String> options) {
    final regex = RegExp(
      '(\\r?\\n)|[$_extendedWordChars]+|[^\\S\\n\\r]+|[^$_extendedWordChars]',
      unicode: true,
    );

    return value
        .splitMapJoin(
          regex,
          onMatch: (match) => '\u0000${match.group(0)}\u0000',
          onNonMatch: (_) => '',
        )
        .split('\u0000')
        .where((part) => part.isNotEmpty)
        .toList();
  }
}

const wordsWithSpaceDiff = WordsWithSpaceDiff();

List<Change<String>>? diffWords(
  String oldStr,
  String newStr, {
  bool ignoreCase = false,
  bool oneChangePerToken = false,
  int? timeout,
  int? maxEditLength,
  bool? ignoreWhitespace,
  List<String> Function(String input)? wordTokenizer,
}) {
  if (ignoreWhitespace != null && !ignoreWhitespace) {
    return diffWordsWithSpace(
      oldStr,
      newStr,
      ignoreCase: ignoreCase,
      oneChangePerToken: oneChangePerToken,
      timeout: timeout,
      maxEditLength: maxEditLength,
    );
  }

  return wordDiff.diff(
    oldStr,
    newStr,
    options: DiffComputationOptions<String>(
      ignoreCase: ignoreCase,
      oneChangePerToken: oneChangePerToken,
      timeout: timeout,
      maxEditLength: maxEditLength,
      extras: {'wordTokenizer': wordTokenizer},
    ),
  );
}

List<Change<String>>? diffWordsWithSpace(
  String oldStr,
  String newStr, {
  bool ignoreCase = false,
  bool oneChangePerToken = false,
  int? timeout,
  int? maxEditLength,
}) {
  return wordsWithSpaceDiff.diff(
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
