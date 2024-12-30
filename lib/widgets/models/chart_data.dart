class ChartData {
  final List<Map<String, dynamic>> _moodData;
  final List<Map<String, dynamic>> _partnerMoodData;
  List<Map<String, dynamic>> filteredData = [];
  List<Map<String, dynamic>> filteredPartnerData = [];
  String selectedFilter = 'all';

  ChartData(this._moodData, this._partnerMoodData) {
    filteredData = _moodData;
    filteredPartnerData = _partnerMoodData;
  }

  void filterData(String filter) {
    selectedFilter = filter;
    DateTime now = DateTime.now();
    DateTime? startDate;

    switch (filter) {
      case 'week':
        startDate = now.subtract(Duration(days: 7));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case 'year':
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      case 'all':
      default:
        filteredData = _moodData;
        filteredPartnerData = _partnerMoodData;
        return;
    }

    filteredData = _moodData.where((data) {
      DateTime date = DateTime.parse(data['date'].toString());
      return date.isAfter(startDate!);
    }).toList();

    filteredPartnerData = _partnerMoodData.where((data) {
      DateTime date = DateTime.parse(data['date'].toString());
      return date.isAfter(startDate!);
    }).toList();
  }

  List<String> get allDates {
    final dates = {
      ...filteredData.map((e) => e['date'].toString()),
      ...filteredPartnerData.map((e) => e['date'].toString())
    }.toList()..sort();
    return dates;
  }
}