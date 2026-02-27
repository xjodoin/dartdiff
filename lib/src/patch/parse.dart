import '../models/patch.dart';

List<StructuredPatch> parsePatch(String uniDiff) {
  final diffLines = uniDiff.split('\n');
  final list = <StructuredPatch>[];
  var i = 0;

  StructuredPatch parseIndex() {
    var indexName = '';
    var oldFileName = '';
    var newFileName = '';
    String? oldHeader;
    String? newHeader;

    while (i < diffLines.length) {
      final line = diffLines[i];

      if (RegExp(r'^(---|\+\+\+|@@)\s').hasMatch(line)) {
        break;
      }

      final headerMatch = RegExp(
        r'^(?:Index:|diff(?: -r \w+)+)\s+',
      ).firstMatch(line);
      if (headerMatch != null) {
        indexName = line.substring(headerMatch.group(0)!.length).trim();
      }

      i++;
    }

    final oldHeaderData = _parseFileHeader(diffLines, i);
    if (oldHeaderData != null) {
      oldFileName = oldHeaderData.fileName;
      oldHeader = oldHeaderData.header;
      i++;
    }

    final newHeaderData = _parseFileHeader(diffLines, i);
    if (newHeaderData != null) {
      newFileName = newHeaderData.fileName;
      newHeader = newHeaderData.header;
      i++;
    }

    final hunks = <StructuredPatchHunk>[];

    while (i < diffLines.length) {
      final line = diffLines[i];

      if (RegExp(
        r'^(Index:\s|diff\s|---\s|\+\+\+\s|===================================================================)',
      ).hasMatch(line)) {
        break;
      }

      if (line.startsWith('@@')) {
        hunks.add(_parseHunk(diffLines, () => i, (value) => i = value));
        continue;
      }

      if (line.isNotEmpty) {
        throw StateError('Unknown line ${i + 1} ${_jsonQuoted(line)}');
      }

      i++;
    }

    return StructuredPatch(
      oldFileName: oldFileName,
      newFileName: newFileName,
      oldHeader: oldHeader,
      newHeader: newHeader,
      index: indexName.isEmpty ? null : indexName,
      hunks: hunks,
    );
  }

  while (i < diffLines.length) {
    list.add(parseIndex());
  }

  return list;
}

class _FileHeaderData {
  _FileHeaderData(this.fileName, this.header);

  final String fileName;
  final String header;
}

_FileHeaderData? _parseFileHeader(List<String> diffLines, int index) {
  if (index >= diffLines.length) {
    return null;
  }

  final line = diffLines[index];
  final match = RegExp(r'^(---|\+\+\+)\s+').firstMatch(line);
  if (match == null) {
    return null;
  }

  final data = line.substring(3).trim().split('\t');
  final header = data.length > 1 ? data.sublist(1).join('\t').trim() : '';
  var fileName = data.first.replaceAll(r'\\', r'\');
  if (fileName.startsWith('"') && fileName.endsWith('"')) {
    fileName = fileName.substring(1, fileName.length - 1);
  }

  return _FileHeaderData(fileName, header);
}

StructuredPatchHunk _parseHunk(
  List<String> diffLines,
  int Function() getIndex,
  void Function(int) setIndex,
) {
  final chunkHeaderIndex = getIndex();
  final chunkHeaderLine = diffLines[getIndex()];
  setIndex(getIndex() + 1);

  final match = RegExp(
    r'^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@',
  ).firstMatch(chunkHeaderLine);

  if (match == null) {
    throw StateError(
      'Invalid hunk header at line ${chunkHeaderIndex + 1}: $chunkHeaderLine',
    );
  }

  final hunk = StructuredPatchHunk(
    oldStart: int.parse(match.group(1)!),
    oldLines: match.group(2) == null ? 1 : int.parse(match.group(2)!),
    newStart: int.parse(match.group(3)!),
    newLines: match.group(4) == null ? 1 : int.parse(match.group(4)!),
    lines: <String>[],
  );

  if (hunk.oldLines == 0) {
    hunk.oldStart += 1;
  }
  if (hunk.newLines == 0) {
    hunk.newStart += 1;
  }

  var addCount = 0;
  var removeCount = 0;

  while (getIndex() < diffLines.length &&
      (removeCount < hunk.oldLines ||
          addCount < hunk.newLines ||
          diffLines[getIndex()].startsWith('\\'))) {
    final line = diffLines[getIndex()];
    final operation = (line.isEmpty && getIndex() != diffLines.length - 1)
        ? ' '
        : line[0];

    if (operation == '+' ||
        operation == '-' ||
        operation == ' ' ||
        operation == r'\') {
      hunk.lines.add(line);

      if (operation == '+') {
        addCount++;
      } else if (operation == '-') {
        removeCount++;
      } else if (operation == ' ') {
        addCount++;
        removeCount++;
      }
    } else {
      throw StateError(
        'Hunk at line ${chunkHeaderIndex + 1} contained invalid line $line',
      );
    }

    setIndex(getIndex() + 1);
  }

  if (addCount == 0 && hunk.newLines == 1) {
    hunk.newLines = 0;
  }

  if (removeCount == 0 && hunk.oldLines == 1) {
    hunk.oldLines = 0;
  }

  if (addCount != hunk.newLines) {
    throw StateError(
      'Added line count did not match for hunk at line ${chunkHeaderIndex + 1}',
    );
  }

  if (removeCount != hunk.oldLines) {
    throw StateError(
      'Removed line count did not match for hunk at line ${chunkHeaderIndex + 1}',
    );
  }

  return hunk;
}

String _jsonQuoted(String value) {
  return '"${value.replaceAll('"', '\\"')}"';
}
