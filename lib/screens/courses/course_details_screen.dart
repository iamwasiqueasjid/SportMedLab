import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:test_project/models/course.dart';
import 'package:test_project/models/lesson.dart';
import 'package:test_project/services/database_service.dart';
import 'package:test_project/utils/message_type.dart';
import 'package:test_project/utils/responsive_extension.dart';
import 'package:test_project/utils/responsive_helper.dart';
import 'package:test_project/widgets/app_message_notifier.dart';

class CourseDetailsScreen extends StatefulWidget {
  final String courseId;
  final VoidCallback? onEnrollSuccess;

  const CourseDetailsScreen({
    super.key,
    required this.courseId,
    this.onEnrollSuccess,
  });

  static Future<void> show({
    required BuildContext context,
    required String courseId,
    VoidCallback? onEnrollSuccess,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return CourseDetailsScreen(
          courseId: courseId,
          onEnrollSuccess: onEnrollSuccess,
        );
      },
    );
  }

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  Course? _courseData;
  List<Lesson> _lessons = [];
  String _doctorName = 'Unknown Doctor';
  bool _isLoading = true;
  bool _isEnrolling = false;

  @override
  void initState() {
    super.initState();
    _loadCourseData();
  }

  Future<void> _loadCourseData() async {
    try {
      final course = await _databaseService.getCourseById(widget.courseId);
      final lessons =
          await _databaseService.fetchLessonsForCourse(widget.courseId).first;
      final userDetails = await _databaseService.fetchUserDetails(
        course?.tutorId ?? '',
      );

      setState(() {
        _courseData = course;
        _lessons = lessons;
        _doctorName = userDetails?['displayName'] ?? 'Unknown Doctor';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppNotifier.show(
        context,
        'Error loading course details: $e',
        type: MessageType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.mediumSpacing),
      ),
      backgroundColor: Colors.white,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: ResponsiveHelper.getValue(
            context,
            mobile: 320.0,
            tablet: 500.0,
            desktop: 600.0,
          ),
          maxHeight:
              _isLoading
                  ? MediaQuery.of(context).size.height *
                      0.3 // Reduced height for loading
                  : MediaQuery.of(context).size.height *
                      0.8, // Normal height for content
        ),
        child:
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(context, theme),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(context.mediumSpacing),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCourseInfo(context, theme),
                            SizedBox(height: context.mediumSpacing),
                            _buildLessonsList(context, theme),
                          ],
                        ),
                      ),
                    ),
                    _buildActionButtons(context, theme),
                  ],
                ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.primaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(context.mediumSpacing),
          topRight: Radius.circular(context.mediumSpacing),
        ),
      ),
      padding: EdgeInsets.all(context.mediumSpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              _courseData?.title ?? 'Course Details',
              style: context.responsiveTitleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: Colors.white,
              size: ResponsiveHelper.getValue(
                context,
                mobile: 20.0,
                tablet: 22.0,
                desktop: 24.0,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseInfo(BuildContext context, ThemeData theme) {
    String formattedDate = 'Date not available';
    if (_courseData?.createdAt != null) {
      formattedDate = DateFormat('MMM d, yyyy').format(_courseData!.createdAt!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Course Information',
          style: context.responsiveHeadlineMedium.copyWith(
            color: theme.primaryColor,
          ),
        ),
        SizedBox(height: context.smallSpacing),
        _buildInfoRow(
          context,
          theme,
          icon: Icons.person,
          label: 'Created by',
          value: _doctorName,
        ),
        _buildInfoRow(
          context,
          theme,
          icon: Icons.people,
          label: 'Enrolled',
          value: '${_courseData?.enrolledCount ?? 0} patients',
        ),
        _buildInfoRow(
          context,
          theme,
          icon: Icons.calendar_today,
          label: 'Created on',
          value: formattedDate,
        ),
        if (_courseData?.description.isNotEmpty ?? false) ...[
          SizedBox(height: context.mediumSpacing),
          Text(
            'Description',
            style: context.responsiveBodyLarge.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: context.smallSpacing),
          Text(
            _courseData!.description,
            style: context.responsiveBodyMedium.copyWith(
              color: Colors.grey[700],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.smallSpacing / 2),
      child: Row(
        children: [
          Icon(
            icon,
            size: ResponsiveHelper.getValue(
              context,
              mobile: 16.0,
              tablet: 18.0,
              desktop: 20.0,
            ),
            color: theme.primaryColor,
          ),
          SizedBox(width: context.smallSpacing),
          Text(
            '$label: ',
            style: context.responsiveBodyMedium.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: context.responsiveBodyMedium.copyWith(
                color: Colors.grey[700],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsList(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lessons (${_lessons.length})',
          style: context.responsiveHeadlineMedium.copyWith(
            color: theme.primaryColor,
          ),
        ),
        SizedBox(height: context.smallSpacing),
        if (_lessons.isEmpty)
          Text(
            'No lessons available yet',
            style: context.responsiveBodyMedium.copyWith(
              color: Colors.grey[600],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _lessons.length,
            itemBuilder: (context, index) {
              final lesson = _lessons[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: theme.primaryColor.withOpacity(0.1),
                  child: Text(
                    '${index + 1}',
                    style: context.responsiveBodyMedium.copyWith(
                      color: theme.primaryColor,
                    ),
                  ),
                ),
                title: Text(
                  lesson.title.isNotEmpty ? lesson.title : 'Untitled Lesson',
                  style: context.responsiveBodyLarge.copyWith(
                    color: Colors.grey[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(context.mediumSpacing),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(context.mediumSpacing),
          bottomRight: Radius.circular(context.mediumSpacing),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: context.responsiveBodyLarge.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          SizedBox(width: context.mediumSpacing),
          ElevatedButton(
            onPressed:
                _isEnrolling
                    ? null
                    : () async {
                      setState(() {
                        _isEnrolling = true;
                      });
                      final success = await _databaseService.enrollInCourse(
                        courseId: widget.courseId,
                        context: context,
                      );
                      if (success) {
                        Navigator.of(context).pop();
                        widget.onEnrollSuccess?.call();
                      }
                      setState(() {
                        _isEnrolling = false;
                      });
                    },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              padding: EdgeInsets.symmetric(
                horizontal: context.mediumSpacing,
                vertical: context.smallSpacing,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.smallSpacing),
              ),
            ),
            child:
                _isEnrolling
                    ? SpinKitCircle(
                      color: Colors.white,
                      size: ResponsiveHelper.getValue(
                        context,
                        mobile: 20.0,
                        tablet: 22.0,
                        desktop: 24.0,
                      ),
                    )
                    : Text(
                      'Enroll',
                      style: context.responsiveBodyLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
