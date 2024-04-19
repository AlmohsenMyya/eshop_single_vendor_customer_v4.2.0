extension D on String {
  DateTime parseAsDate() {
    return DateTime.parse(this);
  }
}

extension DT on DateTime {
  bool isSameDate(DateTime date2) {
    return this.year == date2.year &&
        this.month == date2.month &&
        this.day == date2.day;
  }
}
