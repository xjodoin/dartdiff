class Change<T> {
  Change({
    required this.value,
    required this.count,
    this.added = false,
    this.removed = false,
  });

  T value;
  bool added;
  bool removed;
  int count;

  @override
  String toString() {
    return 'Change(value: $value, added: $added, removed: $removed, count: $count)';
  }
}
