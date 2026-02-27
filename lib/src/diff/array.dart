import '../core/diff_base.dart';
import '../core/diff_options.dart';
import '../models/change.dart';

class ArrayDiff<T> extends DiffBase<T, List<T>, List<T>> {
  const ArrayDiff();

  @override
  List<T> tokenize(List<T> value, DiffComputationOptions<T> options) {
    return List<T>.from(value);
  }

  @override
  List<T> join(List<T> chars) {
    return List<T>.from(chars);
  }

  @override
  List<T> removeEmpty(List<T> array) {
    return array;
  }
}

List<Change<List<T>>>? diffArrays<T>(
  List<T> oldArr,
  List<T> newArr, {
  bool oneChangePerToken = false,
  int? timeout,
  int? maxEditLength,
  bool Function(T left, T right)? comparator,
}) {
  const arrayDiff = ArrayDiff<Object?>();
  final changes = arrayDiff.diff(
    oldArr.cast<Object?>(),
    newArr.cast<Object?>(),
    options: DiffComputationOptions<Object?>(
      oneChangePerToken: oneChangePerToken,
      timeout: timeout,
      maxEditLength: maxEditLength,
      comparator: comparator == null
          ? null
          : (left, right) => comparator(left as T, right as T),
    ),
  );

  if (changes == null) {
    return null;
  }

  return changes
      .map(
        (change) => Change<List<T>>(
          value: change.value.cast<T>(),
          count: change.count,
          added: change.added,
          removed: change.removed,
        ),
      )
      .toList();
}
