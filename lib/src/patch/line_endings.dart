import '../models/patch.dart';

StructuredPatch unixToWinPatch(StructuredPatch patch) {
  return StructuredPatch(
    oldFileName: patch.oldFileName,
    newFileName: patch.newFileName,
    oldHeader: patch.oldHeader,
    newHeader: patch.newHeader,
    index: patch.index,
    hunks: patch.hunks
        .map(
          (hunk) => StructuredPatchHunk(
            oldStart: hunk.oldStart,
            oldLines: hunk.oldLines,
            newStart: hunk.newStart,
            newLines: hunk.newLines,
            lines: List<String>.generate(hunk.lines.length, (i) {
              final line = hunk.lines[i];
              if (line.startsWith('\\') ||
                  line.endsWith('\r') ||
                  (i + 1 < hunk.lines.length &&
                      hunk.lines[i + 1].startsWith('\\'))) {
                return line;
              }
              return '$line\r';
            }),
          ),
        )
        .toList(),
  );
}

List<StructuredPatch> unixToWinPatches(List<StructuredPatch> patches) {
  return patches.map(unixToWinPatch).toList();
}

StructuredPatch winToUnixPatch(StructuredPatch patch) {
  return StructuredPatch(
    oldFileName: patch.oldFileName,
    newFileName: patch.newFileName,
    oldHeader: patch.oldHeader,
    newHeader: patch.newHeader,
    index: patch.index,
    hunks: patch.hunks
        .map(
          (hunk) => StructuredPatchHunk(
            oldStart: hunk.oldStart,
            oldLines: hunk.oldLines,
            newStart: hunk.newStart,
            newLines: hunk.newLines,
            lines: hunk.lines
                .map(
                  (line) => line.endsWith('\r')
                      ? line.substring(0, line.length - 1)
                      : line,
                )
                .toList(),
          ),
        )
        .toList(),
  );
}

List<StructuredPatch> winToUnixPatches(List<StructuredPatch> patches) {
  return patches.map(winToUnixPatch).toList();
}

bool isUnixPatch(dynamic patch) {
  final patches = patch is List<StructuredPatch>
      ? patch
      : <StructuredPatch>[patch as StructuredPatch];
  return !patches.any(
    (index) => index.hunks.any(
      (hunk) => hunk.lines.any(
        (line) => !line.startsWith('\\') && line.endsWith('\r'),
      ),
    ),
  );
}

bool isWinPatch(dynamic patch) {
  final patches = patch is List<StructuredPatch>
      ? patch
      : <StructuredPatch>[patch as StructuredPatch];

  final hasWin = patches.any(
    (index) => index.hunks.any(
      (hunk) => hunk.lines.any((line) => line.endsWith('\r')),
    ),
  );

  final allConsistent = patches.every(
    (index) => index.hunks.every(
      (hunk) => hunk.lines.asMap().entries.every((entry) {
        final line = entry.value;
        final i = entry.key;
        return line.startsWith('\\') ||
            line.endsWith('\r') ||
            (i + 1 < hunk.lines.length && hunk.lines[i + 1].startsWith('\\'));
      }),
    ),
  );

  return hasWin && allConsistent;
}

dynamic unixToWin(dynamic patch) {
  if (patch is List<StructuredPatch>) {
    return unixToWinPatches(patch);
  }
  return unixToWinPatch(patch as StructuredPatch);
}

dynamic winToUnix(dynamic patch) {
  if (patch is List<StructuredPatch>) {
    return winToUnixPatches(patch);
  }
  return winToUnixPatch(patch as StructuredPatch);
}

bool isUnix(dynamic patch) {
  return isUnixPatch(patch);
}

bool isWin(dynamic patch) {
  return isWinPatch(patch);
}
