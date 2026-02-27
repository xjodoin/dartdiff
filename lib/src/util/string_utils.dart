String longestCommonPrefix(String str1, String str2) {
  var i = 0;
  for (; i < str1.length && i < str2.length; i++) {
    if (str1[i] != str2[i]) {
      return str1.substring(0, i);
    }
  }
  return str1.substring(0, i);
}

String longestCommonSuffix(String str1, String str2) {
  if (str1.isEmpty ||
      str2.isEmpty ||
      str1[str1.length - 1] != str2[str2.length - 1]) {
    return '';
  }

  var i = 0;
  for (; i < str1.length && i < str2.length; i++) {
    if (str1[str1.length - (i + 1)] != str2[str2.length - (i + 1)]) {
      return str1.substring(str1.length - i);
    }
  }

  return str1.substring(str1.length - i);
}

String replacePrefix(String string, String oldPrefix, String newPrefix) {
  if (!string.startsWith(oldPrefix)) {
    throw StateError(
      'string ${_quoted(string)} does not start with prefix ${_quoted(oldPrefix)}',
    );
  }
  return '$newPrefix${string.substring(oldPrefix.length)}';
}

String replaceSuffix(String string, String oldSuffix, String newSuffix) {
  if (oldSuffix.isEmpty) {
    return '$string$newSuffix';
  }
  if (!string.endsWith(oldSuffix)) {
    throw StateError(
      'string ${_quoted(string)} does not end with suffix ${_quoted(oldSuffix)}',
    );
  }
  return '${string.substring(0, string.length - oldSuffix.length)}$newSuffix';
}

String removePrefix(String string, String oldPrefix) {
  return replacePrefix(string, oldPrefix, '');
}

String removeSuffix(String string, String oldSuffix) {
  return replaceSuffix(string, oldSuffix, '');
}

String maximumOverlap(String string1, String string2) {
  return string2.substring(0, overlapCount(string1, string2));
}

int overlapCount(String a, String b) {
  if (a.isEmpty || b.isEmpty) {
    return 0;
  }

  var startA = 0;
  if (a.length > b.length) {
    startA = a.length - b.length;
  }

  var endB = b.length;
  if (a.length < b.length) {
    endB = a.length;
  }

  final map = List<int>.filled(endB, 0);
  var k = 0;

  if (endB > 0) {
    map[0] = 0;
  }

  for (var j = 1; j < endB; j++) {
    if (b[j] == b[k]) {
      map[j] = map[k];
    } else {
      map[j] = k;
    }

    while (k > 0 && b[j] != b[k]) {
      k = map[k];
    }
    if (b[j] == b[k]) {
      k++;
    }
  }

  k = 0;
  for (var i = startA; i < a.length; i++) {
    while (k > 0 && a[i] != b[k]) {
      k = map[k];
    }
    if (a[i] == b[k]) {
      k++;
      if (k == endB) {
        return k;
      }
    }
  }

  return k;
}

bool hasOnlyWinLineEndings(String input) {
  return input.contains('\r\n') &&
      !input.startsWith('\n') &&
      !RegExp(r'[^\r]\n').hasMatch(input);
}

bool hasOnlyUnixLineEndings(String input) {
  return !input.contains('\r\n') && input.contains('\n');
}

String trailingWs(String string) {
  var i = string.length - 1;
  while (i >= 0) {
    if (!RegExp(r'\s').hasMatch(string[i])) {
      break;
    }
    i--;
  }
  return string.substring(i + 1);
}

String leadingWs(String string) {
  final match = RegExp(r'^\s*').firstMatch(string);
  return match?.group(0) ?? '';
}

List<String> leadingAndTrailingWs(String string) {
  return [leadingWs(string), trailingWs(string)];
}

List<String> splitKeepingDelimiters(String input, RegExp pattern) {
  final parts = <String>[];
  var index = 0;
  for (final match in pattern.allMatches(input)) {
    if (match.start > index) {
      parts.add(input.substring(index, match.start));
    }
    final delimiter = match.group(0);
    if (delimiter != null && delimiter.isNotEmpty) {
      parts.add(delimiter);
    }
    index = match.end;
  }
  if (index < input.length) {
    parts.add(input.substring(index));
  }
  return parts;
}

String _quoted(String value) {
  final escaped = value
      .replaceAll(r'\', r'\\')
      .replaceAll('"', r'\"')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r');
  return '"$escaped"';
}
