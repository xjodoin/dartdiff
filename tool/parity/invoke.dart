import 'package:dartdiff/dartdiff.dart';

// ignore_for_file: avoid_dynamic_calls

dynamic invokeCall(String fn, List<dynamic> args) {
  switch (fn) {
    case 'diffChars':
      return diffChars(
        args[0] as String,
        args[1] as String,
        ignoreCase: _boolOpt(args, 2, 'ignoreCase'),
        oneChangePerToken: _boolOpt(args, 2, 'oneChangePerToken'),
        timeout: _intOpt(args, 2, 'timeout'),
        maxEditLength: _intOpt(args, 2, 'maxEditLength'),
      );

    case 'diffWords':
      return diffWords(
        args[0] as String,
        args[1] as String,
        ignoreCase: _boolOpt(args, 2, 'ignoreCase'),
        oneChangePerToken: _boolOpt(args, 2, 'oneChangePerToken'),
        timeout: _intOpt(args, 2, 'timeout'),
        maxEditLength: _intOpt(args, 2, 'maxEditLength'),
        ignoreWhitespace: _boolNullableOpt(args, 2, 'ignoreWhitespace'),
      );

    case 'diffWordsWithSpace':
      return diffWordsWithSpace(
        args[0] as String,
        args[1] as String,
        ignoreCase: _boolOpt(args, 2, 'ignoreCase'),
        oneChangePerToken: _boolOpt(args, 2, 'oneChangePerToken'),
        timeout: _intOpt(args, 2, 'timeout'),
        maxEditLength: _intOpt(args, 2, 'maxEditLength'),
      );

    case 'wordDiff.tokenize':
      return wordDiff.tokenize(
        args[0] as String,
        const DiffComputationOptions<String>(),
      );

    case 'diffLines':
      return diffLines(
        args[0] as String,
        args[1] as String,
        oneChangePerToken: _boolOpt(args, 2, 'oneChangePerToken'),
        ignoreCase: _boolOpt(args, 2, 'ignoreCase'),
        ignoreWhitespace: _boolOpt(args, 2, 'ignoreWhitespace'),
        ignoreNewlineAtEof: _boolOpt(args, 2, 'ignoreNewlineAtEof'),
        stripTrailingCr: _boolOpt(args, 2, 'stripTrailingCr'),
        newlineIsToken: _boolOpt(args, 2, 'newlineIsToken'),
        timeout: _intOpt(args, 2, 'timeout'),
        maxEditLength: _intOpt(args, 2, 'maxEditLength'),
      );

    case 'diffTrimmedLines':
      return diffTrimmedLines(
        args[0] as String,
        args[1] as String,
        oneChangePerToken: _boolOpt(args, 2, 'oneChangePerToken'),
        ignoreCase: _boolOpt(args, 2, 'ignoreCase'),
        ignoreNewlineAtEof: _boolOpt(args, 2, 'ignoreNewlineAtEof'),
        stripTrailingCr: _boolOpt(args, 2, 'stripTrailingCr'),
        newlineIsToken: _boolOpt(args, 2, 'newlineIsToken'),
        timeout: _intOpt(args, 2, 'timeout'),
        maxEditLength: _intOpt(args, 2, 'maxEditLength'),
      );

    case 'diffSentences':
      return diffSentences(
        args[0] as String,
        args[1] as String,
        oneChangePerToken: _boolOpt(args, 2, 'oneChangePerToken'),
        timeout: _intOpt(args, 2, 'timeout'),
        maxEditLength: _intOpt(args, 2, 'maxEditLength'),
      );

    case 'sentenceDiff.tokenize':
      return sentenceDiff.tokenize(
        args[0] as String,
        const DiffComputationOptions<String>(),
      );

    case 'diffCss':
      return diffCss(
        args[0] as String,
        args[1] as String,
        oneChangePerToken: _boolOpt(args, 2, 'oneChangePerToken'),
        timeout: _intOpt(args, 2, 'timeout'),
        maxEditLength: _intOpt(args, 2, 'maxEditLength'),
      );

    case 'diffJson':
      return diffJson(
        args[0],
        args[1],
        oneChangePerToken: _boolOpt(args, 2, 'oneChangePerToken'),
        ignoreCase: _boolOpt(args, 2, 'ignoreCase'),
        ignoreWhitespace: _boolOpt(args, 2, 'ignoreWhitespace'),
        ignoreNewlineAtEof: _boolOpt(args, 2, 'ignoreNewlineAtEof'),
        stripTrailingCr: _boolOpt(args, 2, 'stripTrailingCr'),
        newlineIsToken: _boolOpt(args, 2, 'newlineIsToken'),
        timeout: _intOpt(args, 2, 'timeout'),
        maxEditLength: _intOpt(args, 2, 'maxEditLength'),
      );

    case 'diffArrays':
      return diffArrays<dynamic>(
        (args[0] as List).cast<dynamic>(),
        (args[1] as List).cast<dynamic>(),
        oneChangePerToken: _boolOpt(args, 2, 'oneChangePerToken'),
        timeout: _intOpt(args, 2, 'timeout'),
        maxEditLength: _intOpt(args, 2, 'maxEditLength'),
      );

    case 'structuredPatch':
      return structuredPatch(
        args[0] as String,
        args[1] as String,
        args[2] as String,
        args[3] as String,
        oldHeader: args.length > 4 ? args[4] as String? : null,
        newHeader: args.length > 5 ? args[5] as String? : null,
        context: _intOpt(args, 6, 'context') ?? 4,
        ignoreWhitespace: _boolOpt(args, 6, 'ignoreWhitespace'),
        stripTrailingCr: _boolOpt(args, 6, 'stripTrailingCr'),
        newlineIsToken: _boolOpt(args, 6, 'newlineIsToken'),
        timeout: _intOpt(args, 6, 'timeout'),
        maxEditLength: _intOpt(args, 6, 'maxEditLength'),
      );

    case 'createTwoFilesPatch':
      return createTwoFilesPatch(
        args[0] as String,
        args[1] as String,
        args[2] as String,
        args[3] as String,
        oldHeader: args.length > 4 ? args[4] as String? : null,
        newHeader: args.length > 5 ? args[5] as String? : null,
        context: _intOpt(args, 6, 'context') ?? 4,
        ignoreWhitespace: _boolOpt(args, 6, 'ignoreWhitespace'),
        stripTrailingCr: _boolOpt(args, 6, 'stripTrailingCr'),
        timeout: _intOpt(args, 6, 'timeout'),
        maxEditLength: _intOpt(args, 6, 'maxEditLength'),
        headerOptions: _headerOptions(_mapOpt(args, 6, 'headerOptions')),
      );

    case 'createPatch':
      return createPatch(
        args[0] as String,
        args[1] as String,
        args[2] as String,
        oldHeader: args.length > 3 ? args[3] as String? : null,
        newHeader: args.length > 4 ? args[4] as String? : null,
        context: _intOpt(args, 5, 'context') ?? 4,
        ignoreWhitespace: _boolOpt(args, 5, 'ignoreWhitespace'),
        stripTrailingCr: _boolOpt(args, 5, 'stripTrailingCr'),
        timeout: _intOpt(args, 5, 'timeout'),
        maxEditLength: _intOpt(args, 5, 'maxEditLength'),
        headerOptions: _headerOptions(_mapOpt(args, 5, 'headerOptions')),
      );

    case 'formatPatch':
      return formatPatch(
        _patchInput(args[0]),
        headerOptions: _headerOptions(
          args.length > 1 ? args[1] as Map<String, dynamic>? : null,
        ),
      );

    case 'parsePatch':
      return parsePatch(args[0] as String);

    case 'applyPatch':
      final patch = args[1];
      return applyPatch(
        args[0] as String,
        patch is String ? patch : _patchInput(patch),
        fuzzFactor: _intOpt(args, 2, 'fuzzFactor') ?? 0,
        autoConvertLineEndings: _boolOpt(
          args,
          2,
          'autoConvertLineEndings',
          defaultValue: true,
        ),
      );

    case 'reversePatch':
      final patch = args[0];
      if (patch is List) {
        return reversePatches(
          patch
              .map((e) => _structuredPatchFromJson(e as Map<String, dynamic>))
              .toList(),
        );
      }
      return reversePatch(
        _structuredPatchFromJson(patch as Map<String, dynamic>),
      );

    case 'unixToWin':
      final patch = args[0];
      return patch is List
          ? unixToWinPatches(
              patch
                  .map(
                    (e) => _structuredPatchFromJson(e as Map<String, dynamic>),
                  )
                  .toList(),
            )
          : unixToWinPatch(
              _structuredPatchFromJson(patch as Map<String, dynamic>),
            );

    case 'winToUnix':
      final patch = args[0];
      return patch is List
          ? winToUnixPatches(
              patch
                  .map(
                    (e) => _structuredPatchFromJson(e as Map<String, dynamic>),
                  )
                  .toList(),
            )
          : winToUnixPatch(
              _structuredPatchFromJson(patch as Map<String, dynamic>),
            );

    case 'isUnix':
      final patch = args[0];
      return patch is List
          ? isUnixPatch(
              patch
                  .map(
                    (e) => _structuredPatchFromJson(e as Map<String, dynamic>),
                  )
                  .toList(),
            )
          : isUnixPatch(
              _structuredPatchFromJson(patch as Map<String, dynamic>),
            );

    case 'isWin':
      final patch = args[0];
      return patch is List
          ? isWinPatch(
              patch
                  .map(
                    (e) => _structuredPatchFromJson(e as Map<String, dynamic>),
                  )
                  .toList(),
            )
          : isWinPatch(_structuredPatchFromJson(patch as Map<String, dynamic>));

    case 'convertChangesToDMP':
      return convertChangesToDMP(_changesFromJson(args[0] as List));

    case 'convertChangesToXML':
      return convertChangesToXML(_stringChangesFromJson(args[0] as List));

    case 'longestCommonPrefix':
      return longestCommonPrefix(args[0] as String, args[1] as String);

    case 'longestCommonSuffix':
      return longestCommonSuffix(args[0] as String, args[1] as String);

    case 'replacePrefix':
      return replacePrefix(
        args[0] as String,
        args[1] as String,
        args[2] as String,
      );

    case 'replaceSuffix':
      return replaceSuffix(
        args[0] as String,
        args[1] as String,
        args[2] as String,
      );

    case 'removePrefix':
      return removePrefix(args[0] as String, args[1] as String);

    case 'removeSuffix':
      return removeSuffix(args[0] as String, args[1] as String);

    case 'maximumOverlap':
      return maximumOverlap(args[0] as String, args[1] as String);

    case 'leadingWs':
      return leadingWs(args[0] as String);

    case 'trailingWs':
      return trailingWs(args[0] as String);

    default:
      throw UnsupportedError('Unsupported bridge function: $fn');
  }
}

