import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:test_project/models/blog.dart';

class BlogUploadWidgets {
  static Widget buildFileUploadSection(
    BuildContext context,
    String? uploadedFileName,
    bool isProcessingFile,
    VoidCallback onUpload,
  ) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
color: Colors.blue.shade50,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.upload_file,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Smart Document Upload',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Upload PDF or Word document to auto-populate content with preserved formatting, generate smart metadata, and extract structure',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              if (uploadedFileName != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(
                      color: Colors.green.shade200,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Successfully Processed',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              uploadedFileName,
                              style: TextStyle(
                                color: Colors.green.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isProcessingFile ? null : onUpload,
                  icon:
                      isProcessingFile
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: SpinKitDoubleBounce(
                              color: Color(0xFF0A2D7B),
                              size: 40.0,
                            ),
                          )
                          : const Icon(Icons.cloud_upload, size: 20),
                  label: Text(
                    isProcessingFile ? 'Processing...' : 'Upload Document',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildTitleInput(
    BuildContext context,
    TextEditingController titleController,
  ) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.purple.shade50,
        ),
      child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.title,
                      color: Colors.purple.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Blog Title',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: 'Enter your blog title...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.purple.shade700,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
                  counterStyle: TextStyle(color: Colors.grey.shade600),
                ),
                maxLength: 100,
                style: TextStyle(color: Colors.grey.shade900, fontSize: 16),
              ),
            ],
          ),
      ),
      ),
    );
  }

  static Widget buildCategorySelector(
    BuildContext context,
    String? selectedCategory,
    Function(String?) onChanged,
  ) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.orange.shade50,
        ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.category,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Category',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.orange.shade700,
                      width: 2,
                    ),
                ),
                filled: true,
                  fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
              ),
              hint: Text(
                'Select a category',
                style: TextStyle(color: Colors.grey.shade500),
              ),
              items:
                    BlogConstants.categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(
                        category,
                          style: TextStyle(color: Colors.grey.shade900),
                      ),
                    );
                  }).toList(),
              onChanged: onChanged,
              dropdownColor: Colors.white,
            ),
          ],
        ),
      ),
      ),
    );
  }

  static Widget buildTagsInput(
    BuildContext context,
    TextEditingController tagsController,
    List<String> suggestedTags,
    bool isGeneratingTags,
  ) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.teal.shade50,
        ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.tag, color: Colors.teal.shade700, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Tags',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                if (isGeneratingTags) ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 20,
                    height: 20,
                      child: SpinKitDoubleBounce(
                        color: Color(0xFF0A2D7B),
                        size: 40.0,
                      ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tagsController,
              decoration: InputDecoration(
                hintText: 'Enter tags separated by commas...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.teal.shade500,
                      width: 2,
                    ),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.all(16),
              ),
                // maxLines: 2,
                style: TextStyle(color: Colors.grey.shade900, fontSize: 16),
            ),
            if (suggestedTags.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'AI Suggested Tags:',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    suggestedTags.map((tag) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ActionChip(
                          label: Text(
                            tag,
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          backgroundColor: Colors.blue.shade50,
                          side: BorderSide(color: Colors.blue.shade200),
                          onPressed: () {
                            String currentTags = tagsController.text;
                            if (currentTags.isEmpty) {
                              tagsController.text = tag;
                            } else if (!currentTags.contains(tag)) {
                              tagsController.text = '$currentTags, $tag';
                            }
                          },
                        ),
                      );
                    }).toList(),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }

  static Widget buildQuillEditor(
    BuildContext context,
    QuillController controller,
  ) {
    return Card(
      elevation: 2,
      color: Colors.white, // Light background for card
      child: Column(
        children: [
          // Enhanced Quill Toolbar with light theme
          Container(
                  padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade500, // Light grey toolbar background
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                // Customize toolbar icons to be darker
                iconTheme: const IconThemeData(
                  color: Colors.white, // Dark icons
                  size: 20,
                ),
                // Customize button colors
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white,
                  ),
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(foregroundColor: Colors.white,
                        ),
                ),
                // Customize icon button colors
                iconButtonTheme: IconButtonThemeData(
                  style: IconButton.styleFrom(foregroundColor: Colors.white),
                ),
              ),
              child: QuillSimpleToolbar(controller: controller),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade300), // Lighter divider
          // Quill Editor with light theme
          SizedBox(
            height: 400,
            child: Container(
              color: Colors.white, // White background for editor
              padding: const EdgeInsets.all(16),
              child: Theme(
                data: Theme.of(context).copyWith(
                  // Ensure text in editor is dark
                  textTheme: Theme.of(context).textTheme.apply(
                    bodyColor: Colors.black87,
                    displayColor: Colors.black87,
                  ),
                ),
                child: QuillEditor.basic(controller: controller),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildActionButtons(
    BuildContext context,
    bool isPublishing,
    VoidCallback onClear,
    VoidCallback onPublish,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: OutlinedButton.icon(
                onPressed: onClear,
                icon: Icon(Icons.clear, color: Colors.red.shade600),
                label: Text(
                  'Clear',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.red.shade300, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade300.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: isPublishing ? null : onPublish,
                icon:
                    isPublishing
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: SpinKitDoubleBounce(
                            color: Color(0xFF0A2D7B),
                            size: 40.0,
                          ),
                        )
                        : const Icon(Icons.publish, size: 20),
                label: Text(
                  isPublishing ? 'Publishing...' : 'Publish Blog',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
