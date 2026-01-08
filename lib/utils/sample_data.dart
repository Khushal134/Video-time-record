import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Future<void> seedSessions() async {
  final firestore = FirebaseFirestore.instance;

  final sessions = [
    {
      'title': 'Follow-up Consultation',
      'patientName': 'Jane Smith',
      'scheduledTime': Timestamp.fromDate(DateTime(2025, 1, 16, 14, 30)),
      'status': 'upcoming',
    },
    {
      'title': 'Therapy Session',
      'patientName': 'Bob Johnson',
      'scheduledTime': Timestamp.fromDate(DateTime(2025, 1, 17, 9, 0)),
      'status': 'upcoming',
    },
    {
      'title': 'Dental Checkup',
      'patientName': 'Alice Brown',
      'scheduledTime': Timestamp.fromDate(DateTime(2025, 1, 18, 11, 0)),
      'status': 'upcoming',
    },
    {
      'title': 'Eye Examination',
      'patientName': 'Charlie Wilson',
      'scheduledTime': Timestamp.fromDate(DateTime(2025, 1, 19, 15, 30)),
      'status': 'upcoming',
    },
  ];

  try {
    for (var session in sessions) {
      await firestore.collection('sessions').add(session);
    }
    debugPrint('✅ Successfully added ${sessions.length} sessions');
  } catch (e) {
    debugPrint('❌ Error adding sessions: $e');
  }
}
