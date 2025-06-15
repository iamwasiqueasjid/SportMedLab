import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercise History')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadSessions(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final sessions = snapshot.data!;
          if (sessions.isEmpty) {
            return const Center(child: Text('No sessions recorded yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(
                    '${session['exercise']} - ${session['timestamp']}',
                  ),
                  subtitle: Text(
                    'Reps: ${session['reps']}, Data Points: ${session['data'].length}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = prefs.getStringList('exercise_sessions') ?? [];
    return sessions.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
  }
}
