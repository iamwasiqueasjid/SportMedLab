import 'package:flutter/material.dart';
import 'package:test_project/services/auth/auth_service.dart';
import 'package:test_project/services/database_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:test_project/utils/message_type.dart';
import 'package:test_project/widgets/app_message_notifier.dart';
import 'package:test_project/utils/responsive_extension.dart';
import 'package:test_project/utils/responsive_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatListWidget extends StatefulWidget {
  const ChatListWidget({super.key});

  @override
  State<ChatListWidget> createState() => _ChatListWidgetState();
}

class _ChatListWidgetState extends State<ChatListWidget> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  String? _currentUserId;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await _authService.fetchUserData();
    if (userData != null) {
      setState(() {
        _currentUserId = userData.uid;
        _userRole = userData.role;
      });
    } else {
      if (mounted) {
        AppNotifier.show(
          context,
          'Failed to load user data',
          type: MessageType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  left: 24,
                  right: 24,
                  bottom: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: theme.primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Messages',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: theme.primaryColor,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            _userRole == 'Patient'
                                ? 'Connect with Healthcare Professionals'
                                : 'Connect with Patients',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: ResponsiveHelper.getValue(
                  context,
                  mobile: 16.0,
                  tablet: 20.0,
                  desktop: 24.0,
                ),
              ),
              Expanded(
                child:
                    _currentUserId == null
                        ? Center(
                          child: SpinKitDoubleBounce(
                            color: const Color(0xFF0A2D7B),
                            size: ResponsiveHelper.getValue(
                              context,
                              mobile: 40.0,
                              tablet: 50.0,
                              desktop: 60.0,
                            ),
                          ),
                        )
                        : StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _databaseService.fetchUserChats(
                            _currentUserId!,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                child: SpinKitDoubleBounce(
                                  color: const Color(0xFF0A2D7B),
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
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Error loading chats: ${snapshot.error}',
                                      style: context.responsiveBodyLarge,
                                    ),
                                    SizedBox(
                                      height: ResponsiveHelper.getValue(
                                        context,
                                        mobile: 16.0,
                                        tablet: 20.0,
                                        desktop: 24.0,
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => setState(() {}),
                                      child: Text(
                                        'Retry',
                                        style: context.responsiveBodyLarge,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            final chats = snapshot.data ?? [];
                            if (chats.isEmpty) {
                              return Center(
                                child: Text(
                                  'No chats yet',
                                  style: context.responsiveBodyLarge,
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveHelper.getValue(
                                  context,
                                  mobile: 16.0,
                                  tablet: 20.0,
                                  desktop: 24.0,
                                ),
                              ),
                              itemCount: chats.length,
                              itemBuilder: (context, index) {
                                final chat = chats[index];
                                return _buildChatTile(context, chat);
                              },
                            );
                          },
                        ),
              ),
            ],
          ),

          if (_userRole == 'Patient')
            Positioned(
              bottom: 16.0,
              right: 16.0,
              child: FloatingActionButton(
                onPressed: () => _showInitiateChatDialog(context),
                backgroundColor: theme.primaryColor,
                // tooltip: 'Add New Fitness Plan',
                child: Icon(
                  Icons.message,
                  color: Colors.white,
                  size: ResponsiveHelper.getValue(
                    context,
                    mobile: 24.0,
                    tablet: 26.0,
                    desktop: 28.0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, Map<String, dynamic> chat) {
    final theme = Theme.of(context);
    final otherUserId =
        chat['participants'].firstWhere(
              (id) => id != _currentUserId,
              orElse: () => '',
            )
            as String;

    if (otherUserId.isEmpty) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _databaseService.fetchUserDetails(otherUserId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ListTile(title: Text('Loading...'), subtitle: Text(''));
        }
        final userDetails = snapshot.data!;
        final displayName = userDetails['displayName'] ?? 'Unknown';
        final photoURL = userDetails['photoURL'] as String?;
        final lastMessage = chat['lastMessage'] ?? '';
        final lastMessageTimestamp = chat['lastMessageTimestamp'] as DateTime?;
        final formattedTime =
            lastMessageTimestamp != null
                ? DateFormat('MMM d, HH:mm').format(lastMessageTimestamp)
                : '';

        return Card(
          margin: EdgeInsets.only(
            bottom: ResponsiveHelper.getValue(
              context,
              mobile: 12.0,
              tablet: 14.0,
              desktop: 16.0,
            ),
          ),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getValue(
                context,
                mobile: 12.0,
                tablet: 14.0,
                desktop: 16.0,
              ),
            ),
            side: BorderSide(color: theme.primaryColor, width: 1.0),
          ),
          elevation: ResponsiveHelper.getValue(
            context,
            mobile: 2.0,
            tablet: 3.0,
            desktop: 4.0,
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(
              ResponsiveHelper.getValue(
                context,
                mobile: 8.0,
                tablet: 10.0,
                desktop: 12.0,
              ),
            ),
            leading: _buildProfileAvatar(photoURL, displayName, 20, theme),
            title: Text(
              displayName,
              style: context.responsiveBodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            subtitle: Text(
              lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.responsiveBodyMedium.copyWith(
                color: theme.primaryColor,
              ),
            ),
            trailing: Text(
              formattedTime,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/chat',
                arguments: {
                  'chatId': chat['chatId'],
                  'otherUserId': otherUserId,
                  'otherUserName': displayName,
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProfileAvatar(
    String? imageUrl,
    String? fallbackText,
    double radius,
    ThemeData theme,
  ) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF1A1A2E),
        child: ClipOval(
          child:
              imageUrl != null && imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: radius * 2,
                    height: radius * 2,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => const SpinKitDoubleBounce(
                          color: Color(0xFF0A2D7B),
                          size: 40.0,
                        ),
                    errorWidget:
                        (context, url, error) => Image.asset(
                          'assets/images/Avatar.png',
                          width: radius * 2,
                          height: radius * 2,
                          fit: BoxFit.cover,
                        ),
                  )
                  : Image.asset(
                    'assets/images/Avatar.png',
                    width: radius * 2,
                    height: radius * 2,
                    fit: BoxFit.cover,
                  ),
        ),
      ),
    );
  }

  void _showInitiateChatDialog(BuildContext context) {
    final theme = Theme.of(context);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 450),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1), // Slide up from bottom
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.white.withOpacity(0.95)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFF0A2D7B).withOpacity(0.05),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: const Color(0xFF0A2D7B).withOpacity(0.08),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: EdgeInsets.all(
                  ResponsiveHelper.getValue(
                    context,
                    mobile: 16.0,
                    tablet: 20.0,
                    desktop: 24.0,
                  ),
                ),
                constraints: BoxConstraints(
                  maxWidth: ResponsiveHelper.getValue(
                    context,
                    mobile: double.infinity,
                    tablet: 600.0,
                    desktop: 700.0,
                  ),
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A2D7B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.medical_services_outlined,
                              color: const Color(0xFF0A2D7B),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Select a Doctor',
                              style: context.responsiveHeadlineMedium.copyWith(
                                color: const Color(0xFF0A2D7B),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                                fontSize: ResponsiveHelper.getValue(
                                  context,
                                  mobile: 20.0,
                                  tablet: 22.0,
                                  desktop: 24.0,
                                ),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                              onPressed: () => Navigator.pop(context),
                              splashRadius: 16,
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Choose a healthcare professional to start a new conversation',
                        style: context.responsiveBodyMedium.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                          fontSize: ResponsiveHelper.getValue(
                            context,
                            mobile: 13.0,
                            tablet: 14.0,
                            desktop: 14.0,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      height: 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            const Color(0xFF0A2D7B).withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _databaseService.fetchUserChats(
                          _currentUserId!,
                        ),
                        builder: (context, chatSnapshot) {
                          if (chatSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _buildLoadingState(context);
                          }
                          if (chatSnapshot.hasError) {
                            return _buildErrorState(
                              context,
                              'Error loading chats: ${chatSnapshot.error}',
                            );
                          }

                          final chats = chatSnapshot.data ?? [];
                          final chattedDoctorIds =
                              chats
                                  .map(
                                    (chat) => chat['participants'].firstWhere(
                                      (id) => id != _currentUserId,
                                      orElse: () => '',
                                    ),
                                  )
                                  .where((id) => id.isNotEmpty)
                                  .toSet();

                          return StreamBuilder<List<Map<String, dynamic>>>(
                            stream: _databaseService.fetchDoctors(),
                            builder: (context, doctorSnapshot) {
                              if (doctorSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return _buildLoadingState(context);
                              }
                              if (doctorSnapshot.hasError) {
                                return _buildErrorState(
                                  context,
                                  'Error loading doctors: ${doctorSnapshot.error}',
                                );
                              }

                              final doctors = doctorSnapshot.data ?? [];
                              final filteredDoctors =
                                  doctors
                                      .where(
                                        (doctor) =>
                                            !chattedDoctorIds.contains(
                                              doctor['id'],
                                            ),
                                      )
                                      .toList();

                              if (filteredDoctors.isEmpty) {
                                return _buildEmptyState(context);
                              }

                              return _buildDoctorsList(
                                context,
                                filteredDoctors,
                                theme,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A2D7B).withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: SpinKitDoubleBounce(
              color: const Color(0xFF0A2D7B),
              size: ResponsiveHelper.getValue(
                context,
                mobile: 32.0,
                tablet: 36.0,
                desktop: 40.0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Loading doctors...',
            style: context.responsiveBodyMedium.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: Colors.red[400],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Oops! Something went wrong',
            style: context.responsiveBodyLarge.copyWith(
              color: Colors.red[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: context.responsiveBodyMedium.copyWith(
              color: Colors.red[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.people_outline_rounded,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No new doctors available',
            style: context.responsiveBodyLarge.copyWith(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You\'ve already started conversations with all available doctors',
            style: context.responsiveBodyMedium.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorsList(
    BuildContext context,
    List<Map<String, dynamic>> doctors,
    ThemeData theme,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemCount: doctors.length,
      separatorBuilder:
          (context, index) => Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFF0A2D7B).withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
      itemBuilder: (context, index) {
        final doctor = doctors[index];
        final doctorId = doctor['id'] as String;
        final displayName = doctor['displayName'] as String;
        final photoURL = doctor['photoURL'] as String?;
        final email = doctor['email'] as String;

        return AnimatedContainer(
          duration: Duration(milliseconds: 200 + (index * 50)),
          curve: Curves.easeOutCubic,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.transparent,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.pop(context);
                  _showMessageInputDialog(
                    context,
                    doctorId,
                    displayName,
                    email,
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.getValue(
                      context,
                      mobile: 16.0,
                      tablet: 18.0,
                      desktop: 20.0,
                    ),
                    vertical: 16.0,
                  ),
                  child: Row(
                    children: [
                      // Enhanced Avatar
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0A2D7B).withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _buildProfileAvatar(
                          photoURL,
                          displayName,
                          24,
                          theme,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Doctor Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: context.responsiveBodyLarge.copyWith(
                                color: const Color(0xFF0A2D7B),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: context.responsiveBodyMedium.copyWith(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Enhanced Action Button
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A2D7B).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: const Color(0xFF0A2D7B),
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMessageInputDialog(
    BuildContext context,
    String doctorId,
    String doctorName,
    String doctorEmail,
  ) {
    final theme = Theme.of(context);
    final messageController = TextEditingController();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 450),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1), // Slide up from bottom
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Card(
            color: Colors.white,
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Container(
              padding: EdgeInsets.all(
                ResponsiveHelper.getValue(
                  context,
                  mobile: 20.0,
                  tablet: 24.0,
                  desktop: 28.0,
                ),
              ),
              constraints: BoxConstraints(
                maxWidth: ResponsiveHelper.getValue(
                  context,
                  mobile: double.infinity,
                  tablet: 500.0,
                  desktop: 600.0,
                ),
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Message $doctorName',
                        style: context.responsiveHeadlineMedium.copyWith(
                          color: const Color(0xFF0A2D7B),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: const Color(0xFF0A2D7B),
                          size: 28,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Start a new conversation with $doctorName',
                    style: context.responsiveBodyMedium.copyWith(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      labelText: 'Initial Message',
                      hintText: 'Type your message',
                      labelStyle: context.responsiveBodyMedium.copyWith(
                        color: const Color(0xFF0A2D7B),
                      ),
                      hintStyle: context.responsiveBodyMedium.copyWith(
                        color: Colors.grey[400],
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: const Color(0xFF0A2D7B),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: const Color(0xFF0A2D7B),
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: const Color(0xFF0A2D7B).withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                    ),
                    style: context.responsiveBodyLarge.copyWith(
                      color: Colors.black87,
                    ),
                    maxLines: 4,
                    minLines: 2,
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: context.responsiveBodyLarge.copyWith(
                            color: const Color(0xFF0A2D7B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A2D7B),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveHelper.getValue(
                              context,
                              mobile: 20.0,
                              tablet: 24.0,
                              desktop: 28.0,
                            ),
                            vertical: ResponsiveHelper.getValue(
                              context,
                              mobile: 12.0,
                              tablet: 14.0,
                              desktop: 16.0,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        onPressed: () async {
                          if (messageController.text.isEmpty) {
                            AppNotifier.show(
                              context,
                              'Please enter a message',
                              type: MessageType.warning,
                            );
                            return;
                          }

                          final chatId = await _databaseService.initiateChat(
                            patientId: _currentUserId!,
                            doctorEmail: doctorEmail,
                            initialMessage: messageController.text,
                            context: context,
                          );

                          if (chatId != null) {
                            Navigator.pop(context);
                            Navigator.pushNamed(
                              context,
                              '/chat',
                              arguments: {
                                'chatId': chatId,
                                'otherUserId': doctorId,
                                'otherUserName': doctorName,
                              },
                            );
                          }
                        },
                        child: Text(
                          'Send',
                          style: context.responsiveBodyLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
