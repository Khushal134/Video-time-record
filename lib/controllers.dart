import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import '../session_model.dart';
import '../screens/video_call_screen.dart';

// Appointments Controller
class AppointmentsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxList<SessionModel> sessions = <SessionModel>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSessions();
  }

  void fetchSessions() {
    isLoading.value = true;

    _firestore
        .collection('sessions')
        .orderBy('scheduledTime')
        .snapshots()
        .listen((snapshot) {
      try {
        debugPrint(
            '🔄 Firestore update received: ${snapshot.docs.length} total docs');

        // Show ALL sessions (removed status filter)
        sessions.value = snapshot.docs
            .where((doc) => doc.data()['scheduledTime'] != null)
            .map((doc) => SessionModel.fromFirestore(doc.data(), doc.id))
            .toList();

        debugPrint('✅ Showing ${sessions.length} sessions');

        isLoading.value = false;
      } catch (e) {
        debugPrint('❌ Error parsing sessions: $e');
        isLoading.value = false;
      }
    }, onError: (error) {
      debugPrint('❌ Error fetching sessions: $error');
      isLoading.value = false;
    });
  }

  Future<void> joinSession(SessionModel session) async {
    // Only allow joining upcoming sessions
    if (session.status != 'upcoming') {
      Get.snackbar(
        'Cannot Join',
        'This session is ${session.status}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    debugPrint('🔍 Requesting permissions for session: ${session.id}');

    final cameraStatus = await Permission.camera.request();
    final microphoneStatus = await Permission.microphone.request();

    debugPrint('📷 Camera permission: $cameraStatus');
    debugPrint('🎤 Microphone permission: $microphoneStatus');

    if (cameraStatus.isGranted && microphoneStatus.isGranted) {
      debugPrint('✅ Permissions granted, starting session...');

      try {
        await _firestore.collection('sessions').doc(session.id).update({
          'status': 'ongoing',
          'startTime': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ Session ${session.id} updated to ongoing');

        Get.to(() => VideoCallScreen(session: session));
      } catch (e) {
        debugPrint('❌ Error starting session: $e');
        Get.snackbar(
          'Error',
          'Failed to start session: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } else {
      debugPrint('❌ Permissions denied');

      Get.snackbar(
        'Permissions Required',
        'Camera and Microphone permissions are required',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }
}

// Video Call Controller
class VideoCallController extends GetxController {
  final SessionModel session;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxInt elapsedSeconds = 0.obs;
  final RxBool isMuted = false.obs;
  final RxBool isVideoOff = false.obs;
  Timer? _timer;

  VideoCallController(this.session);

  @override
  void onInit() {
    super.onInit();
    startTimer();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      elapsedSeconds.value++;
    });
  }

  String get formattedTime {
    final hours = (elapsedSeconds.value ~/ 3600).toString().padLeft(2, '0');
    final minutes =
        ((elapsedSeconds.value % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (elapsedSeconds.value % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  void toggleMute() {
    isMuted.value = !isMuted.value;
    debugPrint('🎤 Mute toggled: ${isMuted.value}');
  }

  void toggleVideo() {
    isVideoOff.value = !isVideoOff.value;
    debugPrint('📹 Video toggled: ${isVideoOff.value}');
  }

  Future<void> endCall() async {
    debugPrint('📞 Ending call...');
    debugPrint('⏱️  Session duration: ${elapsedSeconds.value} seconds');

    _timer?.cancel();

    try {
      // Update session in Firestore
      await _firestore.collection('sessions').doc(session.id).update({
        'status': 'completed',
        'duration': elapsedSeconds.value,
        'endTime': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Session updated to completed in Firestore');
      debugPrint('   - Session ID: ${session.id}');
      debugPrint('   - Duration: ${elapsedSeconds.value} seconds');
    } catch (e) {
      debugPrint('❌ Error updating session: $e');
    }

    Get.back();

    Get.snackbar(
      'Call Ended',
      'Session duration: $formattedTime',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
