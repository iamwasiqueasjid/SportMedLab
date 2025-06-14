import 'package:flutter_quill/flutter_quill.dart';

Document convertMarkdownToDelta(String markdown) {
  // For now, treat it as plain text.
  // For production, use a Markdown parser or markdown-to-delta package
  return Document()..insert(0, markdown);
}