dynamic toJsonValue(dynamic value) {
  if (value is Change) {
    return {
      'value': toJsonValue(value.value),
      'added': value.added,
      'removed': value.removed,
      'count': value.count,
    };
  }

  if (value is StructuredPatch) {
    return {
      'oldFileName': value.oldFileName,
      'newFileName': value.newFileName,
      'oldHeader': value.oldHeader,
      'newHeader': value.newHeader,
      'index': value.index,
      'hunks': value.hunks.map(toJsonValue).toList(),
    };
  }

  if (value is StructuredPatchHunk) {
    return {
      'oldStart': value.oldStart,
      'oldLines': value.oldLines,
      'newStart': value.newStart,
      'newLines': value.newLines,
      'lines': value.lines,
    };
  }

  if (value is List) {
    return value.map(toJsonValue).toList();
  }

  if (value is Map) {
    final keys = value.keys.map((k) => k.toString()).toList()..sort();
    final out = <String, dynamic>{};
    for (final key in keys) {
      out[key] = toJsonValue(value[key]);
    }
    return out;
  }

  if (value is (int, dynamic)) {
    return [value.$1, toJsonValue(value.$2)];
  }

  return value;
}

dynamic _patchInput(dynamic value) {
  if (value is List) {
    return value
        .map((e) => _structuredPatchFromJson(e as Map<String, dynamic>))
        .toList();
  }
  return _structuredPatchFromJson(value as Map<String, dynamic>);
}

