import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../constants/constants.dart';

class MetadataService {
  static Future<void> generateMetadataWithAI(
    String text,
    TextEditingController titleController,
    TextEditingController tagsController,
    List<String> suggestedTags,
    Function(String?) onCategorySelected,
    Function(String) showSuccessSnackBar,
    Function(String) showErrorSnackBar,
  ) async {
    final geminiApiKey = dotenv.env['GEMINI_API_KEY'];
    if (geminiApiKey == null || geminiApiKey.isEmpty) {
      showErrorSnackBar('Gemini API key not found. Using fallback tag generation.');
      generateBasicTags(text, titleController, tagsController, suggestedTags);
      return;
    }

    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$geminiApiKey');
    String analyzableText = text.length > 2500 ? text.substring(0, 2500) : text;

    final prompt = """
    Analyze this medical/health blog content and provide metadata in JSON format ONLY. 
    Focus on medical accuracy and relevance.

    {
      "title": "Professional medical blog title (50-80 characters)",
      "tags": ["tag1", "tag2", "tag3", "tag4", "tag5", "tag6"],
      "category": "Most appropriate category",
      "summary": "Brief 2-sentence summary for preview"
    }

    Requirements:
    - Title: Engaging, professional, SEO-friendly
    - Tags: Relevant medical terms, conditions, treatments
    - Category: Must be exactly one from: ${AppConstants.categories.join(', ')}
    - Summary: Concise overview of main points
    - Response: Valid JSON only, no additional text

    Medical Content:
    $analyzableText
    """;

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {'temperature': 0.6, 'maxOutputTokens': 1200},
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final generatedText = data['candidates'][0]['content']['parts'][0]['text'];
          final jsonStart = generatedText.indexOf('{');
          final jsonEnd = generatedText.lastIndexOf('}') + 1;

          if (jsonStart != -1 && jsonEnd > jsonStart) {
            final jsonString = generatedText.substring(jsonStart, jsonEnd);
            final jsonData = json.decode(jsonString);

            if (jsonData['title'] != null && jsonData['title'].toString().isNotEmpty) {
              titleController.text = jsonData['title'].toString();
            }

            if (jsonData['tags'] != null && jsonData['tags'] is List) {
              suggestedTags.clear();
              suggestedTags.addAll(List<String>.from(jsonData['tags']));
              tagsController.text = suggestedTags.join(', ');
            }

            if (jsonData['category'] != null && AppConstants.categories.contains(jsonData['category'].toString())) {
              onCategorySelected(jsonData['category'].toString());
            }

            showSuccessSnackBar('AI analysis complete! Enhanced metadata generated.');
            return;
          }
        }
      }
      generateBasicTags(text, titleController, tagsController, suggestedTags);
    } catch (e) {
      print('Error calling enhanced Gemini API: $e');
      generateBasicTags(text, titleController, tagsController, suggestedTags);
    }
  }

  static void generateBasicTags(
    String text,
    TextEditingController titleController,
    TextEditingController tagsController,
    List<String> suggestedTags,
  ) {
    Map<String, List<String>> medicalTermsByCategory = {
      'symptoms': ['pain', 'fever', 'headache', 'nausea', 'fatigue', 'dizziness'],
      'treatments': ['therapy', 'medication', 'surgery', 'treatment', 'intervention'],
      'conditions': ['diabetes', 'hypertension', 'infection', 'disease', 'disorder'],
      'general': ['health', 'medical', 'patient', 'care', 'diagnosis', 'prevention']
    };

    Set<String> foundTags = {};
    String lowerText = text.toLowerCase();

    medicalTermsByCategory.forEach((category, terms) {
      for (String term in terms) {
        if (lowerText.contains(term) && foundTags.length < 8) {
          foundTags.add(term);
        }
      }
    });

    if (titleController.text.isEmpty) {
      List<String> sentences = text.split('.').where((s) => s.trim().isNotEmpty).toList();
      if (sentences.isNotEmpty) {
        String firstSentence = sentences[0].trim();
        if (firstSentence.length > 80) {
          firstSentence = firstSentence.substring(0, 77) + '...';
        }
        titleController.text = firstSentence;
      }
    }

    suggestedTags.clear();
    suggestedTags.addAll(foundTags);
    if (foundTags.isNotEmpty) {
      tagsController.text = foundTags.join(', ');
    }
  }
}