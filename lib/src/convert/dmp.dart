import '../models/change.dart';

typedef DmpTuple<T> = (int, T);

List<DmpTuple<T>> convertChangesToDmp<T>(List<Change<T>> changes) {
  final ret = <DmpTuple<T>>[];
  for (final change in changes) {
    final operation = change.added
        ? 1
        : change.removed
        ? -1
        : 0;
    ret.add((operation, change.value));
  }
  return ret;
}

List<DmpTuple<T>> convertChangesToDMP<T>(List<Change<T>> changes) {
  return convertChangesToDmp(changes);
}
