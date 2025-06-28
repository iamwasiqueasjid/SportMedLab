import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'vision_detector_views/pose_detector_view.dart';
import 'exercise_data.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

enum ExercisePhase { starting, down, up, transition }

class ExerciseSessionScreen extends StatefulWidget {
  final Exercise exercise;

  const ExerciseSessionScreen({super.key, required this.exercise});

  @override
  _ExerciseSessionScreenState createState() => _ExerciseSessionScreenState();
}

class _ExerciseSessionScreenState extends State<ExerciseSessionScreen> {
  List<CameraDescription> cameras = [];
  final FlutterTts _tts = FlutterTts();
  String _feedback = 'Start performing the exercise';
  int _reps = 0;
  ExercisePhase _currentPhase = ExercisePhase.starting;
  final List<Map<String, dynamic>> _sessionData = [];

  // TTS management
  bool _isSpeaking = false;
  String _lastSpokenText = '';
  DateTime _lastSpeechTime = DateTime.now();

  // Exercise state tracking
  // final bool _wasInCorrectStartPosition = false;
  // final DateTime _lastPhaseChange = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initCameras();
    _initTts();
  }

  void _initCameras() async {
    cameras = await availableCameras();
    setState(() {});
  }

  void _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.6);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  void _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = prefs.getStringList('exercise_sessions') ?? [];
    sessions.add(
      jsonEncode({
        'exercise': widget.exercise.name,
        'timestamp': DateTime.now().toIso8601String(),
        'reps': _reps,
        'data': _sessionData,
      }),
    );
    await prefs.setStringList('exercise_sessions', sessions);
  }

  void _provideFeedback(List<Pose> poses) {
    if (poses.isEmpty) {
      setState(() {
        _feedback = 'No pose detected. Please position yourself in view.';
      });
      _speakWithDelay('Please position yourself in view.');
      return;
    }

    final pose = poses.first;
    final angles = _calculateAngles(pose);

    if (widget.exercise.name == 'Push ups') {
      _handlePushUpLogic(pose, angles);
    } else if (widget.exercise.name == 'Arm Press') {
      _handleArmPressLogic(pose, angles);
    }
  }

  void _handlePushUpLogic(Pose pose, Map<PoseLandmarkType, double> angles) {
    final leftElbowAngle = angles[PoseLandmarkType.leftElbow] ?? 180.0;
    final rightElbowAngle = angles[PoseLandmarkType.rightElbow] ?? 180.0;
    final avgElbowAngle = (leftElbowAngle + rightElbowAngle) / 2;

    String feedbackMessage = '';
    bool isValidPosition = false;

    // Check body alignment
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder]!;
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip]!;
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle]!;

    final bodyAngle = _calculateBodyAngle(leftShoulder, leftHip, leftAnkle);
    final isBodyStraight =
        bodyAngle > 160; // Body should be relatively straight

    switch (_currentPhase) {
      case ExercisePhase.starting:
        if (avgElbowAngle > 140 && isBodyStraight) {
          isValidPosition = true;
          feedbackMessage = 'Ready position. Now go down!';
          _currentPhase = ExercisePhase.down;
          _speakWithDelay('Go down slowly');
        } else {
          feedbackMessage =
              'Get in starting position - arms extended, body straight';
          _speakWithDelay('Get in plank position with arms extended');
        }
        break;

      case ExercisePhase.down:
        if (avgElbowAngle < 90 && isBodyStraight) {
          isValidPosition = true;
          feedbackMessage = 'Good! Now push up!';
          _currentPhase = ExercisePhase.up;
          _speakWithDelay('Now push up');
        } else if (avgElbowAngle > 140) {
          feedbackMessage = 'Go lower - bend your elbows more';
          _speakWithDelay('Go down more');
        } else if (!isBodyStraight) {
          feedbackMessage = 'Keep your body straight';
          _speakWithDelay('Keep your body straight');
        } else {
          feedbackMessage = 'Keep going down';
        }
        break;

      case ExercisePhase.up:
        if (avgElbowAngle > 140 && isBodyStraight) {
          isValidPosition = true;
          _reps++;
          feedbackMessage = 'Rep $_reps completed! Go down again';
          _currentPhase = ExercisePhase.down;
          _speakWithDelay('Rep $_reps complete. Go down again');
        } else if (!isBodyStraight) {
          feedbackMessage = 'Keep your body straight while pushing up';
          _speakWithDelay('Keep your body straight');
        } else {
          feedbackMessage = 'Push all the way up';
        }
        break;

      case ExercisePhase.transition:
        // Handle transition logic if needed
        break;
    }

    setState(() {
      _feedback =
          'Reps: $_reps\nPhase: ${_currentPhase.name}\n$feedbackMessage';
    });

    _sessionData.add({
      'timestamp': DateTime.now().toIso8601String(),
      'angles': angles,
      'phase': _currentPhase.name,
      'correct': isValidPosition,
      'bodyAngle': bodyAngle,
    });
  }

  void _handleArmPressLogic(Pose pose, Map<PoseLandmarkType, double> angles) {
    final leftElbowAngle = angles[PoseLandmarkType.leftElbow] ?? 180.0;
    final rightElbowAngle = angles[PoseLandmarkType.rightElbow] ?? 180.0;
    final avgElbowAngle = (leftElbowAngle + rightElbowAngle) / 2;

    String feedbackMessage = '';
    bool isValidPosition = false;

    switch (_currentPhase) {
      case ExercisePhase.starting:
        if (avgElbowAngle > 160) {
          isValidPosition = true;
          feedbackMessage = 'Arms extended. Now bring arms in!';
          _currentPhase = ExercisePhase.down;
          _speakWithDelay('Bring your arms in');
        } else {
          feedbackMessage = 'Extend your arms out to the sides';
          _speakWithDelay('Extend your arms out to the sides');
        }
        break;

      case ExercisePhase.down:
        if (avgElbowAngle < 90) {
          isValidPosition = true;
          feedbackMessage = 'Good! Now extend arms out!';
          _currentPhase = ExercisePhase.up;
          _speakWithDelay('Now extend your arms out');
        } else if (avgElbowAngle > 160) {
          feedbackMessage = 'Bring your arms closer to your body';
          _speakWithDelay('Bring your arms in more');
        } else {
          feedbackMessage = 'Keep bringing arms in';
        }
        break;

      case ExercisePhase.up:
        if (avgElbowAngle > 160) {
          isValidPosition = true;
          _reps++;
          feedbackMessage = 'Rep $_reps completed! Bring arms in again';
          _currentPhase = ExercisePhase.down;
          _speakWithDelay('Rep $_reps complete. Bring arms in again');
        } else {
          feedbackMessage = 'Extend arms fully out';
        }
        break;

      case ExercisePhase.transition:
        // Handle transition logic if needed
        break;
    }

    setState(() {
      _feedback =
          'Reps: $_reps\nPhase: ${_currentPhase.name}\n$feedbackMessage';
    });

    _sessionData.add({
      'timestamp': DateTime.now().toIso8601String(),
      'angles': angles,
      'phase': _currentPhase.name,
      'correct': isValidPosition,
    });
  }

  Map<PoseLandmarkType, double> _calculateAngles(Pose pose) {
    final angles = <PoseLandmarkType, double>{};

    double calculateAngle(PoseLandmark p1, PoseLandmark p2, PoseLandmark p3) {
      final vector1 = Offset(p1.x - p2.x, p1.y - p2.y);
      final vector2 = Offset(p3.x - p2.x, p3.y - p2.y);
      final angle = acos(
        (vector1.dx * vector2.dx + vector1.dy * vector2.dy) /
            (sqrt(vector1.dx * vector1.dx + vector1.dy * vector1.dy) *
                sqrt(vector2.dx * vector2.dx + vector2.dy * vector2.dy)),
      );
      return angle * 180 / pi;
    }

    if (widget.exercise.name == 'Arm Press' ||
        widget.exercise.name == 'Push ups') {
      final leftElbowAngle = calculateAngle(
        pose.landmarks[PoseLandmarkType.leftShoulder]!,
        pose.landmarks[PoseLandmarkType.leftElbow]!,
        pose.landmarks[PoseLandmarkType.leftWrist]!,
      );
      final rightElbowAngle = calculateAngle(
        pose.landmarks[PoseLandmarkType.rightShoulder]!,
        pose.landmarks[PoseLandmarkType.rightElbow]!,
        pose.landmarks[PoseLandmarkType.rightWrist]!,
      );
      angles[PoseLandmarkType.leftElbow] = leftElbowAngle;
      angles[PoseLandmarkType.rightElbow] = rightElbowAngle;
    }

    return angles;
  }

  double _calculateBodyAngle(
    PoseLandmark shoulder,
    PoseLandmark hip,
    PoseLandmark ankle,
  ) {
    final vector1 = Offset(shoulder.x - hip.x, shoulder.y - hip.y);
    final vector2 = Offset(ankle.x - hip.x, ankle.y - hip.y);
    final angle = acos(
      (vector1.dx * vector2.dx + vector1.dy * vector2.dy) /
          (sqrt(vector1.dx * vector1.dx + vector1.dy * vector1.dy) *
              sqrt(vector2.dx * vector2.dx + vector2.dy * vector2.dy)),
    );
    return angle * 180 / pi;
  }

  void _speakWithDelay(String text) async {
    // Prevent speaking the same text repeatedly
    if (text == _lastSpokenText) return;

    // Ensure minimum delay between speeches
    final now = DateTime.now();
    if (now.difference(_lastSpeechTime).inSeconds < 3) return;

    // Don't interrupt ongoing speech unless it's been too long
    if (_isSpeaking && now.difference(_lastSpeechTime).inSeconds < 5) return;

    setState(() {
      _isSpeaking = true;
      _lastSpokenText = text;
      _lastSpeechTime = now;
    });

    await _tts.stop();
    await _tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Text(widget.exercise.name),
                      content: Text(widget.exercise.instructions),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          PoseDetectorView(
            onImage: _provideFeedback,
            initialCameraLensDirection: CameraLensDirection.back,
          ),
          Positioned(
            bottom: 70,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _feedback,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  _saveSession();
                  Navigator.pop(context);
                },
                child: const Text('End Session'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
