class Mood {
  final int? rating;

  Mood({this.rating});

  Map<String, dynamic> toMap() {
    return {'rating': rating};
  }

  factory Mood.fromMap(Map<String, dynamic> map) {
    return Mood(
      rating: map['rating'],
    );
  }
}