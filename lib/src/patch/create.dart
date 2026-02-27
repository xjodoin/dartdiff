import '../diff/line.dart';
import '../models/patch.dart';

class _ChangeWithLines {
  _ChangeWithLines({
    required this.value,
    required this.added,
    required this.removed,
    required this.lines,
  });

  String value;
  bool added;
  bool removed;
  List<String> lines;
}

StructuredPatch? structuredPatch(
  String oldFileName,
  String newFileName,
  String oldStr,
  String newStr, {
  String? oldHeader,
  String? newHeader,
  int context = 4,
  bool ignoreWhitespace = false,
  bool stripTrailingCr = false,
  bool newlineIsToken = false,
  int? timeout,
  int? maxEditLength,
}) {
  if (newlineIsToken) {
    throw ArgumentError(
      'newlineIsToken may not be used with patch-generation functions, only with diffing functions',
    );
  }

  final diff = diffLines(
    oldStr,
    newStr,
    ignoreWhitespace: ignoreWhitespace,
    stripTrailingCr: stripTrailingCr,
    timeout: timeout,
    maxEditLength: maxEditLength,
  );

  if (diff == null) {
    return null;
  }

  final changeObjects = <_ChangeWithLines>[];
  for (final current in diff) {
    changeObjects.add(
      _ChangeWithLines(
        value: current.value,
        added: current.added,
        removed: current.removed,
        lines: _splitLines(current.value),
      ),
    );
  }

  changeObjects.add(
    _ChangeWithLines(
      value: '',
      added: false,
      removed: false,
      lines: <String>[],
    ),
  );

  List<String> contextLines(List<String> lines) {
    return lines.map((entry) => ' $entry').toList();
  }

  final hunks = <StructuredPatchHunk>[];
  var oldRangeStart = 0;
  var newRangeStart = 0;
  var curRange = <String>[];
  var oldLine = 1;
  var newLine = 1;

  for (var i = 0; i < changeObjects.length; i++) {
    final current = changeObjects[i];
    final lines = current.lines;

    if (current.added || current.removed) {
      if (oldRangeStart == 0) {
        final prev = i > 0 ? changeObjects[i - 1] : null;

        oldRangeStart = oldLine;
        newRangeStart = newLine;

        if (prev != null) {
          final startContext = context > 0
              ? contextLines(
                  prev.lines
                      .skip(_max(0, prev.lines.length - context))
                      .toList(),
                )
              : <String>[];
          curRange = List<String>.from(startContext);
          oldRangeStart -= curRange.length;
          newRangeStart -= curRange.length;
        }
      }

      for (final line in lines) {
        curRange.add('${current.added ? '+' : '-'}$line');
      }

      if (current.added) {
        newLine += lines.length;
      } else {
        oldLine += lines.length;
      }
    } else {
      if (oldRangeStart != 0) {
        if (lines.length <= context * 2 && i < changeObjects.length - 2) {
          curRange.addAll(contextLines(lines));
        } else {
          final contextSize = _min(lines.length, context);
          curRange.addAll(contextLines(lines.take(contextSize).toList()));

          hunks.add(
            StructuredPatchHunk(
              oldStart: oldRangeStart,
              oldLines: oldLine - oldRangeStart + contextSize,
              newStart: newRangeStart,
              newLines: newLine - newRangeStart + contextSize,
              lines: List<String>.from(curRange),
            ),
          );

          oldRangeStart = 0;
          newRangeStart = 0;
          curRange = <String>[];
        }
      }

      oldLine += lines.length;
      newLine += lines.length;
    }
  }

  for (final hunk in hunks) {
    var i = 0;
    while (i < hunk.lines.length) {
      if (hunk.lines[i].endsWith('\n')) {
        hunk.lines[i] = hunk.lines[i].substring(0, hunk.lines[i].length - 1);
      } else {
        hunk.lines.insert(i + 1, r'\ No newline at end of file');
        i++;
      }
      i++;
    }
  }

  return StructuredPatch(
    oldFileName: oldFileName,
    newFileName: newFileName,
    oldHeader: oldHeader,
    newHeader: newHeader,
    hunks: hunks,
  );
}