StructuredPatch _structuredPatchFromJson(Map<String, dynamic> json) {
  return StructuredPatch(
    oldFileName: (json['oldFileName'] ?? '') as String,
    newFileName: (json['newFileName'] ?? '') as String,
    oldHeader: json['oldHeader'] as String?,
    newHeader: json['newHeader'] as String?,
    index: json['index'] as String?,
    hunks: (json['hunks'] as List)
        .map((e) => _structuredPatchHunkFromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

StructuredPatchHunk _structuredPatchHunkFromJson(Map<String, dynamic> json) {
  return StructuredPatchHunk(
    oldStart: (json['oldStart'] as num).toInt(),
    oldLines: (json['oldLines'] as num).toInt(),
    newStart: (json['newStart'] as num).toInt(),
    newLines: (json['newLines'] as num).toInt(),
    lines: (json['lines'] as List).map((e) => e as String).toList(),
  );
}

HeaderOptions _headerOptions(Map<String, dynamic>? value) {
  if (value == null) {
    return INCLUDE_HEADERS;
  }
  return HeaderOptions(
    includeIndex: (value['includeIndex'] ?? true) == true,
    includeUnderline: (value['includeUnderline'] ?? true) == true,
    includeFileHeaders: (value['includeFileHeaders'] ?? true) == true,
  );
}

List<Change<dynamic>> _changesFromJson(List<dynamic> list) {
  return list
      .map(
        (item) => Change<dynamic>(
          value: (item as Map<String, dynamic>)['value'],
          count: ((item)['count'] as num).toInt(),
          added: (item['added'] ?? false) == true,
          removed: (item['removed'] ?? false) == true,
        ),
      )
      .toList();
}

List<Change<String>> _stringChangesFromJson(List<dynamic> list) {
  return list
      .map(
        (item) => Change<String>(
          value: (item as Map<String, dynamic>)['value'] as String,
          count: ((item)['count'] as num).toInt(),
          added: (item['added'] ?? false) == true,
          removed: (item['removed'] ?? false) == true,
        ),
      )
      .toList();
}

Map<String, dynamic> _optionMap(List<dynamic> args, int index) {
  if (args.length <= index || args[index] == null) {
    return const {};
  }

  final value = args[index];
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }

  return const {};
}

Map<String, dynamic>? _mapOpt(List<dynamic> args, int index, String key) {
  final map = _optionMap(args, index);
  final value = map[key];
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  return null;
}

bool _boolOpt(
  List<dynamic> args,
  int index,
  String key, {
  bool defaultValue = false,
}) {
  final map = _optionMap(args, index);
  final value = map[key];
  if (value is bool) {
    return value;
  }
  return defaultValue;
}

bool? _boolNullableOpt(List<dynamic> args, int index, String key) {
  final map = _optionMap(args, index);
  final value = map[key];
  if (value is bool) {
    return value;
  }
  return null;
}

int? _intOpt(List<dynamic> args, int index, String key) {
  final map = _optionMap(args, index);
  final value = map[key];
  if (value is num) {
    return value.toInt();
  }
  return null;
}
