extension MapExt on Map {
  void removeEmptyKeys() {
    removeWhere((key, value) => value.isEmpty || value == "");
  }
}
