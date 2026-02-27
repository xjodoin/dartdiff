# dartdiff Port Plan

## Goal
Build a pure Dart port of [`jsdiff`](../jsdiff) with behavior parity for core diffing and unified patch workflows.

## Source Analysis Summary
- Core Myers engine is concentrated in `src/diff/base.ts` (~366 LOC).
- Highest-risk modules by size + test load:
  - `src/patch/create.ts` (~522 LOC), `test/patch/create.js` (43 tests)
  - `src/patch/apply.ts` (~366 LOC), `test/patch/apply.js` (58 tests)
  - `src/diff/word.ts` (~368 LOC), `test/diff/word.js` (45 tests)
- Supporting modules are smaller and good early wins:
  - `diff/character`, `diff/css`, `diff/array`, `convert/dmp`, `convert/xml`, utility modules.

## Proposed Dart Package Shape
- `lib/dartdiff.dart`
- `lib/src/core/diff_engine.dart`
- `lib/src/models/change.dart`
- `lib/src/diff/character_diff.dart`
- `lib/src/diff/word_diff.dart`
- `lib/src/diff/line_diff.dart`
- `lib/src/diff/sentence_diff.dart`
- `lib/src/diff/css_diff.dart`
- `lib/src/diff/json_diff.dart`
- `lib/src/diff/array_diff.dart`
- `lib/src/patch/create_patch.dart`
- `lib/src/patch/parse_patch.dart`
- `lib/src/patch/apply_patch.dart`
- `lib/src/patch/reverse_patch.dart`
- `lib/src/patch/line_endings.dart`
- `lib/src/convert/xml.dart`
- `lib/src/convert/dmp.dart`
- `test/` mirrored by module.

## Phased Execution Plan

### Phase 0: Baseline and Compatibility Contracts
- Lock API names and return types for a Dart-first surface similar to jsdiff.
- Decide sync-only vs sync+async wrappers:
  - Recommend sync implementation first.
  - Add async wrappers (`Future`) after correctness.
- Define known parity deltas up front:
  - `Intl.Segmenter` option in `diffWords` has no direct Dart equivalent.
  - Introduce optional custom tokenizer hook as Dart replacement.

### Phase 1: Core Engine + Basic Diff APIs
- Port Myers implementation from `src/diff/base.ts`.
- Port:
  - `diffChars`
  - `diffArrays` with comparator
  - `diffCss`
  - `diffSentences`
- Port converters:
  - `convertChangesToXML`
  - `convertChangesToDMP`
- Add unit tests for each with direct parity fixtures.

Exit criteria:
- Core change-object semantics match jsdiff on fixed fixtures.
- Unicode code point behavior validated for `diffChars`.

### Phase 2: Line and JSON Diff
- Port line tokenization and options:
  - `ignoreWhitespace`
  - `ignoreNewlineAtEof`
  - `stripTrailingCr`
  - `newlineIsToken`
- Port `diffTrimmedLines`.
- Port `diffJson` + canonicalization:
  - stable key sort
  - nested structures
  - circular reference behavior
  - replacer support.

Exit criteria:
- All line/json fixture cases passing, including EOF/newline edge cases.

### Phase 3: Word Diff Parity (Hard Part)
- Port regex/tokenization behavior including extended word-char ranges.
- Port whitespace post-processing (`dedupeWhitespaceInChangeObjects`).
- Add optional Dart hook to emulate `intlSegmenter` behavior where possible.

Exit criteria:
- Match jsdiff outputs for high-sensitivity whitespace and punctuation tests.

### Phase 4: Patch Stack
- Port:
  - `structuredPatch`
  - `createPatch` / `createTwoFilesPatch` / `formatPatch`
  - `parsePatch`
  - `applyPatch` / `applyPatches`
  - `reversePatch`
  - line-ending transforms (`unixToWin`, `winToUnix`, `isUnix`, `isWin`)
- Preserve behavior for:
  - fuzz factor
  - hunk offset search
  - EOF newline markers
  - multi-file patch handling.

Exit criteria:
- Patch tests pass, especially large and edge-condition cases.

### Phase 5: Differential + Property Testing
- Add a Node-based oracle harness that runs official jsdiff and compares Dart output on random and curated cases.
- Add regression corpus from upstream tests.
- Track and document intentional differences.

Exit criteria:
- Zero unexpected diffs in compatibility matrix.

### Phase 6: Package Hardening and Release
- Finalize docs with parity matrix and limitations.
- Add benchmarks (small/medium/large inputs).
- CI checks:
  - `dart format --set-exit-if-changed .`
  - `dart analyze`
  - `dart test`
- Publish as `0.1.0` (or `0.0.x` if keeping API experimental).

## Recommended Build Order
1. Engine + character/array/css/sentence
2. line + json
3. word
4. patch parse/create
5. patch apply/reverse/line-endings
6. differential test harness + release polish

## Risks and Mitigations
- Word tokenization parity risk:
  - Copy regex semantics exactly and freeze fixtures early.
- Patch application complexity:
  - Port with stepwise tests and keep algorithm structure close to source.
- Runtime performance on large diffs:
  - Add benchmark thresholds and optional early-abort options (`timeout`, `maxEditLength`) once sync parity is stable.

## Initial Milestone Definition (first implementation PR)
- Deliverables:
  - Core engine
  - `diffChars`, `diffArrays`, `diffCss`, `diffSentences`
  - `convertChangesToXML`, `convertChangesToDMP`
  - baseline tests and CI wiring
- Target: complete and green before starting word/patch modules.
