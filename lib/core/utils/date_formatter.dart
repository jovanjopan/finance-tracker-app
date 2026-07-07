class DateFormatter {
  DateFormatter._();

  static const List<String> _months = [
    'januari', 'februari', 'maret', 'april', 'mei', 'juni',
    'juli', 'agustus', 'september', 'oktober', 'november', 'desember',
  ];

  static String format(DateTime date) {
    return '${date.day} ${_months[date.month - 1]} ${date.year}';
  }
}