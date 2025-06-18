import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../services/blog/blog_service.dart';
import '../../models/blog.dart';
import 'view_blog.dart';

class BlogList extends StatefulWidget {
  const BlogList({super.key});

  @override
  State<BlogList> createState() => _BlogListState();
}

class _BlogListState extends State<BlogList> {
  late Future<List<Blog>> _blogsFuture;
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8F9FA), Color(0xFFFFFFFF)],
        ),
      ),
      child:
          _isLoading
              ? const Center(
                child: SpinKitDoubleBounce(
                  color: Color(0xFF0A2D7B),
                  size: 40.0,
                ),
              )
              : _errorMessage != null
              ? _buildErrorWidget()
              : FutureBuilder<List<Blog>>(
                future: _blogsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: SpinKitDoubleBounce(
                        color: Color(0xFF0A2D7B),
                        size: 40.0,
                      ),
                    );
                  }
                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return _buildEmptyWidget();
                  }

                  final blogs = snapshot.data!;
                  return RefreshIndicator(
                    onRefresh: _fetchBlogs,
                    color: const Color(0xFF2196F3),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: blogs.length,
                      itemBuilder:
                          (context, index) => _buildBlogCard(blogs[index]),
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildBlogCard(Blog blog) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToBlog(blog),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        blog.category,
                        style: const TextStyle(
                          color: Color(0xFF2196F3),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.article_outlined,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  blog.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  (blog.content['ops'][0]['insert']?.length ?? 0) > 100
                      ? '${blog.content['ops'][0]['insert']?.substring(0, 100)}...'
                      : blog.content['ops'][0]['insert'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'By ${blog.authorId ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(blog.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    // const SizedBox(width: 8),
                    const Spacer(),
                    
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchBlogs,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No Blogs Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new content',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _navigateToBlog(Blog blog) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: Duration(milliseconds: 400),
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                PatientBlogScreen(blog: blog),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0); // Slide from bottom
          const end = Offset.zero;
          final curve = Curves.easeInOut;

          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

}
