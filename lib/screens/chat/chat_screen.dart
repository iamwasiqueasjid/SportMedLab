import 'package:flutter/material.dart';
import 'package:test_project/services/auth/auth_service.dart';
import 'package:test_project/services/database_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:test_project/utils/message_type.dart';
import 'package:test_project/widgets/app_message_notifier.dart';
import 'package:test_project/utils/responsive_extension.dart';
import 'package:test_project/utils/responsive_helper.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const ChatScreen({super.key, this.arguments});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _messageController = TextEditingController();
  String? _currentUserId;
  String? _otherUserId;
  String? _chatId;
  String? _otherUserName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userData = await _authService.fetchUserData();
      if (userData != null) {
        setState(() {
          _currentUserId = userData.uid;
          _otherUserId =
              widget.arguments?['otherUserId'] ?? _retryLoadArguments();
          _chatId = widget.arguments?['chatId'] ?? _retryLoadArguments();
          _otherUserName = widget.arguments?['otherUserName'] ?? 'Unknown';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        AppNotifier.show(
          context,
          'Failed to load user data',
          type: MessageType.error,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      AppNotifier.show(
        context,
        'Error loading data: $e',
        type: MessageType.error,
      );
    }
  }

  String? _retryLoadArguments() {
    if (widget.arguments == null) {
      AppNotifier.show(
        context,
        'Invalid chat data, please try again',
        type: MessageType.warning,
      );
      Navigator.pop(context);
    }
    return widget.arguments?[ModalRoute.of(context)?.settings.name == '/chat'
        ? 'chatId'
        : 'otherUserId'];
  }

  void _sendMessage() async {
    if (_messageController.text.isEmpty ||
        _currentUserId == null ||
        _otherUserId == null ||
        _chatId == null) {
      AppNotifier.show(
        context,
        'Please enter a message',
        type: MessageType.warning,
      );
      return;
    }

    final success = await _databaseService.sendMessage(
      chatId: _chatId!,
      senderId: _currentUserId!,
      receiverId: _otherUserId!,
      message: _messageController.text,
      context: context,
    );

    if (success) {
      _messageController.clear();
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
          _otherUserName ?? 'Chat',
          style: context.responsiveTitleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.call,
              size: ResponsiveHelper.getValue(
                context,
                mobile: 24.0,
                tablet: 26.0,
                desktop: 28.0,
              ),
              color: Colors.white,
            ),
            onPressed: () {
              // Add call functionality if needed
            },
          ),
        ],
      ),
      body:
          _isLoading
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
              : _currentUserId == null || _chatId == null
              ? Center(
                child: Text(
                  'Unable to load chat',
                  style: context.responsiveBodyLarge,
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveHelper.getValue(
                          context,
                          mobile: 8.0,
                          tablet: 12.0,
                          desktop: 16.0,
                        ),
                        vertical: ResponsiveHelper.getValue(
                          context,
                          mobile: 4.0,
                          tablet: 6.0,
                          desktop: 8.0,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(
                            ResponsiveHelper.getValue(
                              context,
                              mobile: 16.0,
                              tablet: 18.0,
                              desktop: 20.0,
                            ),
                          ),
                        ),
                      ),
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _databaseService.fetchChatMessages(_chatId!),
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
                              child: Text(
                                'Error loading messages: ${snapshot.error}',
                                style: context.responsiveBodyLarge,
                              ),
                            );
                          }
                          final messages = snapshot.data ?? [];
                          return ListView.builder(
                            reverse: true,
                            padding: EdgeInsets.all(
                              ResponsiveHelper.getValue(
                                context,
                                mobile: 8.0,
                                tablet: 10.0,
                                desktop: 12.0,
                              ),
                            ),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final isSentByMe =
                                  message['senderId'] == _currentUserId;
                              return _buildMessageBubble(message, isSentByMe);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(
                      ResponsiveHelper.getValue(
                        context,
                        mobile: 8.0,
                        tablet: 10.0,
                        desktop: 12.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                ResponsiveHelper.getValue(
                                  context,
                                  mobile: 24.0,
                                  tablet: 26.0,
                                  desktop: 28.0,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: ResponsiveHelper.getValue(
                                    context,
                                    mobile: 4.0,
                                    tablet: 5.0,
                                    desktop: 6.0,
                                  ),
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                hintStyle: context.responsiveBodyMedium
                                    .copyWith(color: Colors.grey[600]),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: ResponsiveHelper.getValue(
                                    context,
                                    mobile: 16.0,
                                    tablet: 18.0,
                                    desktop: 20.0,
                                  ),
                                  vertical: ResponsiveHelper.getValue(
                                    context,
                                    mobile: 12.0,
                                    tablet: 14.0,
                                    desktop: 16.0,
                                  ),
                                ),
                              ),
                              style: context.responsiveBodyLarge.copyWith(
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: ResponsiveHelper.getValue(
                            context,
                            mobile: 8.0,
                            tablet: 10.0,
                            desktop: 12.0,
                          ),
                        ),
                        FloatingActionButton(
                          backgroundColor: theme.primaryColor,
                          onPressed: _sendMessage,
                          elevation: ResponsiveHelper.getValue(
                            context,
                            mobile: 4.0,
                            tablet: 5.0,
                            desktop: 6.0,
                          ),
                          shape: CircleBorder(
                            side: BorderSide(
                              color: theme.primaryColor,
                              width: ResponsiveHelper.getValue(
                                context,
                                mobile: 1.0,
                                tablet: 1.5,
                                desktop: 2.0,
                              ),
                            ),
                          ),
                          child: Icon(
                            Icons.send,
                            color: Colors.white,
                            size: ResponsiveHelper.getValue(
                              context,
                              mobile: 20.0,
                              tablet: 22.0,
                              desktop: 24.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isSentByMe) {
    final theme = Theme.of(context);
    final timestamp = message['timestamp'] as DateTime?;
    final formattedTime =
        timestamp != null ? DateFormat('HH:mm').format(timestamp) : '';

    return Container(
      margin: EdgeInsets.symmetric(
        vertical: ResponsiveHelper.getValue(
          context,
          mobile: 4.0,
          tablet: 6.0,
          desktop: 8.0,
        ),
        horizontal: ResponsiveHelper.getValue(
          context,
          mobile: 8.0,
          tablet: 10.0,
          desktop: 12.0,
        ),
      ),
      child: Row(
        mainAxisAlignment:
            isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSentByMe)
            Padding(
              padding: EdgeInsets.only(
                right: ResponsiveHelper.getValue(
                  context,
                  mobile: 8.0,
                  tablet: 10.0,
                  desktop: 12.0,
                ),
              ),
              child: CircleAvatar(
                radius: ResponsiveHelper.getValue(
                  context,
                  mobile: 16.0,
                  tablet: 18.0,
                  desktop: 20.0,
                ),
                backgroundColor: theme.primaryColor.withOpacity(0.2),
                child: Text(
                  _otherUserName?[0].toUpperCase() ?? '?',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: ResponsiveHelper.getValue(
                      context,
                      mobile: 12.0,
                      tablet: 14.0,
                      desktop: 16.0,
                    ),
                  ),
                ),
              ),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isSentByMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.getValue(
                      context,
                      mobile: 12.0,
                      tablet: 14.0,
                      desktop: 16.0,
                    ),
                    vertical: ResponsiveHelper.getValue(
                      context,
                      mobile: 8.0,
                      tablet: 10.0,
                      desktop: 12.0,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSentByMe
                            ? theme.primaryColor.withOpacity(0.8)
                            : Colors.grey[300],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(
                        ResponsiveHelper.getValue(
                          context,
                          mobile: 12.0,
                          tablet: 14.0,
                          desktop: 16.0,
                        ),
                      ),
                      topRight: Radius.circular(
                        ResponsiveHelper.getValue(
                          context,
                          mobile: 12.0,
                          tablet: 14.0,
                          desktop: 16.0,
                        ),
                      ),
                      bottomLeft:
                          isSentByMe
                              ? Radius.circular(
                                ResponsiveHelper.getValue(
                                  context,
                                  mobile: 12.0,
                                  tablet: 14.0,
                                  desktop: 16.0,
                                ),
                              )
                              : Radius.circular(0),
                      bottomRight:
                          isSentByMe
                              ? Radius.circular(0)
                              : Radius.circular(
                                ResponsiveHelper.getValue(
                                  context,
                                  mobile: 12.0,
                                  tablet: 14.0,
                                  desktop: 16.0,
                                ),
                              ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: ResponsiveHelper.getValue(
                          context,
                          mobile: 4.0,
                          tablet: 5.0,
                          desktop: 6.0,
                        ),
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message['message'],
                    style: TextStyle(
                      color: isSentByMe ? Colors.white : Colors.black87,
                      fontSize: ResponsiveHelper.getValue(
                        context,
                        mobile: 14.0,
                        tablet: 16.0,
                        desktop: 18.0,
                      ),
                    ),
                  ),
                ),
                if (formattedTime.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      top: ResponsiveHelper.getValue(
                        context,
                        mobile: 4.0,
                        tablet: 6.0,
                        desktop: 8.0,
                      ),
                    ),
                    child: Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getValue(
                          context,
                          mobile: 10.0,
                          tablet: 11.0,
                          desktop: 12.0,
                        ),
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isSentByMe)
            Padding(
              padding: EdgeInsets.only(
                left: ResponsiveHelper.getValue(
                  context,
                  mobile: 8.0,
                  tablet: 10.0,
                  desktop: 12.0,
                ),
              ),
              child: CircleAvatar(
                radius: ResponsiveHelper.getValue(
                  context,
                  mobile: 16.0,
                  tablet: 18.0,
                  desktop: 20.0,
                ),
                backgroundColor: theme.primaryColor.withOpacity(0.2),
                child: Text(
                  _currentUserId?[0].toUpperCase() ?? '?',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: ResponsiveHelper.getValue(
                      context,
                      mobile: 12.0,
                      tablet: 14.0,
                      desktop: 16.0,
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
