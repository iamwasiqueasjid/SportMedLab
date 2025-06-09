// lib/services/gemini_service.dart
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final GenerativeModel _model;
  final String _apiKey;

  GeminiService()
    : _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '',
      _model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
      );

  Future<String> generateSummary(String content) async {
    try {
      final prompt = """
      Generate a concise summary of the following educational content:
      
      $content
      
      Make the summary clear, informative, and no more than 3-4 sentences.
      """;

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Summary generation failed.';
    } catch (e) {
      return 'Failed to generate summary.';
    }
  }

  Future<List<Map<String, String>>> generateFlashcards(String content) async {
    try {
      final prompt = """
      Create 3-5 flashcards based on the following educational content. 
      Each flashcard should have a question and answer. Format as JSON.
      
      $content
      """;

      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '[]';

      // Parse the flashcard JSON - in a real app, you'd want to add better error handling here
      // This is a simplified approach and assumes the model returns valid JSON
      final List<dynamic> parsedJson = json.decode(responseText);

      return parsedJson
          .map<Map<String, String>>(
            (card) => {
              'question': card['question'] as String,
              'answer': card['answer'] as String,
            },
          )
          .toList();
    } catch (e) {
      return [];
    }
  }
}
