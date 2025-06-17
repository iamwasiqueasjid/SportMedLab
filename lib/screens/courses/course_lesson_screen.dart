import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:test_project/models/course.dart';
import 'package:test_project/models/lesson.dart';
import 'package:test_project/services/auth/auth_service.dart'; // Added import
import 'package:test_project/services/database_service.dart';
import 'package:test_project/utils/message_type.dart';
import 'package:test_project/utils/responsive_extension.dart';
import 'package:test_project/utils/responsive_helper.dart';
import 'package:test_project/widgets/app_message_notifier.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:intl/intl.dart';

class CourseLessonsScreen extends StatefulWidget {
  final String courseId;

  const CourseLessonsScreen({super.key, required this.courseId});

  @override
  State<CourseLessonsScreen> createState() => _CourseLessonsScreenState();
}

class _CourseLessonsScreenState extends State<CourseLessonsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService(); // Added AuthService
  Course? _courseData;
  bool _isLoading = true;
  String? _userRole; // Added to store user role

  @override
  void initState() {
    super.initState();
    _loadCourseData();
    _loadUserRole(); // Added to load user role
  }

  Future<void> _loadCourseData() async {
    try {
      final data = await _databaseService.getCourseById(widget.courseId);
      setState(() {
        _courseData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppNotifier.show(
        context,
        'Error loading course: $e',
        type: MessageType.error,
      );
    }
  }

  Future<void> _loadUserRole() async {
    final userData = await _authService.fetchUserData();
    setState(() {
      _userRole = userData?.role;
    });
  }

  Future<void> _showAddLessonDialog() async {
    final titleController = TextEditingController();
    final youtubeUrlController = TextEditingController();
    bool isSaving = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.mediumSpacing),
              ),
              title: Text(
                'Add New Lesson',
                style: context.responsiveHeadlineMedium.copyWith(
                  color: theme.primaryColor,
                ),
              ),
              content: SingleChildScrollView(
                child: Container(
                  width: ResponsiveHelper.getValue(
                    context,
                    mobile: double.infinity,
                    tablet: 400.0,
                    desktop: 600.0,
                  ),
                  padding: EdgeInsets.all(context.mediumSpacing),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        style: context.responsiveBodyLarge.copyWith(
                          color: theme.primaryColor,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Lesson Title',
                          hintText: 'Enter lesson title',
                          hintStyle: context.responsiveBodyMedium.copyWith(
                            color: theme.primaryColor,
                          ),
                          labelStyle: context.responsiveBodyMedium.copyWith(
                            color: theme.primaryColor,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              context.smallSpacing,
                            ),
                            borderSide: BorderSide(color: theme.primaryColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              context.smallSpacing,
                            ),
                            borderSide: BorderSide(
                              color: theme.primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: context.mediumSpacing),
                      TextField(
                        controller: youtubeUrlController,
                        style: context.responsiveBodyLarge.copyWith(
                          color: theme.primaryColor,
                        ),
                        decoration: InputDecoration(
                          labelText: 'YouTube URL',
                          hintText: 'Enter YouTube video URL',
                          hintStyle: context.responsiveBodyMedium.copyWith(
                            color: theme.primaryColor,
                          ),
                          labelStyle: context.responsiveBodyMedium.copyWith(
                            color: theme.primaryColor,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              context.smallSpacing,
                            ),
                            borderSide: BorderSide(color: theme.primaryColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              context.smallSpacing,
                            ),
                            borderSide: BorderSide(
                              color: theme.primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      if (isSaving)
                        Padding(
                          padding: EdgeInsets.only(top: context.mediumSpacing),
                          child: SpinKitDoubleBounce(
                            color: theme.primaryColor,
                            size: ResponsiveHelper.getValue(
                              context,
                              mobile: 40.0,
                              tablet: 50.0,
                              desktop: 60.0,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: Text(
                    'Cancel',
                    style: context.responsiveBodyLarge.copyWith(
                      color: theme.primaryColor,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  onPressed:
                      isSaving
                          ? null
                          : () async {
                            if (titleController.text.isEmpty) {
                              AppNotifier.show(
                                context,
                                'Lesson title is required',
                                type: MessageType.warning,
                              );
                              return;
                            }
                            if (youtubeUrlController.text.isEmpty) {
                              AppNotifier.show(
                                context,
                                'YouTube URL is required',
                                type: MessageType.warning,
                              );
                              return;
                            }

                            setState(() {
                              isSaving = true;
                            });

                            final success = await _databaseService.createLesson(
                              courseId: widget.courseId,
                              title: titleController.text,
                              contentType: 'youtube',
                              content: '',
                              youtubeUrl: youtubeUrlController.text,
                              context: context,
                            );

                            if (success) {
                              Navigator.of(context).pop();
                            } else {
                              setState(() {
                                isSaving = false;
                              });
                            }
                          },
                  child: Text(
                    'Save',
                    style: context.responsiveBodyLarge.copyWith(
                      color: theme.primaryColor,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteLessonConfirmation(String lessonId) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.mediumSpacing),
          ),
          title: Text(
            'Delete Lesson',
            style: context.responsiveHeadlineMedium.copyWith(
              color: theme.primaryColor,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this lesson? This action cannot be undone.',
            style: context.responsiveBodyLarge.copyWith(
              color: Colors.grey[700],
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: context.responsiveBodyLarge.copyWith(
                  color: theme.primaryColor,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Delete',
                style: context.responsiveBodyLarge.copyWith(color: Colors.red),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _databaseService.deleteLesson(lessonId, context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        title: Text(
          _isLoading
              ? 'Course Lessons'
              : _courseData?.title ?? 'Course Lessons',
          style: context.responsiveTitleLarge.copyWith(color: Colors.white),
        ),
      ),
      body:
          _isLoading
              ? Center(
                child: SpinKitDoubleBounce(
                  color: theme.primaryColor,
                  size: ResponsiveHelper.getValue(
                    context,
                    mobile: 40.0,
                    tablet: 50.0,
                    desktop: 60.0,
                  ),
                ),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: ResponsiveHelper.getValue(
                      context,
                      mobile: 160.0,
                      tablet: 200.0,
                      desktop: 250.0,
                    ),
                    width: double.infinity,
                    child:
                        _courseData?.coverImageUrl != null &&
                                _courseData!.coverImageUrl!.isNotEmpty
                            ? Image.network(
                              _courseData!.coverImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => Container(
                                    color: Colors.grey[100],
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: ResponsiveHelper.getValue(
                                        context,
                                        mobile: 50.0,
                                        tablet: 60.0,
                                        desktop: 70.0,
                                      ),
                                      color: theme.primaryColor,
                                    ),
                                  ),
                            )
                            : Container(
                              color: Colors.grey[100],
                              child: Icon(
                                Icons.fitness_center,
                                size: ResponsiveHelper.getValue(
                                  context,
                                  mobile: 50.0,
                                  tablet: 60.0,
                                  desktop: 70.0,
                                ),
                                color: theme.primaryColor,
                              ),
                            ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(
                      ResponsiveHelper.getValue(
                        context,
                        mobile: 16.0,
                        tablet: 20.0,
                        desktop: 24.0,
                      ),
                    ),
                    child: Text(
                      'Lessons',
                      style: context.responsiveHeadlineMedium.copyWith(
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<List<Lesson>>(
                      stream: _databaseService.fetchLessonsForCourse(
                        widget.courseId,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: SpinKitDoubleBounce(
                              color: theme.primaryColor,
                              size: ResponsiveHelper.getValue(
                                context,
                                mobile: 40.0,
                                tablet: 50.0,
                                desktop: 60.0,
                              ),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: context.responsiveBodyLarge,
                            ),
                          );
                        }

                        final lessons = snapshot.data ?? [];

                        if (lessons.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.book_outlined,
                                  size: ResponsiveHelper.getValue(
                                    context,
                                    mobile: 80.0,
                                    tablet: 100.0,
                                    desktop: 120.0,
                                  ),
                                  color: Colors.grey[600],
                                ),
                                SizedBox(height: context.mediumSpacing),
                                Text(
                                  'No Lessons Yet',
                                  style: context.responsiveHeadlineMedium,
                                ),
                                SizedBox(height: context.smallSpacing),
                                Text(
                                  _userRole == 'Doctor'
                                      ? 'Add your first lesson'
                                      : 'No lessons available',
                                  style: context.responsiveBodyLarge.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: EdgeInsets.all(
                            ResponsiveHelper.getValue(
                              context,
                              mobile: 16.0,
                              tablet: 20.0,
                              desktop: 24.0,
                            ),
                          ),
                          itemCount: lessons.length,
                          itemBuilder: (context, index) {
                            final lesson = lessons[index];
                            return _buildLessonCard(context, theme, lesson);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
      floatingActionButton:
          _userRole == 'Doctor'
              ? FloatingActionButton(
                onPressed: _showAddLessonDialog,
                backgroundColor: theme.primaryColor,
                tooltip: 'Add New Lesson',
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: ResponsiveHelper.getValue(
                    context,
                    mobile: 24.0,
                    tablet: 26.0,
                    desktop: 28.0,
                  ),
                ),
              )
              : null, // Hide FAB for non-Doctor users
    );
  }

  Widget _buildLessonCard(
    BuildContext context,
    ThemeData theme,
    Lesson lesson,
  ) {
    String formattedDate = 'Date not available';
    if (lesson.createdAt != null) {
      formattedDate = DateFormat('MMM d, yyyy').format(lesson.createdAt!);
    }

    return Card(
      margin: EdgeInsets.symmetric(
        vertical: ResponsiveHelper.getValue(
          context,
          mobile: 8.0,
          tablet: 10.0,
          desktop: 12.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.mediumSpacing),
      ),
      elevation: ResponsiveHelper.getValue(
        context,
        mobile: 4.0,
        tablet: 6.0,
        desktop: 8.0,
      ),
      color: Colors.white,
      child: InkWell(
        onTap: () {
          if (lesson.youtubeUrl != null && lesson.youtubeUrl!.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => YoutubePlayerScreen(
                      youtubeUrl: lesson.youtubeUrl!,
                      lessonTitle: lesson.title,
                    ),
              ),
            );
          } else {
            AppNotifier.show(
              context,
              'No YouTube video available for this lesson',
              type: MessageType.warning,
            );
          }
        },
        child: Padding(
          padding: EdgeInsets.all(
            ResponsiveHelper.getValue(
              context,
              mobile: 8.0,
              tablet: 12.0,
              desktop: 16.0,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.primaryColor.withOpacity(0.1),
                child: Icon(
                  Icons.play_circle_outline,
                  color: theme.primaryColor,
                  size: ResponsiveHelper.getValue(
                    context,
                    mobile: 24.0,
                    tablet: 26.0,
                    desktop: 28.0,
                  ),
                ),
              ),
              SizedBox(width: context.mediumSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title.isNotEmpty
                          ? lesson.title
                          : 'Untitled Lesson',
                      style: context.responsiveTitleLarge,
                    ),
                    SizedBox(height: context.smallSpacing),
                    Text(
                      formattedDate,
                      style: context.responsiveBodyMedium.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (_userRole == 'Doctor') // Show delete button only for Doctors
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: Colors.red,
                    size: ResponsiveHelper.getValue(
                      context,
                      mobile: 20.0,
                      tablet: 22.0,
                      desktop: 24.0,
                    ),
                  ),
                  onPressed: () => _showDeleteLessonConfirmation(lesson.id),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class YoutubePlayerScreen extends StatefulWidget {
  final String youtubeUrl;
  final String lessonTitle;

  const YoutubePlayerScreen({
    super.key,
    required this.youtubeUrl,
    required this.lessonTitle,
  });

  @override
  State<YoutubePlayerScreen> createState() => _YoutubePlayerScreenState();
}

class _YoutubePlayerScreenState extends State<YoutubePlayerScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.youtubeUrl);
    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? '',
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        title: Text(
          widget.lessonTitle,
          style: context.responsiveTitleLarge.copyWith(color: Colors.white),
        ),
      ),
      body: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: theme.primaryColor,
        progressColors: ProgressBarColors(
          playedColor: theme.primaryColor,
          handleColor: theme.primaryColor.withOpacity(0.8),
        ),
      ),
    );
  }
}
