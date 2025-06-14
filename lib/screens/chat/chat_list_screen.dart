import 'package:flutter/material.dart';
import 'package:test_project/services/auth/auth_service.dart';
import 'package:test_project/services/database_service.dart';
import 'package:test_project/widgets/custom_bottom_navbar.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:test_project/utils/message_type.dart';
import 'package:test_project/widgets/app_message_notifier.dart';

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
        title: const Text('Messages'),
        actions: [
          if (_userRole == 'Patient')
            IconButton(
              icon: const Icon(Icons.add_comment),
              onPressed: () => _showInitiateChatDialog(context),
            ),
        ],
      ),
      body:
          _currentUserId == null
              ? Center(
                child: SpinKitDoubleBounce(
                  color: const Color(0xFF0A2D7B),
                  size: 40.0,
                ),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'All Chats',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
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
                              size: 40.0,
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          print('Stream error: ${snapshot.error}');
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Error loading chats: ${snapshot.error}'),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => setState(() {}),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          );
                        }
                        final chats = snapshot.data ?? [];
                        if (chats.isEmpty) {
                          print('No chats found for userId: $_currentUserId');
                          return const Center(child: Text('No chats yet'));
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
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
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.primaryColor.withOpacity(0.2),
              child: Text(
                displayName[0].toUpperCase(),
                style: TextStyle(color: theme.primaryColor),
              ),
            ),
            title: Text(
              displayName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              formattedTime,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Start New Chat',
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Doctor Email',
                        hintText: 'Enter doctor\'s email',
                        labelStyle: TextStyle(color: theme.primaryColor),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.primaryColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        labelText: 'Initial Message',
                        hintText: 'Type your message',
                        labelStyle: TextStyle(color: theme.primaryColor),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.primaryColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                      style: const TextStyle(color: Colors.black87),
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
                  style: TextStyle(color: theme.primaryColor),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                child: const Text(
                  'Send',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
}