String formatPatch(
  dynamic patch, {
  HeaderOptions headerOptions = includeHeaders,
}) {
  if (patch is List<StructuredPatch>) {
    if (patch.length > 1 && !headerOptions.includeFileHeaders) {
      throw ArgumentError(
        'Cannot omit file headers on a multi-file patch. (The result would be unparseable.)',
      );
    }

    return patch
        .map(
          (singlePatch) =>
              formatPatch(singlePatch, headerOptions: headerOptions),
        )
        .join('\n');
  }

  if (patch is! StructuredPatch) {
    throw ArgumentError(
      'patch must be a StructuredPatch or List<StructuredPatch>',
    );
  }

  final ret = <String>[];

  if (headerOptions.includeIndex && patch.oldFileName == patch.newFileName) {
    ret.add('Index: ${patch.oldFileName}');
  }
  if (headerOptions.includeUnderline) {
    ret.add(
      '===================================================================',
    );
  }
  if (headerOptions.includeFileHeaders) {
    ret.add(
      '--- ${patch.oldFileName}${patch.oldHeader == null ? '' : '\t${patch.oldHeader}'}',
    );
    ret.add(
      '+++ ${patch.newFileName}${patch.newHeader == null ? '' : '\t${patch.newHeader}'}',
    );
  }

  for (final hunk in patch.hunks) {
    var oldStart = hunk.oldStart;
    var newStart = hunk.newStart;

    if (hunk.oldLines == 0) {
      oldStart -= 1;
    }
    if (hunk.newLines == 0) {
      newStart -= 1;
    }

    ret.add('@@ -$oldStart,${hunk.oldLines} +$newStart,${hunk.newLines} @@');
    ret.addAll(hunk.lines);
  }

  return '${ret.join('\n')}\n';
}

String? createTwoFilesPatch(
  String oldFileName,
  String newFileName,
  String oldStr,
  String newStr, {
  String? oldHeader,
  String? newHeader,
  int context = 4,
  bool ignoreWhitespace = false,
  bool stripTrailingCr = false,
  int? timeout,
  int? maxEditLength,
  HeaderOptions headerOptions = includeHeaders,
}) {
  final patchObj = structuredPatch(
    oldFileName,
    newFileName,
    oldStr,
    newStr,
    oldHeader: oldHeader,
    newHeader: newHeader,
    context: context,
    ignoreWhitespace: ignoreWhitespace,
    stripTrailingCr: stripTrailingCr,
    timeout: timeout,
    maxEditLength: maxEditLength,
  );

  if (patchObj == null) {
    return null;
  }

  return formatPatch(patchObj, headerOptions: headerOptions);
}

String? createPatch(
  String fileName,
  String oldStr,
  String newStr, {
  String? oldHeader,
  String? newHeader,
  int context = 4,
  bool ignoreWhitespace = false,
  bool stripTrailingCr = false,
  int? timeout,
  int? maxEditLength,
  HeaderOptions headerOptions = includeHeaders,
}) {
  return createTwoFilesPatch(
    fileName,
    fileName,
    oldStr,
    newStr,
    oldHeader: oldHeader,
    newHeader: newHeader,
    context: context,
    ignoreWhitespace: ignoreWhitespace,
    stripTrailingCr: stripTrailingCr,
    timeout: timeout,
    maxEditLength: maxEditLength,
    headerOptions: headerOptions,
  );
}

List<String> _splitLines(String text) {
  final hasTrailingNl = text.endsWith('\n');
  final result = text.split('\n').map((line) => '$line\n').toList();

  if (hasTrailingNl) {
    if (result.isNotEmpty) {
      result.removeLast();
    }
  } else {
    if (result.isNotEmpty) {
      final last = result.removeLast();
      result.add(last.substring(0, last.length - 1));
    }
  }

  return result;
}

int _min(int a, int b) => a < b ? a : b;
int _max(int a, int b) => a > b ? a : b;
