class ResultModel {
  final String id;
  final String childId;
  final String activityType;
  final int score;
  final int totalPoints;
  final int timeSpent; // en secondes
  final DateTime date;
  final Map<String, dynamic> details;
  
  ResultModel({
    required this.id,
    required this.childId,
    required this.activityType,
    required this.score,
    required this.totalPoints,
    required this.timeSpent,
    required this.date,
    required this.details,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'childId': childId,
    'activityType': activityType,
    'score': score,
    'totalPoints': totalPoints,
    'timeSpent': timeSpent,
    'date': date.toIso8601String(),
    'details': details,
  };
  
  factory ResultModel.fromJson(Map<String, dynamic> json) => ResultModel(
    id: json['id'],
    childId: json['childId'],
    activityType: json['activityType'],
    score: json['score'],
    totalPoints: json['totalPoints'],
    timeSpent: json['timeSpent'],
    date: DateTime.parse(json['date']),
    details: json['details'] ?? {},
  );
  
  double get percentage => (score / totalPoints * 100).clamp(0.0, 100.0);
  String get formattedDate => '${date.day}/${date.month}/${date.year}';
  String get formattedTime => '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}