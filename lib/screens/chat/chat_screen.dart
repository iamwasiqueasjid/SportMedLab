import 'package:flutter/material.dart';
import 'package:test_project/services/auth/auth_service.dart';
import 'package:test_project/services/database_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:test_project/utils/message_type.dart';
import 'package:test_project/widgets/app_message_notifier.dart';

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
    print('ChatScreen initState: arguments = ${widget.arguments}');
    _loadData();
  }

  Future<void> _loadData() async {
    print('Loading data...');
    try {
      final userData = await _authService.fetchUserData();
      print('User data fetched: $userData');
      if (userData != null) {
        setState(() {
          _currentUserId = userData.uid;
          _otherUserId =
              widget.arguments?['otherUserId'] ?? _retryLoadArguments();
          _chatId = widget.arguments?['chatId'] ?? _retryLoadArguments();
          _otherUserName = widget.arguments?['otherUserName'] ?? 'Unknown';
          _isLoading = false;
          print(
            'Loaded: _currentUserId=$_currentUserId, _chatId=$_chatId, _otherUserId=$_otherUserId, _otherUserName=$_otherUserName',
          );
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
      print('Error in _loadData: $e');
    }
  }

  String? _retryLoadArguments() {
    print('Retrying to load arguments: ${widget.arguments}');
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
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            color: Colors.white,
            onPressed: () {
              // Add call functionality if needed
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: SpinKitDoubleBounce(
                  color: Color(0xFF0A2D7B),
                  size: 40.0,
                ),
              )
              : _currentUserId == null || _chatId == null
              ? const Center(child: Text('Unable to load chat'))
              : Column(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _databaseService.fetchChatMessages(_chatId!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: SpinKitDoubleBounce(
                                color: Color(0xFF0A2D7B),
                                size: 40.0,
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error loading messages: ${snapshot.error}',
                              ),
                            );
                          }
                          final messages = snapshot.data ?? [];
                          print('Messages received: $messages');
                          return ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.all(8),
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
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                hintStyle: TextStyle(color: Colors.grey[600]),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              style: TextStyle(color: Colors.black87),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FloatingActionButton(
                          backgroundColor: theme.primaryColor,
                          onPressed: _sendMessage,
                          child: const Icon(Icons.send, color: Colors.white),
                          elevation: 4,
                          shape: const CircleBorder(),
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
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment:
            isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSentByMe)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                backgroundColor: theme.primaryColor.withOpacity(0.2),
                child: Text(
                  _otherUserName?[0].toUpperCase() ?? '?',
                  style: TextStyle(color: theme.primaryColor),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSentByMe
                            ? theme.primaryColor.withOpacity(0.8)
                            : Colors.grey[300],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft:
                          isSentByMe
                              ? const Radius.circular(12)
                              : const Radius.circular(0),
                      bottomRight:
                          isSentByMe
                              ? const Radius.circular(0)
                              : const Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message['message'],
                    style: TextStyle(
                      color: isSentByMe ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                if (formattedTime.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      formattedTime,
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),
          ),
          if (isSentByMe)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: CircleAvatar(
                backgroundColor: theme.primaryColor.withOpacity(0.2),
                child: Text(
                  _currentUserId?[0].toUpperCase() ?? '?',
                  style: TextStyle(color: theme.primaryColor),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
