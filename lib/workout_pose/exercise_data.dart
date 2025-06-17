import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class AngleCheck {
  final PoseLandmarkType landmarkType;
  final double minAngle;
  final double maxAngle;
  final String feedback;

  AngleCheck({
    required this.landmarkType,
    required this.minAngle,
    required this.maxAngle,
    required this.feedback,
  });
}

class Exercise {
  final String name;
  final String description;
  final String instructions;
  final List<AngleCheck> angleChecks;

  Exercise({
    required this.name,
    required this.description,
    required this.instructions,
    required this.angleChecks,
  });
}

final List<Exercise> exercises = [
  Exercise(
    name: 'Arm Press',
    description: 'Strengthen your arms and shoulders',
    instructions:
        'Stand straight with feet shoulder-width apart. Hold weights in both hands, palms facing forward. Bend elbows to 90 degrees, then extend arms fully upward. Return to starting position slowly.',
    angleChecks: [
      // Elbow angles
      AngleCheck(
        landmarkType: PoseLandmarkType.leftElbow,
        minAngle: 80,
        maxAngle: 100,
        feedback: 'Keep your elbows at a 90-degree angle when bending.',
      ),
      AngleCheck(
        landmarkType: PoseLandmarkType.rightElbow,
        minAngle: 80,
        maxAngle: 100,
        feedback: 'Keep your elbows at a 90-degree angle when bending.',
      ),
      // Shoulder angles
      AngleCheck(
        landmarkType: PoseLandmarkType.leftShoulder,
        minAngle: 70,
        maxAngle: 110,
        feedback: 'Keep shoulders stable and avoid hunching.',
      ),
      AngleCheck(
        landmarkType: PoseLandmarkType.rightShoulder,
        minAngle: 70,
        maxAngle: 110,
        feedback: 'Keep shoulders stable and avoid hunching.',
      ),
      // Wrist alignment
      AngleCheck(
        landmarkType: PoseLandmarkType.leftWrist,
        minAngle: 160,
        maxAngle: 200,
        feedback: 'Keep wrists straight and aligned with forearms.',
      ),
      AngleCheck(
        landmarkType: PoseLandmarkType.rightWrist,
        minAngle: 160,
        maxAngle: 200,
        feedback: 'Keep wrists straight and aligned with forearms.',
      ),
      // Hip stability
      AngleCheck(
        landmarkType: PoseLandmarkType.leftHip,
        minAngle: 170,
        maxAngle: 190,
        feedback: 'Keep hips stable and maintain upright posture.',
      ),
      AngleCheck(
        landmarkType: PoseLandmarkType.rightHip,
        minAngle: 170,
        maxAngle: 190,
        feedback: 'Keep hips stable and maintain upright posture.',
      ),
    ],
  ),
  Exercise(
    name: 'Push ups',
    description: 'Build upper body and core strength',
    instructions:
        'Start in a plank position with hands under shoulders. Lower your body until your chest nearly touches the floor, keeping elbows at a 45-degree angle. Push back up to the starting position.',
    angleChecks: [
      // Elbow angles
      AngleCheck(
        landmarkType: PoseLandmarkType.leftElbow,
        minAngle: 45,
        maxAngle: 90,
        feedback: 'Keep your elbows between 45 and 90 degrees during Push ups.',
      ),
      AngleCheck(
        landmarkType: PoseLandmarkType.rightElbow,
        minAngle: 45,
        maxAngle: 90,
        feedback: 'Keep your elbows between 45 and 90 degrees during Push ups.',
      ),
      // Shoulder angles
      AngleCheck(
        landmarkType: PoseLandmarkType.leftShoulder,
        minAngle: 80,
        maxAngle: 120,
        feedback: 'Keep shoulders engaged and avoid sagging.',
      ),
      AngleCheck(
        landmarkType: PoseLandmarkType.rightShoulder,
        minAngle: 80,
        maxAngle: 120,
        feedback: 'Keep shoulders engaged and avoid sagging.',
      ),
      // Hip alignment (plank position)
      AngleCheck(
        landmarkType: PoseLandmarkType.leftHip,
        minAngle: 160,
        maxAngle: 200,
        feedback: 'Keep hips in line with body - avoid sagging or piking.',
      ),
      AngleCheck(
        landmarkType: PoseLandmarkType.rightHip,
        minAngle: 160,
        maxAngle: 200,
        feedback: 'Keep hips in line with body - avoid sagging or piking.',
      ),
      // Knee stability
      AngleCheck(
        landmarkType: PoseLandmarkType.leftKnee,
        minAngle: 170,
        maxAngle: 190,
        feedback: 'Keep knees straight and legs engaged.',
      ),
      AngleCheck(
        landmarkType: PoseLandmarkType.rightKnee,
        minAngle: 170,
        maxAngle: 190,
        feedback: 'Keep knees straight and legs engaged.',
      ),
      // Ankle position
      AngleCheck(
        landmarkType: PoseLandmarkType.leftAnkle,
        minAngle: 80,
        maxAngle: 100,
        feedback: 'Keep feet flexed and maintain balance on toes.',
      ),
      AngleCheck(
        landmarkType: PoseLandmarkType.rightAnkle,
        minAngle: 80,
        maxAngle: 100,
        feedback: 'Keep feet flexed and maintain balance on toes.',
      ),
    ],
  ),
];
