import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:test_project/utils/blogs/constants.dart';

class UIUtils {
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static Widget buildFileUploadSection(
    BuildContext context,
    String? uploadedFileName,
    bool isProcessingFile,
    VoidCallback onUpload,
  ) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.upload_file, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Smart Document Upload',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Upload PDF or Word document to auto-populate content with preserved formatting, generate smart metadata, and extract structure',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            if (uploadedFileName != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Successfully Processed',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            uploadedFileName,
                            style: TextStyle(
                              color: Colors.green.shade600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isProcessingFile ? null : onUpload,
                icon:
                    isProcessingFile
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.cloud_upload),
                label: Text(
                  isProcessingFile ? 'Processing...' : 'Upload Document',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Blog Title',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: 'Enter your blog title...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              maxLength: 100,
            ),
          ],
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              hint: const Text('Select a category'),
              items:
                  AppConstants.categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
              onChanged: onChanged,
            ),
          ],
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Tags',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isGeneratingTags) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: tagsController,
              decoration: const InputDecoration(
                hintText: 'Enter tags separated by commas...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
              maxLines: 2,
            ),
            if (suggestedTags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'AI Suggested Tags:',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children:
                    suggestedTags.map((tag) {
                      return ActionChip(
                        label: Text(tag),
                        onPressed: () {
                          String currentTags = tagsController.text;
                          if (currentTags.isEmpty) {
                            tagsController.text = tag;
                          } else if (!currentTags.contains(tag)) {
                            tagsController.text = '$currentTags, $tag';
                          }
                        },
                      );
                    }).toList(),
              ),
            ],
          ],
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Blog Content',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Custom Toolbar with individual buttons
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        // Bold Button
                        IconButton(
                          icon: const Icon(Icons.format_bold),
                          onPressed:
                              () => controller.formatSelection(Attribute.bold),
                          tooltip: 'Bold',
                          iconSize: 20,
                        ),
                        // Italic Button
                        IconButton(
                          icon: const Icon(Icons.format_italic),
                          onPressed:
                              () =>
                                  controller.formatSelection(Attribute.italic),
                          tooltip: 'Italic',
                          iconSize: 20,
                        ),
                        // Underline Button
                        IconButton(
                          icon: const Icon(Icons.format_underlined),
                          onPressed:
                              () => controller.formatSelection(
                                Attribute.underline,
                              ),
                          tooltip: 'Underline',
                          iconSize: 20,
                        ),
                        // Bullet List Button
                        IconButton(
                          icon: const Icon(Icons.format_list_bulleted),
                          onPressed:
                              () => controller.formatSelection(Attribute.ul),
                          tooltip: 'Bullet List',
                          iconSize: 20,
                        ),
                        // Numbered List Button
                        IconButton(
                          icon: const Icon(Icons.format_list_numbered),
                          onPressed:
                              () => controller.formatSelection(Attribute.ol),
                          tooltip: 'Numbered List',
                          iconSize: 20,
                        ),
                        // Header Button
                        PopupMenuButton<int>(
                          icon: const Icon(Icons.title),
                          tooltip: 'Header',
                          itemBuilder:
                              (context) => [
                                const PopupMenuItem(
                                  value: 1,
                                  child: Text('Header 1'),
                                ),
                                const PopupMenuItem(
                                  value: 2,
                                  child: Text('Header 2'),
                                ),
                                const PopupMenuItem(
                                  value: 3,
                                  child: Text('Header 3'),
                                ),
                                const PopupMenuItem(
                                  value: 0,
                                  child: Text('Normal'),
                                ),
                              ],
                          onSelected: (value) {
                            switch (value) {
                              case 1:
                                controller.formatSelection(Attribute.h1);
                                break;
                              case 2:
                                controller.formatSelection(Attribute.h2);
                                break;
                              case 3:
                                controller.formatSelection(Attribute.h3);
                                break;
                              case 0:
                                // Remove header formatting
                                if (controller
                                    .getSelectionStyle()
                                    .attributes
                                    .containsKey(Attribute.header.key)) {
                                  controller.formatSelection(Attribute.header);
                                }
                                break;
                            }
                          },
                        ),
                        // Clear Format Button
                        IconButton(
                          icon: const Icon(Icons.format_clear),
                          onPressed: () {
                            // Clear formatting by toggling off active formats
                            final selection = controller.selection;
                            if (selection.isCollapsed) return;

                            // Toggle off bold if active
                            if (controller
                                .getSelectionStyle()
                                .attributes
                                .containsKey(Attribute.bold.key)) {
                              controller.formatSelection(Attribute.bold);
                            }
                            // Toggle off italic if active
                            if (controller
                                .getSelectionStyle()
                                .attributes
                                .containsKey(Attribute.italic.key)) {
                              controller.formatSelection(Attribute.italic);
                            }
                            // Toggle off underline if active
                            if (controller
                                .getSelectionStyle()
                                .attributes
                                .containsKey(Attribute.underline.key)) {
                              controller.formatSelection(Attribute.underline);
                            }
                          },
                          tooltip: 'Clear Format',
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Quill Editor with minimal parameters
                  SizedBox(
                    height: 400,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: QuillEditor(
                        controller: controller,
                        focusNode: FocusNode(),
                        scrollController: ScrollController(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildActionButtons(
    BuildContext context,
    bool isPublishing,
    VoidCallback onClear,
    VoidCallback onPublish,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.clear),
            label: const Text('Clear'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isPublishing ? null : onPublish,
            icon:
                isPublishing
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.publish),
            label: Text(isPublishing ? 'Publishing...' : 'Publish Blog'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
