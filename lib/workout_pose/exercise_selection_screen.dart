import 'package:flutter/material.dart';
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
        // Header with title and history icon
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Select an Exercise',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
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
        // Search bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'What pose do you wish to align?',
              hintStyle: TextStyle(color: Theme.of(context).primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2.0,
                ),
              ),
              filled: true,
              fillColor: Colors.grey[200],
            ),
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
        ),
        const SizedBox(height: 20),
        // Strength Alignment Section
        Text(
          'Available Exercises',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _buildExerciseCard(context, exercises[0], theme), // Arm Press
            _buildExerciseCard(context, exercises[1], theme), // Push ups
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    Exercise exercise,
    ThemeData theme,
  ) {
    // Determine the image path based on exercise name
    String imagePath = '';
    // print('Exercise name: ${exercise.name}'); // Debug log
    if (exercise.name.toLowerCase() == 'arm press') {
      imagePath = 'assets/icons/muscle.png';
    } else if (exercise.name.toLowerCase() == 'push ups') {
      imagePath = 'assets/icons/push-up.png';
    }

    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: theme.primaryColor, width: 1.0),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExerciseSessionScreen(exercise: exercise),
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              width: 65,
              height: 65,
              errorBuilder: (context, error, stackTrace) {
                // print(
                //   'Error loading image: $imagePath for ${exercise.name}',
                // ); // Debug log
                return Icon(
                  Icons.fitness_center,
                  size: 50,
                  color: theme.primaryColor,
                ); // Fallback icon
              },
            ),
            const SizedBox(height: 10),
            Text(
              exercise.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
