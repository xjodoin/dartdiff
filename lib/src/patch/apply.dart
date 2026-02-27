import '../models/patch.dart';
import '../util/distance_iterator.dart';
import '../util/string_utils.dart';
import 'line_endings.dart';
import 'parse.dart';

typedef CompareLine =
    bool Function(
      int lineNumber,
      String line,
      String operation,
      String patchContent,
    );

class _ApplyHunkResult {
  _ApplyHunkResult({required this.patchedLines, required this.oldLineLastI});

  final List<String> patchedLines;
  final int oldLineLastI;
}

String? applyPatch(
  String source,
  dynamic patch, {
  int fuzzFactor = 0,
  bool autoConvertLineEndings = true,
  CompareLine? compareLine,
}) {
  late List<StructuredPatch> patches;
  if (patch is String) {
    patches = parsePatch(patch);
  } else if (patch is List<StructuredPatch>) {
    patches = patch;
  } else if (patch is StructuredPatch) {
    patches = <StructuredPatch>[patch];
  } else {
    throw ArgumentError(
      'patch must be a String, StructuredPatch, or List<StructuredPatch>',
    );
  }

  if (patches.length > 1) {
    throw ArgumentError('applyPatch only works with a single input.');
  }

  return _applyStructuredPatch(
    source,
    patches.first,
    fuzzFactor: fuzzFactor,
    autoConvertLineEndings: autoConvertLineEndings,
    compareLine: compareLine,
  );
}

