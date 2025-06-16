import 'package:flutter/material.dart';
// import 'package:test_project/workout_pose/history_screen.dart';
import 'exercise_session_screen.dart';
import 'history_screen.dart';
import 'exercise_data.dart';

class ExerciseSelectionWidget extends StatelessWidget {
  const ExerciseSelectionWidget({super.key});

  void _showHistoryPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return HistoryPopup();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Select an Exercise',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor, // Changed to theme.primaryColor
                ),
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.history, color: Colors.black),
              onPressed: () => _showHistoryPopup(context),
            ),
          ],
        ),
        const SizedBox(height: 20),
        for (var exercise in exercises)
          Card(
            color: Colors.white,
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: BorderSide(color: theme.primaryColor, width: 1.0),
            ),
            child: ListTile(
              leading:
                  exercise.name.toLowerCase() == 'armpress'
                      ? const Icon(Icons.fitness_center, color: Colors.blue)
                      : exercise.name.toLowerCase() == 'pushups'
                      ? const Icon(
                        Icons.accessibility_new,
                        color: Colors.orange,
                      )
                      : null,
              title: Text(
                exercise.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              subtitle: Text(
                exercise.description,
                style: TextStyle(color: theme.primaryColor),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: theme.primaryColor,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ExerciseSessionScreen(exercise: exercise),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
