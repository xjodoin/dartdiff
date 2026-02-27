# dartdiff

Pure Dart text differencing and unified patching inspired by `jsdiff`.

## Implemented APIs

- `diffChars`
- `diffWords`
- `diffWordsWithSpace`
- `diffLines`
- `diffTrimmedLines`
- `diffSentences`
- `diffCss`
- `diffJson`
- `diffArrays`
- `structuredPatch`
- `createPatch`
- `createTwoFilesPatch`
- `formatPatch`
- `parsePatch`
- `applyPatch`
- `applyPatches`
- `reversePatch`
- `unixToWin` / `winToUnix` / `isUnix` / `isWin`
- `convertChangesToDMP` / `convertChangesToXML`

## Usage

```dart
import 'package:dartdiff/dartdiff.dart';

void main() {
  final changes = diffChars('Old Value.', 'New ValueMoreData.');
  if (changes != null) {
    print(convertChangesToXML(changes));
  }

  final patch = createPatch('file.txt', 'a\nb\n', 'a\nc\n');
  if (patch != null) {
    final patched = applyPatch('a\nb\n', patch);
    print(patched); // a\nc\n
  }
}
```

## Notes

- Diff functions return `null` when `maxEditLength` or `timeout` aborts computation.
- `applyPatch` returns `null` when a patch cannot be applied.
- A custom `wordTokenizer` hook is available on `diffWords` to customize tokenization.

## Upstream jsdiff Test Corpus

`dartdiff` includes a converted fixture derived from the upstream `jsdiff` test corpus:

- Fixture: `test/data/upstream_cases.json`
- Dart replay test: `test/upstream_converted_cases_test.dart`
- Fixture integrity test: `test/upstream_parity_test.dart`

Fixture regeneration utilities are still available under `tool/parity/` (Node + jsdiff harness) when you want to refresh against upstream.
