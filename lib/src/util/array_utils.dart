bool arrayEqual(List<Object?> a, List<Object?> b) {
  if (a.length != b.length) {
    return false;
  }
  return arrayStartsWith(a, b);
}

bool arrayStartsWith(List<Object?> array, List<Object?> start) {
  if (start.length > array.length) {
    return false;
  }

  for (var i = 0; i < start.length; i++) {
    if (array[i] != start[i]) {
      return false;
    }
  }
  return true;
}
