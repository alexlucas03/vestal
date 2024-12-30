class StatisticsCalculator {
  static Map<String, dynamic> calculate(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return {
        'average': 0.0,
        'mostCommon': 0,
        'longestStreak': 0,
      };
    }

    List<double> ratings = data
        .map((data) => (data['rating'] as num).toDouble())
        .toList();

    double average = ratings.reduce((a, b) => a + b) / ratings.length;

    Map<double, int> frequencyMap = {};
    for (var rating in ratings) {
      frequencyMap[rating] = (frequencyMap[rating] ?? 0) + 1;
    }
    double mostCommon = frequencyMap.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    List<DateTime> dates = data
        .map((data) => DateTime.parse(data['date'].toString()))
        .toList()
      ..sort();
    
    int currentStreak = 1;
    int longestStreak = 1;
    
    for (int i = 1; i < dates.length; i++) {
      if (dates[i].difference(dates[i - 1]).inDays == 1) {
        currentStreak++;
        longestStreak = currentStreak > longestStreak ? currentStreak : longestStreak;
      } else {
        currentStreak = 1;
      }
    }

    return {
      'average': average,
      'mostCommon': mostCommon,
      'longestStreak': longestStreak,
    };
  }
}