String? _applyStructuredPatch(
  String source,
  StructuredPatch patch, {
  required int fuzzFactor,
  required bool autoConvertLineEndings,
  CompareLine? compareLine,
}) {
  if (autoConvertLineEndings) {
    if (hasOnlyWinLineEndings(source) && isUnixPatch(patch)) {
      patch = unixToWinPatch(patch);
    } else if (hasOnlyUnixLineEndings(source) && isWinPatch(patch)) {
      patch = winToUnixPatch(patch);
    }
  }

  final lines = source.split('\n');
  final hunks = patch.hunks;
  final compare =
      compareLine ??
      ((lineNumber, line, operation, patchContent) => line == patchContent);

  var minLine = 0;

  if (fuzzFactor < 0) {
    throw ArgumentError('fuzzFactor must be a non-negative integer');
  }

  if (hunks.isEmpty) {
    return source;
  }

  var prevLine = '';
  var removeEOFNL = false;
  var addEOFNL = false;

  for (final line in hunks.last.lines) {
    if (line.startsWith(r'\')) {
      if (prevLine.startsWith('+')) {
        removeEOFNL = true;
      } else if (prevLine.startsWith('-')) {
        addEOFNL = true;
      }
    }
    prevLine = line;
  }

  if (removeEOFNL) {
    if (addEOFNL) {
      if (fuzzFactor == 0 && lines.isNotEmpty && lines.last == '') {
        return null;
      }
    } else if (lines.isNotEmpty && lines.last == '') {
      lines.removeLast();
    } else if (fuzzFactor == 0) {
      return null;
    }
  } else if (addEOFNL) {
    if (lines.isEmpty || lines.last != '') {
      lines.add('');
    } else if (fuzzFactor == 0) {
      return null;
    }
  }

  _ApplyHunkResult? applyHunk(
    List<String> hunkLines,
    int toPos,
    int maxErrors, {
    int hunkLinesI = 0,
    bool lastContextLineMatched = true,
    List<String>? patchedLines,
    int patchedLinesLength = 0,
  }) {
    patchedLines ??= <String>[];

    var nConsecutiveOldContextLines = 0;
    var nextContextLineMustMatch = false;

    for (; hunkLinesI < hunkLines.length; hunkLinesI++) {
      final hunkLine = hunkLines[hunkLinesI];
      final operation = hunkLine.isNotEmpty ? hunkLine[0] : ' ';
      final content = hunkLine.isNotEmpty ? hunkLine.substring(1) : hunkLine;

      if (operation == '-') {
        if (toPos < lines.length &&
            toPos >= 0 &&
            compare(toPos + 1, lines[toPos], operation, content)) {
          toPos++;
          nConsecutiveOldContextLines = 0;
        } else {
          if (maxErrors == 0 || toPos >= lines.length || toPos < 0) {
            return null;
          }
          _setPatchedLine(patchedLines, patchedLinesLength, lines[toPos]);
          return applyHunk(
            hunkLines,
            toPos + 1,
            maxErrors - 1,
            hunkLinesI: hunkLinesI,
            lastContextLineMatched: false,
            patchedLines: patchedLines,
            patchedLinesLength: patchedLinesLength + 1,
          );
        }
      }

      if (operation == '+') {
        if (!lastContextLineMatched) {
          return null;
        }

        _setPatchedLine(patchedLines, patchedLinesLength, content);
        patchedLinesLength++;
        nConsecutiveOldContextLines = 0;
        nextContextLineMustMatch = true;
      }

      if (operation == ' ') {
        nConsecutiveOldContextLines++;

        if (toPos < 0 || toPos >= lines.length) {
          if (nextContextLineMustMatch || maxErrors == 0) {
            return null;
          }

          return applyHunk(
            hunkLines,
            toPos,
            maxErrors - 1,
            hunkLinesI: hunkLinesI + 1,
            lastContextLineMatched: false,
            patchedLines: patchedLines,
            patchedLinesLength: patchedLinesLength,
          );
        }

        _setPatchedLine(patchedLines, patchedLinesLength, lines[toPos]);

        if (compare(toPos + 1, lines[toPos], operation, content)) {
          patchedLinesLength++;
          lastContextLineMatched = true;
          nextContextLineMustMatch = false;
          toPos++;
        } else {
          if (nextContextLineMustMatch || maxErrors == 0) {
            return null;
          }

          final substitution = applyHunk(
            hunkLines,
            toPos + 1,
            maxErrors - 1,
            hunkLinesI: hunkLinesI + 1,
            lastContextLineMatched: false,
            patchedLines: List<String>.from(patchedLines),
            patchedLinesLength: patchedLinesLength + 1,
          );

          if (substitution != null) {
            return substitution;
          }

          final insertion = applyHunk(
            hunkLines,
            toPos + 1,
            maxErrors - 1,
            hunkLinesI: hunkLinesI,
            lastContextLineMatched: false,
            patchedLines: List<String>.from(patchedLines),
            patchedLinesLength: patchedLinesLength + 1,
          );

          if (insertion != null) {
            return insertion;
          }

          return applyHunk(
            hunkLines,
            toPos,
            maxErrors - 1,
            hunkLinesI: hunkLinesI + 1,
            lastContextLineMatched: false,
            patchedLines: patchedLines,
            patchedLinesLength: patchedLinesLength,
          );
        }
      }
    }

    patchedLinesLength -= nConsecutiveOldContextLines;
    toPos -= nConsecutiveOldContextLines;

    if (patchedLinesLength < patchedLines.length) {
      patchedLines.removeRange(patchedLinesLength, patchedLines.length);
    }

    return _ApplyHunkResult(
      patchedLines: patchedLines,
      oldLineLastI: toPos - 1,
    );
  }

  final resultLines = <String>[];
  var prevHunkOffset = 0;

  for (final hunk in hunks) {
    _ApplyHunkResult? hunkResult;
    final maxLine = lines.length - hunk.oldLines + fuzzFactor;
    int? appliedPos;

    for (var maxErrors = 0; maxErrors <= fuzzFactor; maxErrors++) {
      final startPos = hunk.oldStart + prevHunkOffset - 1;
      final iterator = distanceIterator(startPos, minLine, maxLine);

      int? candidate = startPos;
      while (candidate != null) {
        hunkResult = applyHunk(hunk.lines, candidate, maxErrors);
        if (hunkResult != null) {
          appliedPos = candidate;
          break;
        }
        candidate = iterator();
      }

      if (hunkResult != null) {
        break;
      }
    }

    if (hunkResult == null || appliedPos == null) {
      return null;
    }

    for (var i = minLine; i < appliedPos; i++) {
      if (i >= 0 && i < lines.length) {
        resultLines.add(lines[i]);
      }
    }

    resultLines.addAll(hunkResult.patchedLines);

    minLine = hunkResult.oldLineLastI + 1;
    prevHunkOffset = appliedPos + 1 - hunk.oldStart;
  }

  for (var i = minLine; i < lines.length; i++) {
    resultLines.add(lines[i]);
  }

  return resultLines.join('\n');
}

void _setPatchedLine(List<String> lines, int index, String value) {
  if (index < lines.length) {
    lines[index] = value;
    return;
  }

  if (index == lines.length) {
    lines.add(value);
    return;
  }

  while (lines.length < index) {
    lines.add('');
  }
  lines.add(value);
}

void applyPatches(
  dynamic uniDiff, {
  required void Function(
    StructuredPatch index,
    void Function(Object? err, String data) callback,
  )
  loadFile,
  required void Function(
    StructuredPatch index,
    String? content,
    void Function(Object? err) callback,
  )
  patched,
  required void Function([Object? err]) complete,
  int fuzzFactor = 0,
  bool autoConvertLineEndings = true,
  CompareLine? compareLine,
}) {
  final spDiff = uniDiff is String
      ? parsePatch(uniDiff)
      : uniDiff as List<StructuredPatch>;
  var currentIndex = 0;

  void processIndex() {
    if (currentIndex >= spDiff.length) {
      complete();
      return;
    }

    final index = spDiff[currentIndex++];

    loadFile(index, (err, data) {
      if (err != null) {
        complete(err);
        return;
      }

      final updatedContent = applyPatch(
        data,
        index,
        fuzzFactor: fuzzFactor,
        autoConvertLineEndings: autoConvertLineEndings,
        compareLine: compareLine,
      );

      patched(index, updatedContent, (patchErr) {
        if (patchErr != null) {
          complete(patchErr);
          return;
        }

        processIndex();
      });
    });
  }

  processIndex();
}
