typedef DistanceIterator = int? Function();

DistanceIterator distanceIterator(int start, int minLine, int maxLine) {
  var wantForward = true;
  var backwardExhausted = false;
  var forwardExhausted = false;
  var localOffset = 1;

  int? iterator() {
    if (wantForward && !forwardExhausted) {
      if (backwardExhausted) {
        localOffset++;
      } else {
        wantForward = false;
      }

      if (start + localOffset <= maxLine) {
        return start + localOffset;
      }

      forwardExhausted = true;
    }

    if (!backwardExhausted) {
      if (!forwardExhausted) {
        wantForward = true;
      }

      if (minLine <= start - localOffset) {
        return start - localOffset++;
      }

      backwardExhausted = true;
      return iterator();
    }

    return null;
  }

  return iterator;
}
