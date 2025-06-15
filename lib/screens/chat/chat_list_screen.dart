import 'package:flutter/material.dart';
import 'package:test_project/services/auth/auth_service.dart';
import 'package:test_project/services/database_service.dart';
import 'package:test_project/widgets/custom_bottom_navbar.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:test_project/utils/message_type.dart';
import 'package:test_project/widgets/app_message_notifier.dart';
import 'package:test_project/utils/responsive_extension.dart';
import 'package:test_project/utils/responsive_helper.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
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
        print('User loaded: userId=${userData.uid}, role=${userData.role}');
      });
    } else {
      print('Failed to load user data');
      AppNotifier.show(
        context,
        'Failed to load user data',
        type: MessageType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        title: Text(
          'Messages',
          style: context.responsiveTitleLarge.copyWith(color: Colors.white),
        ),
        actions: [
          if (_userRole == 'Patient')
            IconButton(
              icon: Icon(
                Icons.add_comment,
                size: ResponsiveHelper.getValue(
                  context,
                  mobile: 24.0,
                  tablet: 26.0,
                  desktop: 28.0,
                ),
              ),
              onPressed: () => _showInitiateChatDialog(context),
            ),
        ],
      ),
      body:
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
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      'All Chats',
                      style: context.responsiveHeadlineMedium.copyWith(
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
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
                          print('Stream error: ${snapshot.error}');
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
                          print('No chats found for userId: $_currentUserId');
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
      bottomNavigationBar: CustomBottomNavBar(currentRoute: '/messaging'),
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
      print('Invalid chat participants: ${chat['participants']}');
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getValue(
                context,
                mobile: 12.0,
                tablet: 14.0,
                desktop: 16.0,
              ),
            ),
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
            leading: CircleAvatar(
              radius: ResponsiveHelper.getValue(
                context,
                mobile: 20.0,
                tablet: 22.0,
                desktop: 24.0,
              ),
              backgroundColor: theme.primaryColor.withOpacity(0.2),
              child: Text(
                displayName[0].toUpperCase(),
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: ResponsiveHelper.getValue(
                    context,
                    mobile: 16.0,
                    tablet: 18.0,
                    desktop: 20.0,
                  ),
                ),
              ),
            ),
            title: Text(
              displayName,
              style: context.responsiveBodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.responsiveBodyMedium,
            ),
            trailing: Text(
              formattedTime,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            onTap: () {
              print(
                'Navigating to chat with chatId: ${chat['chatId']}, otherUserId: $otherUserId, displayName: $displayName',
              );
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

  void _showInitiateChatDialog(BuildContext context) {
    final theme = Theme.of(context);
    final emailController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getValue(
                  context,
                  mobile: 16.0,
                  tablet: 18.0,
                  desktop: 20.0,
                ),
              ),
            ),
            title: Text(
              'Start New Chat',
              style: context.responsiveHeadlineMedium.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(
                  ResponsiveHelper.getValue(
                    context,
                    mobile: 16.0,
                    tablet: 20.0,
                    desktop: 24.0,
                  ),
                ),
                width: ResponsiveHelper.getValue(
                  context,
                  mobile: double.infinity,
                  tablet: 400.0,
                  desktop: 500.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getValue(
                      context,
                      mobile: 12.0,
                      tablet: 14.0,
                      desktop: 16.0,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Doctor Email',
                        hintText: 'Enter doctor\'s email',
                        labelStyle: context.responsiveBodyMedium.copyWith(
                          color: theme.primaryColor,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getValue(
                              context,
                              mobile: 12.0,
                              tablet: 14.0,
                              desktop: 16.0,
                            ),
                          ),
                          borderSide: BorderSide(color: theme.primaryColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getValue(
                              context,
                              mobile: 12.0,
                              tablet: 14.0,
                              desktop: 16.0,
                            ),
                          ),
                          borderSide: BorderSide(
                            color: theme.primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                      style: context.responsiveBodyLarge.copyWith(
                        color: Colors.black87,
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
                    TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        labelText: 'Initial Message',
                        hintText: 'Type your message',
                        labelStyle: context.responsiveBodyMedium.copyWith(
                          color: theme.primaryColor,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getValue(
                              context,
                              mobile: 12.0,
                              tablet: 14.0,
                              desktop: 16.0,
                            ),
                          ),
                          borderSide: BorderSide(color: theme.primaryColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getValue(
                              context,
                              mobile: 12.0,
                              tablet: 14.0,
                              desktop: 16.0,
                            ),
                          ),
                          borderSide: BorderSide(
                            color: theme.primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                      style: context.responsiveBodyLarge.copyWith(
                        color: Colors.black87,
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: context.responsiveBodyLarge.copyWith(
                    color: theme.primaryColor,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getValue(
                        context,
                        mobile: 12.0,
                        tablet: 14.0,
                        desktop: 16.0,
                      ),
                    ),
                  ),
                ),
                onPressed: () async {
                  if (emailController.text.isEmpty ||
                      messageController.text.isEmpty) {
                    AppNotifier.show(
                      context,
                      'Please fill all fields',
                      type: MessageType.warning,
                    );
                    return;
                  }

                  final chatId = await _databaseService.initiateChat(
                    patientId: _currentUserId!,
                    doctorEmail: emailController.text,
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
                        'otherUserId': chatId.split('_')[1],
                        'otherUserName':
                            emailController.text.split('@')[0], // Fallback name
                      },
                    );
                  }
                },
                child: Text(
                  'Send',
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
