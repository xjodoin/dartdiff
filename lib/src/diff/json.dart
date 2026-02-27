import 'dart:convert';

import '../core/diff_base.dart';
import '../core/diff_options.dart';
import '../models/change.dart';
import 'line.dart';

class JsonDiff extends DiffBase<String, String, Object?> {
  const JsonDiff();

  @override
  bool get useLongestToken => true;

  @override
  List<String> tokenize(String value, DiffComputationOptions<String> options) {
    return tokenizeLines(
      value,
      stripTrailingCr: options.extra<bool>('stripTrailingCr') ?? false,
      newlineIsToken: options.extra<bool>('newlineIsToken') ?? false,
    );
  }

  @override
  String castInput(Object? value, DiffComputationOptions<String> options) {
    final replacer = options.extra<Object? Function(String key, Object? value)>(
      'stringifyReplacer',
    );

    if (value is String) {
      return value;
    }

    final encoder = const JsonEncoder.withIndent('  ');
    final canonical = canonicalize(
      value,
      replacer: replacer,
      undefinedReplacement: options.extra<Object?>('undefinedReplacement'),
    );

    return encoder.convert(canonical);
  }

  @override
  bool equals(
    String left,
    String right,
    DiffComputationOptions<String> options,
  ) {
    return super.equals(
      left.replaceAllMapped(RegExp(r',([\r\n])'), (match) => match.group(1)!),
      right.replaceAllMapped(RegExp(r',([\r\n])'), (match) => match.group(1)!),
      options,
    );
  }
}

const jsonDiff = JsonDiff();

List<Change<String>>? diffJson(
  Object? oldObj,
  Object? newObj, {
  bool oneChangePerToken = false,
  bool ignoreCase = false,
  bool ignoreWhitespace = false,
  bool ignoreNewlineAtEof = false,
  bool stripTrailingCr = false,
  bool newlineIsToken = false,
  int? timeout,
  int? maxEditLength,
  Object? Function(String key, Object? value)? stringifyReplacer,
  Object? undefinedReplacement,
}) {
  return jsonDiff.diff(
    oldObj,
    newObj,
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
        'stringifyReplacer': stringifyReplacer,
        'undefinedReplacement': undefinedReplacement,
      },
    ),
  );
}

Object? canonicalize(
  Object? obj, {
  List<Object?>? stack,
  List<Object?>? replacementStack,
  Object? Function(String key, Object? value)? replacer,
  String? key,
  Object? undefinedReplacement,
}) {
  stack ??= <Object?>[];
  replacementStack ??= <Object?>[];

  if (replacer != null) {
    obj = replacer(key ?? '', obj);
  }

  for (var i = 0; i < stack.length; i++) {
    if (identical(stack[i], obj)) {
      return replacementStack[i];
    }
  }

  if (obj is List) {
    stack.add(obj);
    final canonicalized = List<Object?>.filled(obj.length, null);
    replacementStack.add(canonicalized);

    for (var i = 0; i < obj.length; i++) {
      canonicalized[i] = canonicalize(
        obj[i],
        stack: stack,
        replacementStack: replacementStack,
        replacer: replacer,
        key: '$i',
        undefinedReplacement: undefinedReplacement,
      );
    }

    stack.removeLast();
    replacementStack.removeLast();
    return canonicalized;
  }

  if (obj != null &&
      obj is! Map &&
      obj is! String &&
      obj is! num &&
      obj is! bool) {
    try {
      final converted = (obj as dynamic).toJson();
      obj = converted;
    } catch (_) {
      // No toJson support; keep as-is.
    }
  }

  if (obj is Map) {
    stack.add(obj);
    final canonicalized = <String, Object?>{};
    replacementStack.add(canonicalized);

    final sortedKeys = obj.keys.map((key) => key.toString()).toList()..sort();
    for (final sortedKey in sortedKeys) {
      Object? sourceKey;
      for (final key in obj.keys) {
        if (key.toString() == sortedKey) {
          sourceKey = key;
          break;
        }
      }

      final value = sourceKey == null ? null : obj[sourceKey];
      canonicalized[sortedKey] = canonicalize(
        value,
        stack: stack,
        replacementStack: replacementStack,
        replacer: replacer,
        key: sortedKey,
        undefinedReplacement: undefinedReplacement,
      );
    }

    stack.removeLast();
    replacementStack.removeLast();
    return canonicalized;
  }

  return obj;
}
