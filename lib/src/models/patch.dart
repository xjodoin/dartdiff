// ignore_for_file: constant_identifier_names

class StructuredPatch {
  StructuredPatch({
    required this.oldFileName,
    required this.newFileName,
    required this.hunks,
    this.oldHeader,
    this.newHeader,
    this.index,
  });

  String oldFileName;
  String newFileName;
  String? oldHeader;
  String? newHeader;
  String? index;
  List<StructuredPatchHunk> hunks;
}

class StructuredPatchHunk {
  StructuredPatchHunk({
    required this.oldStart,
    required this.oldLines,
    required this.newStart,
    required this.newLines,
    required this.lines,
  });

  int oldStart;
  int oldLines;
  int newStart;
  int newLines;
  List<String> lines;
}

class HeaderOptions {
  const HeaderOptions({
    required this.includeIndex,
    required this.includeUnderline,
    required this.includeFileHeaders,
  });

  final bool includeIndex;
  final bool includeUnderline;
  final bool includeFileHeaders;
}

const HeaderOptions includeHeaders = HeaderOptions(
  includeIndex: true,
  includeUnderline: true,
  includeFileHeaders: true,
);
const HeaderOptions INCLUDE_HEADERS = includeHeaders;

const HeaderOptions fileHeadersOnly = HeaderOptions(
  includeIndex: false,
  includeUnderline: false,
  includeFileHeaders: true,
);
const HeaderOptions FILE_HEADERS_ONLY = fileHeadersOnly;

const HeaderOptions omitHeaders = HeaderOptions(
  includeIndex: false,
  includeUnderline: false,
  includeFileHeaders: false,
);
const HeaderOptions OMIT_HEADERS = omitHeaders;
