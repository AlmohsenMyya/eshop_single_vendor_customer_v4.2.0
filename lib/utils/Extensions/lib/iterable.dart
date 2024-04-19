extension MapIndexed on Iterable {
  Iterable<U> mapIndexed<T, U>(U Function(T e, int i) f) {
    int i = 0;
    return map<U>((it) {
      final t = i;
      i++;
      return f(it, t);
    });
  }
}
