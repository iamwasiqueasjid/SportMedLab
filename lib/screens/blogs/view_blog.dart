import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

import 'package:test_project/models/blog.dart';
import 'package:test_project/services/auth/auth_service.dart';
import 'package:test_project/services/blog/blog_service.dart';

class PatientBlogScreen extends StatefulWidget {
  final Blog blog;

  const PatientBlogScreen({super.key, required this.blog});

  @override
  State<PatientBlogScreen> createState() => _PatientBlogScreenState();
}

class _PatientBlogScreenState extends State<PatientBlogScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;
  double _scrollProgress = 0.0;
  double _maxScrollExtent = 0.0;
  bool _hasScrollExtent = false;

  @override
  void initState() {
    super.initState();
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _progressAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _scrollController.addListener(_onScroll);

    // Get max scroll extent after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _maxScrollExtent = _scrollController.position.maxScrollExtent;
        _hasScrollExtent = true;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasScrollExtent || !_scrollController.hasClients) return;

    // Use cached maxScrollExtent for better performance
    if (_maxScrollExtent <= 0) {
      _maxScrollExtent = _scrollController.position.maxScrollExtent;
      if (_maxScrollExtent <= 0) return;
    }

    final currentScroll = _scrollController.offset;
    final progress = (currentScroll / _maxScrollExtent).clamp(0.0, 1.0);

    // Only update if there's a significant change (reduced threshold for smoother updates)
    if ((progress - _scrollProgress).abs() > 0.005) {
      _scrollProgress = progress;

      // Use direct animation update instead of setState for better performance
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: progress,
      ).animate(
        CurvedAnimation(
          parent: _progressAnimationController,
          curve: Curves.easeOut,
        ),
      );

      _progressAnimationController.forward(from: 0);
    }
  }

  QuillController _createQuillController() {
    try {
      // Parse the content from the Blog model
      if (widget.blog.content.isNotEmpty &&
          widget.blog.content['ops'] != null) {
        final deltaJson = widget.blog.content['ops'];
        final delta = Delta.fromJson(deltaJson);
        return QuillController(
          document: Document.fromDelta(delta),
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } catch (e) {
    }

    // Fallback to plain text if delta parsing fails
    final plainText = widget.blog.extractedText ?? 'Content not available';
    return QuillController(
      document: Document()..insert(0, plainText),
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _createQuillController();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Custom AppBar with Progress Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // AppBar content
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.black87,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            widget.blog.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              fontSize: 18,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Padding(
                        //   padding: const EdgeInsets.only(right: 16),
                        //   child: Row(
                        //     children: [
                        //       Icon(
                        //         Icons.visibility,
                        //         size: 16,
                        //         color: Colors.grey[600],
                        //       ),
                        //       const SizedBox(width: 4),
                        //       Text(
                        //         '${widget.blog.viewCount}',
                        //         style: TextStyle(color: Colors.grey[600]),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                      ],
                    ),
                  ),

                  // Progress Bar
                  SizedBox(
                    height: 3,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Container(
                          height: 3,
                          width: double.infinity,
                          decoration: BoxDecoration(color: Colors.grey[200]),
                        ),
                        AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return Container(
                              height: 3,
                              width:
                                  MediaQuery.of(context).size.width *
                                  _progressAnimation.value,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue[400]!,
                                    Colors.blue[600]!,
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics:
                  const ClampingScrollPhysics(), // Changed for better performance
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Blog metadata section
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date and status info
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              color: Colors.grey[600],
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Published on ${_formatDate(widget.blog.createdAt)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            if (widget.blog.likeCount > 0) ...[
                              Icon(
                                Icons.favorite,
                                color: Colors.red[400],
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.blog.likeCount}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Category
                        Row(
                          children: [
                            Icon(
                              Icons.category_outlined,
                              color: Colors.blue[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Category',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Text(
                            widget.blog.category,
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        if (widget.blog.tags.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          // Tags
                          Row(
                            children: [
                              Icon(
                                Icons.local_offer_outlined,
                                color: Colors.green[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Tags',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                widget.blog.tags
                                    .map(
                                      (tag) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green[50],
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: Colors.green[200]!,
                                          ),
                                        ),
                                        child: Text(
                                          tag,
                                          style: TextStyle(
                                            color: Colors.green[800],
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Blog content container
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: QuillEditor.basic(controller: controller),
                  ),

                  const SizedBox(height: 20),

FutureBuilder(
                    future: AuthService().fetchUserData(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data?.role == 'Doctor') {
                        return Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  _showDeleteDialog(widget.blog);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.delete, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete Blog',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          
                            const SizedBox(height: 20),
                          ],
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),

                  

                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),

                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.article_outlined, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'View More Blogs',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Extra spacing at bottom to ensure progress bar reaches 100%
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  
}

  void _showDeleteDialog(Blog blog) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_rounded,
              color: Colors.red[600],
              size: 32,
            ),
          ),
          title: const Text(
            'Delete Blog',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure you want to delete this blog?',
                style: TextStyle(color: Colors.grey[700], fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This action cannot be undone.',
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await BlogService.deleteBlog(blog.id, context);
                      Navigator.of(context).pop(); // Close dialog
                      if (mounted) {
                        Navigator.of(context).pop(); // Close the blog view page
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
