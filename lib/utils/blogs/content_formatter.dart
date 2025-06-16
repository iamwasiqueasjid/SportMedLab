import 'package:flutter_quill/flutter_quill.dart';
import 'package:dart_quill_delta/dart_quill_delta.dart';

class ContentFormatter {
  static Future<void> processExtractedContent(
    QuillController controller,
    String text,
    Map<String, dynamic>? structure,
    Function(bool) onProcessingStateChanged,
  ) async {
    onProcessingStateChanged(true);
    try {
      await populateQuillEditorWithFormatting(text, controller, structure);
    } catch (e) {
      rethrow;
    } finally {
      onProcessingStateChanged(false);
    }
  }

  static Future<void> populateQuillEditorWithFormatting(
    String text,
    QuillController controller,
    Map<String, dynamic>? structure,
  ) async {
    try {
      controller.document = Document(); // Clear existing content
      if (text.isEmpty) return;

      final cleanedText = cleanExtractedText(text);
      final paragraphs =
          cleanedText.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
      final document = Document();

      for (int i = 0; i < paragraphs.length; i++) {
        final paragraph = paragraphs[i].trim();
        if (paragraph.isEmpty) continue;

        final paragraphDelta = createFormattedParagraph(
          paragraph,
          structure,
          i,
        );
        if (paragraphDelta.isNotEmpty) {
          document.insert(document.length, paragraphDelta);
          if (i < paragraphs.length - 1) {
            document.insert(document.length, '\n');
          }
        }
      }

      controller.document = document;
    } catch (e) {
      await populateQuillEditorBasic(text, controller);
    }
  }

  static Delta createFormattedParagraph(
    String paragraph,
    Map<String, dynamic>? structure,
    int position,
  ) {
    final delta = Delta();

    if (isHeading(paragraph)) {
      final level = getHeadingLevel(paragraph);
      final cleanHeading = cleanHeadingText(paragraph);
      delta.insert(cleanHeading, {'header': level.clamp(1, 3)});
      delta.insert('\n');
      return delta;
    }

    final listItems = extractListItems(paragraph);
    if (listItems.isNotEmpty) {
      for (final item in listItems) {
        final cleanItem = item.trim();
        if (cleanItem.isNotEmpty) {
          delta.insert(cleanItem, {'list': 'bullet'});
          delta.insert('\n');
        }
      }
      return delta;
    }

    delta.insert(paragraph); // Default case
    delta.insert('\n');
    return parseInlineFormatting(paragraph); // Apply inline formatting
  }

  static Delta parseInlineFormatting(String text) {
    final delta = Delta();
    final patterns = [
      _FormatPattern(RegExp(r'\*\*(.+?)\*\*'), {'bold': true}),
      _FormatPattern(RegExp(r'\*(.+?)\*'), {'italic': true}),
      _FormatPattern(RegExp(r'_(.+?)_'), {'underline': true}),
      _FormatPattern(RegExp(r'ALL CAPS: ([A-Z\s]+)'), {'bold': true}),
    ];

    int currentIndex = 0;
    String remainingText = text;

    while (currentIndex < text.length) {
      _FormatPattern? matchedPattern;
      RegExpMatch? earliestMatch;
      int earliestMatchStart = text.length;

      for (final pattern in patterns) {
        final match = pattern.regex.firstMatch(remainingText);
        if (match != null && match.start < earliestMatchStart) {
          matchedPattern = pattern;
          earliestMatch = match;
          earliestMatchStart = match.start;
        }
      }

      if (earliestMatch == null) {
        if (remainingText.isNotEmpty) {
          delta.insert(remainingText);
        }
        break;
      }

      if (earliestMatch.start > 0) {
        delta.insert(remainingText.substring(0, earliestMatch.start));
      }

      final matchedText = earliestMatch.group(1)!;
      delta.insert(matchedText, matchedPattern!.attributes);

      currentIndex += earliestMatch.end;
      remainingText = text.substring(currentIndex);
    }

    return delta;
  }

  static List<String> extractListItems(String paragraph) {
    return paragraph
        .split('\n')
        .map((line) => line.trim())
        .where((line) => isListItem(line))
        .map(cleanListItem)
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static String cleanExtractedText(String text) {
    return text
        .replaceAll(RegExp(r'--- Page Break ---'), '\n\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool isHeading(String line) {
    final trimmed = line.trim();
    if (trimmed.length > 100 || trimmed.split(' ').length > 15) return false;
    return RegExp(r'^\d+\.?\s+[A-Z]').hasMatch(trimmed) ||
        RegExp(r'^[IVX]+\.\s+[A-Z]').hasMatch(trimmed) ||
        (RegExp(r'^[A-Z][A-Za-z\s]*$').hasMatch(trimmed) &&
            trimmed.length > 3 &&
            !RegExp(r'[.,;:]$').hasMatch(trimmed));
  }

  static int getHeadingLevel(String line) {
    final trimmed = line.trim();
    if (RegExp(r'^\d+\.').hasMatch(trimmed)) {
      final number = RegExp(r'^\d+').firstMatch(trimmed)?.group(0);
      final num = int.tryParse(number ?? '1') ?? 1;
      return (num <= 3)
          ? 1
          : (num <= 6)
          ? 2
          : 3;
    }
    return trimmed.length < 30 && trimmed == trimmed.toUpperCase() ? 1 : 2;
  }

  static String cleanHeadingText(String line) {
    return line
        .trim()
        .replaceFirst(RegExp(r'^\d+\.?\s*'), '')
        .replaceFirst(RegExp(r'^[IVX]+\.\s*'), '')
        .trim();
  }

  static bool isListItem(String line) {
    final trimmed = line.trim();
    return RegExp(r'^[•\-\*o]\s+').hasMatch(trimmed) ||
        RegExp(r'^\d+\.\s+').hasMatch(trimmed) ||
        RegExp(r'^[a-zA-Z]\)\s+').hasMatch(trimmed);
  }

  static String cleanListItem(String line) {
    return line
        .trim()
        .replaceFirst(RegExp(r'^[•\-\*o]\s*'), '')
        .replaceFirst(RegExp(r'^\d+\.\s*'), '')
        .replaceFirst(RegExp(r'^[a-zA-Z]\)\s*'), '')
        .trim();
  }

  static Future<void> populateQuillEditorBasic(
    String text,
    QuillController controller,
  ) async {
    try {
      controller.document = Document();
      if (text.isEmpty) return;

      final paragraphs =
          text.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
      final document = Document();

      for (final paragraph in paragraphs) {
        final trimmedParagraph = paragraph.trim();
        if (trimmedParagraph.isEmpty) continue;

        final delta = Delta();
        if (isHeading(trimmedParagraph)) {
          final level = getHeadingLevel(trimmedParagraph);
          final cleanHeading = cleanHeadingText(trimmedParagraph);
          delta.insert(cleanHeading, {'header': level <= 2 ? 1 : 2});
        } else {
          delta.insert(trimmedParagraph);
        }
        document.insert(document.length, delta);
        document.insert(document.length, '\n');
      }

      controller.document = document;
    } catch (e) {
      controller.document = Document()..insert(0, text);
    }
  }
}

class _FormatPattern {
  final RegExp regex;
  final Map<String, dynamic> attributes;
  _FormatPattern(this.regex, this.attributes);
}
