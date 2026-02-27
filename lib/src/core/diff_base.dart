import '../models/change.dart';
import 'diff_options.dart';

class _DraftChangeObject {
  _DraftChangeObject({
    required this.added,
    required this.removed,
    required this.count,
    this.previousComponent,
  });

  bool added;
  bool removed;
  int count;
  _DraftChangeObject? previousComponent;
  dynamic value;
}

class _Path {
  _Path({required this.oldPos, this.lastComponent});

  int oldPos;
  _DraftChangeObject? lastComponent;
}

abstract class DiffBase<
  TokenT,
  ValueT extends Object?,
  InputValueT extends Object?
> {
  const DiffBase();

  List<Change<ValueT>>? diff(
    InputValueT oldValue,
    InputValueT newValue, {
    DiffComputationOptions<TokenT>? options,
  }) {
    options ??= DiffComputationOptions<TokenT>();
    final oldString = castInput(oldValue, options);
    final newString = castInput(newValue, options);

    final oldTokens = removeEmpty(tokenize(oldString, options));
    final newTokens = removeEmpty(tokenize(newString, options));

    return _diffWithOptions(oldTokens, newTokens, options);
  }

  List<Change<ValueT>>? _diffWithOptions(
    List<TokenT> oldTokens,
    List<TokenT> newTokens,
    DiffComputationOptions<TokenT> options,
  ) {
    List<Change<ValueT>> done(List<Change<ValueT>> value) {
      return postProcess(value, options);
    }

    final newLen = newTokens.length;
    final oldLen = oldTokens.length;

    var editLength = 1;
    var maxEditLength = newLen + oldLen;
    if (options.maxEditLength != null) {
      maxEditLength = maxEditLength < options.maxEditLength!
          ? maxEditLength
          : options.maxEditLength!;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final abortAfterTimestamp = options.timeout == null
        ? null
        : now + options.timeout!;

    final bestPath = <int, _Path>{0: _Path(oldPos: -1, lastComponent: null)};

    var newPos = _extractCommon(bestPath[0]!, newTokens, oldTokens, 0, options);
    if (bestPath[0]!.oldPos + 1 >= oldLen && newPos + 1 >= newLen) {
      return done(
        _buildValues(bestPath[0]!.lastComponent, newTokens, oldTokens),
      );
    }

    var minDiagonalToConsider = -1 << 30;
    var maxDiagonalToConsider = 1 << 30;

    List<Change<ValueT>>? execEditLength() {
      for (
        var diagonalPath = _max(minDiagonalToConsider, -editLength);
        diagonalPath <= _min(maxDiagonalToConsider, editLength);
        diagonalPath += 2
      ) {
        _Path? basePath;
        final removePath = bestPath[diagonalPath - 1];
        final addPath = bestPath[diagonalPath + 1];

        if (removePath != null) {
          bestPath.remove(diagonalPath - 1);
        }

        var canAdd = false;
        if (addPath != null) {
          final addPathNewPos = addPath.oldPos - diagonalPath;
          canAdd = 0 <= addPathNewPos && addPathNewPos < newLen;
        }

        final canRemove = removePath != null && removePath.oldPos + 1 < oldLen;

        if (!canAdd && !canRemove) {
          bestPath.remove(diagonalPath);
          continue;
        }

        if (!canRemove) {
          basePath = _addToPath(addPath as _Path, true, false, 0, options);
        } else if (canAdd && removePath.oldPos < (addPath as _Path).oldPos) {
          basePath = _addToPath(addPath, true, false, 0, options);
        } else {
          basePath = _addToPath(removePath, false, true, 1, options);
        }

        newPos = _extractCommon(
          basePath,
          newTokens,
          oldTokens,
          diagonalPath,
          options,
        );

        if (basePath.oldPos + 1 >= oldLen && newPos + 1 >= newLen) {
          return done(
            _buildValues(basePath.lastComponent, newTokens, oldTokens),
          );
        }

        bestPath[diagonalPath] = basePath;

        if (basePath.oldPos + 1 >= oldLen) {
          maxDiagonalToConsider = _min(maxDiagonalToConsider, diagonalPath - 1);
        }
        if (newPos + 1 >= newLen) {
          minDiagonalToConsider = _max(minDiagonalToConsider, diagonalPath + 1);
        }
      }

      editLength++;
      return null;
    }

    while (editLength <= maxEditLength) {
      if (abortAfterTimestamp != null &&
          DateTime.now().millisecondsSinceEpoch > abortAfterTimestamp) {
        return null;
      }

      final ret = execEditLength();
      if (ret != null) {
        return ret;
      }
    }

    return null;
  }

  _Path _addToPath(
    _Path path,
    bool added,
    bool removed,
    int oldPosInc,
    DiffComputationOptions<TokenT> options,
  ) {
    final last = path.lastComponent;

    if (last != null &&
        !options.oneChangePerToken &&
        last.added == added &&
        last.removed == removed) {
      return _Path(
        oldPos: path.oldPos + oldPosInc,
        lastComponent: _DraftChangeObject(
          count: last.count + 1,
          added: added,
          removed: removed,
          previousComponent: last.previousComponent,
        ),
      );
    }

    return _Path(
      oldPos: path.oldPos + oldPosInc,
      lastComponent: _DraftChangeObject(
        count: 1,
        added: added,
        removed: removed,
        previousComponent: last,
      ),
    );
  }

  int _extractCommon(
    _Path basePath,
    List<TokenT> newTokens,
    List<TokenT> oldTokens,
    int diagonalPath,
    DiffComputationOptions<TokenT> options,
  ) {
    final newLen = newTokens.length;
    final oldLen = oldTokens.length;

    var oldPos = basePath.oldPos;
    var newPos = oldPos - diagonalPath;
    var commonCount = 0;

    while (newPos + 1 < newLen &&
        oldPos + 1 < oldLen &&
        equals(oldTokens[oldPos + 1], newTokens[newPos + 1], options)) {
      newPos++;
      oldPos++;
      commonCount++;

      if (options.oneChangePerToken) {
        basePath.lastComponent = _DraftChangeObject(
          count: 1,
          previousComponent: basePath.lastComponent,
          added: false,
          removed: false,
        );
      }
    }

    if (commonCount > 0 && !options.oneChangePerToken) {
      basePath.lastComponent = _DraftChangeObject(
        count: commonCount,
        previousComponent: basePath.lastComponent,
        added: false,
        removed: false,
      );
    }

    basePath.oldPos = oldPos;
    return newPos;
  }

  bool equals(
    TokenT left,
    TokenT right,
    DiffComputationOptions<TokenT> options,
  ) {
    if (options.comparator != null) {
      return options.comparator!(left, right);
    }

    if (left == right) {
      return true;
    }

    if (options.ignoreCase && left is String && right is String) {
      return left.toLowerCase() == right.toLowerCase();
    }

    return false;
  }

  List<TokenT> removeEmpty(List<TokenT> array) {
    final ret = <TokenT>[];
    for (final item in array) {
      if (_truthy(item)) {
        ret.add(item);
      }
    }
    return ret;
  }

  bool _truthy(Object? value) {
    if (value == null) {
      return false;
    }
    if (value is bool) {
      return value;
    }
    if (value is String) {
      return value.isNotEmpty;
    }
    if (value is num) {
      return value != 0;
    }
    return true;
  }

  ValueT castInput(InputValueT value, DiffComputationOptions<TokenT> options) {
    return value as ValueT;
  }

  List<TokenT> tokenize(ValueT value, DiffComputationOptions<TokenT> options) {
    if (value is String) {
      return value.runes
          .map((rune) => String.fromCharCode(rune) as TokenT)
          .toList();
    }

    if (value is Iterable<TokenT>) {
      return value.toList();
    }

    throw StateError(
      'Unsupported value type for tokenization: ${value.runtimeType}',
    );
  }

  ValueT join(List<TokenT> chars) {
    return (chars.cast<String>().join()) as ValueT;
  }

  List<Change<ValueT>> postProcess(
    List<Change<ValueT>> changeObjects,
    DiffComputationOptions<TokenT> options,
  ) {
    return changeObjects;
  }

  bool get useLongestToken => false;

  List<Change<ValueT>> _buildValues(
    _DraftChangeObject? lastComponent,
    List<TokenT> newTokens,
    List<TokenT> oldTokens,
  ) {
    final components = <_DraftChangeObject>[];

    while (lastComponent != null) {
      components.add(lastComponent);
      lastComponent = lastComponent.previousComponent;
    }

    final reversed = components.reversed.toList();
    components
      ..clear()
      ..addAll(reversed);

    var newPos = 0;
    var oldPos = 0;

    for (final component in components) {
      if (!component.removed) {
        if (!component.added && useLongestToken) {
          var value = newTokens.sublist(newPos, newPos + component.count);
          final longest = <TokenT>[];
          for (var i = 0; i < value.length; i++) {
            final newValue = value[i];
            final oldValue = oldTokens[oldPos + i];
            if (newValue is String &&
                oldValue is String &&
                oldValue.length > newValue.length) {
              longest.add(oldValue as TokenT);
            } else {
              longest.add(newValue);
            }
          }
          component.value = join(longest);
        } else {
          component.value = join(
            newTokens.sublist(newPos, newPos + component.count),
          );
        }

        newPos += component.count;

        if (!component.added) {
          oldPos += component.count;
        }
      } else {
        component.value = join(
          oldTokens.sublist(oldPos, oldPos + component.count),
        );
        oldPos += component.count;
      }
    }

    return components
        .map(
          (component) => Change<ValueT>(
            value: component.value as ValueT,
            count: component.count,
            added: component.added,
            removed: component.removed,
          ),
        )
        .toList();
  }
}

int _max(int a, int b) => a > b ? a : b;
int _min(int a, int b) => a < b ? a : b;
