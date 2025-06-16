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
      body: Column(
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
                if (_userRole == 'Patient')
                  GestureDetector(
                    onTap: () => _showInitiateChatDialog(context),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.primaryColor,
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(Icons.add, color: Colors.white, size: 24),
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
                      stream: _databaseService.fetchUserChats(_currentUserId!),
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
                        (context, url) => const CircularProgressIndicator(),
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
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: FadeTransition(opacity: animation, child: child),
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
                  tablet: 600.0,
                  desktop: 700.0,
                ),
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select a Doctor',
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
                    'Choose a healthcare professional to start a new conversation',
                    style: context.responsiveBodyMedium.copyWith(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _databaseService.fetchUserChats(_currentUserId!),
                      builder: (context, chatSnapshot) {
                        if (chatSnapshot.connectionState ==
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
                        if (chatSnapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error loading chats: ${chatSnapshot.error}',
                              style: context.responsiveBodyLarge.copyWith(
                                color: Colors.red[600],
                              ),
                            ),
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
                            if (doctorSnapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Error loading doctors: ${doctorSnapshot.error}',
                                  style: context.responsiveBodyLarge.copyWith(
                                    color: Colors.red[600],
                                  ),
                                ),
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
                              return Center(
                                child: Text(
                                  'No new doctors available',
                                  style: context.responsiveBodyLarge.copyWith(
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              );
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              itemCount: filteredDoctors.length,
                              separatorBuilder:
                                  (context, index) => Divider(
                                    color: const Color(
                                      0xFF0A2D7B,
                                    ).withOpacity(0.1),
                                    height: 1,
                                    thickness: 1,
                                  ),
                              itemBuilder: (context, index) {
                                final doctor = filteredDoctors[index];
                                final doctorId = doctor['id'] as String;
                                final displayName =
                                    doctor['displayName'] as String;
                                final photoURL = doctor['photoURL'] as String?;
                                final email = doctor['email'] as String;

                                return ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: ResponsiveHelper.getValue(
                                      context,
                                      mobile: 12.0,
                                      tablet: 14.0,
                                      desktop: 16.0,
                                    ),
                                    vertical: 10.0,
                                  ),
                                  leading: _buildProfileAvatar(
                                    photoURL,
                                    displayName,
                                    24,
                                    theme,
                                  ),
                                  title: Text(
                                    displayName,
                                    style: context.responsiveBodyLarge.copyWith(
                                      color: const Color(0xFF0A2D7B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    email,
                                    style: context.responsiveBodyMedium
                                        .copyWith(color: Colors.grey[600]),
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios,
                                    color: const Color(0xFF0A2D7B),
                                    size: 18,
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showMessageInputDialog(
                                      context,
                                      doctorId,
                                      displayName,
                                      email,
                                    );
                                  },
                                  hoverColor: const Color(
                                    0xFF0A2D7B,
                                  ).withOpacity(0.05),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                );
                              },
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
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: FadeTransition(opacity: animation, child: child),
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
