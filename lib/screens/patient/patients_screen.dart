import 'package:flutter/material.dart';
import '../../services/blog_service.dart';
import 'blog_view_patient.dart'; // Changed import to new patient-specific screen
import 'package:flutter_quill/flutter_quill.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  late Future<List<Map<String, dynamic>>> _blogsFuture;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchBlogs();
  }

  Future<void> _fetchBlogs() async {
    setState(() => _isLoading = true);
    try {
      final blogs = await BlogService.getPublishedBlogs();
      setState(() {
        _blogsFuture = Future.value(blogs);
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching blogs: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posted Blogs for Patients'),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : FutureBuilder<List<Map<String, dynamic>>>(
        future: _blogsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No blogs available.'));
          }

          final blogs = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: blogs.length,
            itemBuilder: (context, index) {
              final blog = blogs[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(
                    blog['title'] ?? 'Untitled',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    blog['extractedText']?.substring(0, 50) ?? 'No preview available',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientBlogPreviewScreen(
                          title: blog['title'] ?? 'Untitled',
                          controller: QuillController(
                            document: Document.fromJson(blog['content']),
                            selection: const TextSelection.collapsed(offset: 0),
                          ),
                          tags: blog['tags'] as List<String>? ?? [],
                          category: blog['category'] ?? 'Uncategorized',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}