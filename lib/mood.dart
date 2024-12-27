class Mood {
  final int? rating;
  final String? date;

  Mood({this.rating, this.date});

  Map<String, dynamic> toMap() {
    return {'rating': rating, 'date': date};
  }

  factory Mood.fromMap(Map<String, dynamic> map) {
    return Mood(
      rating: map['rating'],
      date: map['date'],
    );
  }
}