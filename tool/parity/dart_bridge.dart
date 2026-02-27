import 'dart:convert';
import 'dart:io';

import 'invoke.dart';

Future<void> main() async {
  final input = await stdin.transform(utf8.decoder).join();
  if (input.trim().isEmpty) {
    stdout.write(jsonEncode({'ok': false, 'error': 'empty input'}));
    return;
  }

  try {
    final payload = jsonDecode(input) as Map<String, dynamic>;
    final fn = payload['fn'] as String;
    final args = (payload['args'] as List?) ?? const [];
    final result = invokeCall(fn, args.cast<dynamic>());
    stdout.write(jsonEncode({'ok': true, 'result': toJsonValue(result)}));
  } catch (error, stack) {
    stdout.write(
      jsonEncode({
        'ok': false,
        'error': error.toString(),
        'stack': stack.toString(),
      }),
    );
  }
}
