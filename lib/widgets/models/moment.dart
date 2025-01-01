class Moment {
  final int? id;
  final String title;
  final String date;
  final String status;
  final String description;
  final String feelings;
  final String ideal;
  final String intensity;
  final String type;

  Moment({
    this.id,
    required this.title,
    required this.date,
    required this.status,
    required this.description,
    required this.feelings,
    required this.ideal,
    required this.intensity,
    required this.type,
  });

  factory Moment.fromMap(Map<String, dynamic> map) {
    return Moment(
      id: map['id'],
      title: map['title'] ?? '',
      date: map['date'] ?? '',
      status: map['status'] ?? '',
      description: map['description'] ?? '',
      feelings: map['feelings'] ?? '',
      ideal: map['ideal'] ?? '',
      intensity: map['intensity']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
    );
  }
}