class SessionModel {
  final String id;
  final String title;
  final String patientName;
  final DateTime scheduledTime;
  final String status; // 'upcoming', 'ongoing', 'completed'
  final int? duration; // Duration in seconds

  SessionModel({
    required this.id,
    required this.title,
    required this.patientName,
    required this.scheduledTime,
    required this.status,
    this.duration,
  });

  factory SessionModel.fromFirestore(Map<String, dynamic> data, String id) {
    return SessionModel(
      id: id,
      title: data['title'] ?? '',
      patientName: data['patientName'] ?? '',
      scheduledTime: (data['scheduledTime'] as dynamic).toDate(),
      status: data['status'] ?? 'upcoming',
      duration: data['duration'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'patientName': patientName,
      'scheduledTime': scheduledTime,
      'status': status,
      'duration': duration,
    };
  }
}
