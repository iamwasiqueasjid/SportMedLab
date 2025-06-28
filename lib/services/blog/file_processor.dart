import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FileProcessor {
  static Future<Map<String, dynamic>?> uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'doc'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String extractedText = '';
      Map<String, dynamic>? structuredContent;

      if (result.files.single.extension?.toLowerCase() == 'pdf') {
        extractedText = await _extractTextFromPDF(file);
        structuredContent = await _analyzeContentStructure(extractedText);
      } else if (result.files.single.extension?.toLowerCase() == 'docx' ||
          result.files.single.extension?.toLowerCase() == 'doc') {
        extractedText = await _extractTextFromWord(file);
        structuredContent = await _analyzeContentStructure(extractedText);
      }

      if (extractedText.isNotEmpty) {
        return {
          'fileName': result.files.single.name,
          'extractedText': extractedText,
          'structure': structuredContent,
        };
      }
    }
    return null;
  }

  static Future<String> _extractTextFromPDF(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      String text = '';

      for (int i = 0; i < document.pages.count; i++) {
        // final PdfPage page = document.pages[i];
        String pageText = PdfTextExtractor(
          document,
        ).extractText(startPageIndex: i, endPageIndex: i);
        text += pageText;
        if (i < document.pages.count - 1) {
          text += '\n\n--- Page Break ---\n\n';
        }
      }

      document.dispose();
      return text.trim();
    } catch (e) {
      throw Exception('Failed to extract text from PDF: ${e.toString()}');
    }
  }

  static Future<String> _extractTextFromWord(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final text = docxToText(bytes);
      return text;
    } catch (e) {
      throw Exception(
        'Failed to extract text from Word document: ${e.toString()}',
      );
    }
  }

  static Future<Map<String, dynamic>?> _analyzeContentStructure(
    String text,
  ) async {
    final geminiApiKey = dotenv.env['GEMINI_API_KEY'];
    if (geminiApiKey == null || geminiApiKey.isEmpty) return null;

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$geminiApiKey',
    );
    String analyzableText = text.length > 3000 ? text.substring(0, 3000) : text;

    final prompt = """
    Analyze this document content and identify its structure. Return ONLY a JSON object with this format:

    {
      "headings": [
        {"text": "heading text", "level": 1, "position": 0}
      ],
      "lists": [
        {"items": ["item1", "item2"], "type": "bullet", "position": 100}
      ],
      "emphasis": [
        {"text": "bold text", "type": "bold", "position": 50},
        {"text": "italic text", "type": "italic", "position": 75}
      ],
      "structure_hints": {
        "has_introduction": true,
        "has_conclusion": true,
        "main_sections": 3
      }
    }

    Content to analyze:
    $analyzableText
    """;

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {'temperature': 0.3, 'maxOutputTokens': 1500},
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final generatedText =
              data['candidates'][0]['content']['parts'][0]['text'];
          final jsonStart = generatedText.indexOf('{');
          final jsonEnd = generatedText.lastIndexOf('}') + 1;

          if (jsonStart != -1 && jsonEnd > jsonStart) {
            final jsonString = generatedText.substring(jsonStart, jsonEnd);
            return json.decode(jsonString);
          }
        }
      }
    } catch (e) {}
    return null;
  }
}
