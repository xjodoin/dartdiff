import '../models/patch.dart';

StructuredPatch reversePatch(StructuredPatch structuredPatch) {
  return StructuredPatch(
    oldFileName: structuredPatch.newFileName,
    newFileName: structuredPatch.oldFileName,
    oldHeader: structuredPatch.newHeader,
    newHeader: structuredPatch.oldHeader,
    index: structuredPatch.index,
    hunks: structuredPatch.hunks
        .map(
          (hunk) => StructuredPatchHunk(
            oldLines: hunk.newLines,
            oldStart: hunk.newStart,
            newLines: hunk.oldLines,
            newStart: hunk.oldStart,
            lines: hunk.lines.map((line) {
              if (line.startsWith('-')) {
                return '+${line.substring(1)}';
              }
              if (line.startsWith('+')) {
                return '-${line.substring(1)}';
              }
              return line;
            }).toList(),
          ),
        )
        .toList(),
  );
}

List<StructuredPatch> reversePatches(List<StructuredPatch> patches) {
  return patches.map(reversePatch).toList().reversed.toList();
}
