import 'package:flutter/material.dart';
import 'exercise_session_screen.dart';
import 'history_screen.dart';
import 'exercise_data.dart';

class ExerciseSelectionWidget extends StatelessWidget {
  const ExerciseSelectionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'Select an Exercise',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        for (var exercise in exercises)
          Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(exercise.name),
              subtitle: Text(exercise.description),
              trailing: const Icon(Icons.arrow_forward_ios),
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
