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

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const ChatScreen({super.key, this.arguments});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _messageController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String? _currentUserId;
  String? _otherUserId;
  String? _chatId;
  String? _otherUserName;
  String? _currentUserProfilePic;
  String? _otherUserProfilePic;
  bool _isLoading = true;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadData();
    _messageController.addListener(_onTypingChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageController.removeListener(_onTypingChanged);
    _messageController.dispose();
    super.dispose();
  }

  void _onTypingChanged() {
    final isCurrentlyTyping = _messageController.text.isNotEmpty;
    if (isCurrentlyTyping != _isTyping) {
      setState(() {
        _isTyping = isCurrentlyTyping;
      });
    }
  }

  Future<void> _loadData() async {
    try {
      final userData = await _authService.fetchUserData();
      final otherUserData = await _databaseService.fetchUserDetails(
        widget.arguments?['otherUserId'] ?? '',
      );

      if (userData != null && otherUserData != null) {
        setState(() {
          _currentUserId = userData.uid;
          _currentUserProfilePic = userData.photoURL;
          _otherUserId = widget.arguments?['otherUserId'];
          _chatId = widget.arguments?['chatId'];
          _otherUserName = widget.arguments?['otherUserName'] ?? 'Unknown';
          _otherUserProfilePic = otherUserData['photoURL'] as String?;
          _isLoading = false;
        });
        _animationController.forward();
        await _databaseService.markMessagesAsRead(
          chatId: _chatId!,
          userId: _currentUserId!,
        );
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

  // String? _retryLoadArguments() {
  //   if (widget.arguments == null) {
  //     AppNotifier.show(
  //       context,
  //       'Invalid chat data, please try again',
  //       type: MessageType.warning,
  //     );
  //     Navigator.pop(context);
  //   }
  //   return widget.arguments?[ModalRoute.of(context)?.settings.name == '/chat'
  //       ? 'chatId'
  //       : 'otherUserId'];
  // }

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
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: _buildFuturisticAppBar(theme),
      body:
          _isLoading
              ? _buildLoadingIndicator(theme)
              : _currentUserId == null || _chatId == null
              ? _buildErrorState()
              : FadeTransition(
                opacity: _fadeAnimation,
                child: _buildChatInterface(theme),
              ),
    );
  }

  PreferredSizeWidget _buildFuturisticAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1A2E),
              const Color(0xFF16213E),
              theme.primaryColor.withOpacity(0.8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          _buildProfileAvatar(_otherUserProfilePic, _otherUserName, 20, theme),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _otherUserName ?? 'Chat',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Online',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: theme.primaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        _buildActionButton(Icons.videocam, () {}, theme),
        _buildActionButton(Icons.call, () {}, theme),
        _buildActionButton(Icons.more_vert, () {}, theme),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    VoidCallback onPressed,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildLoadingIndicator(ThemeData theme) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          colors: [Color(0xFF1A1A2E), Color(0xFF0A0A0A)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitPulse(
              color: theme.primaryColor,
              size: ResponsiveHelper.getValue(
                context,
                mobile: 60.0,
                tablet: 70.0,
                desktop: 80.0,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Initializing secure connection...',
              style: context.responsiveBodyLarge.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          colors: [Color(0xFF1A1A2E), Color(0xFF0A0A0A)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load chat',
              style: context.responsiveBodyLarge.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInterface(ThemeData theme) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0A0A), Color(0xFF1A1A2E), Color(0xFF0A0A0A)],
        ),
      ),
      child: Column(
        children: [
          Expanded(child: _buildMessagesList(theme)),
          _buildMessageInput(theme),
        ],
      ),
    );
  }

  Widget _buildMessagesList(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _databaseService.fetchChatMessages(_chatId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: SpinKitThreeBounce(
                color: theme.primaryColor,
                size: ResponsiveHelper.getValue(
                  context,
                  mobile: 30.0,
                  tablet: 35.0,
                  desktop: 40.0,
                ),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading messages: ${snapshot.error}',
                style: context.responsiveBodyLarge.copyWith(
                  color: Colors.white70,
                ),
              ),
            );
          }
          final messages = snapshot.data ?? [];
          return ListView.builder(
            reverse: true,
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final isSentByMe = message['senderId'] == _currentUserId;
              return _buildFuturisticMessageBubble(message, isSentByMe, theme);
            },
          );
        },
      ),
    );
  }

  Widget _buildFuturisticMessageBubble(
    Map<String, dynamic> message,
    bool isSentByMe,
    ThemeData theme,
  ) {
    final timestamp = message['timestamp'] as DateTime?;
    final formattedTime =
        timestamp != null ? DateFormat('HH:mm').format(timestamp) : '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSentByMe) ...[
            _buildProfileAvatar(
              _otherUserProfilePic,
              _otherUserName,
              16,
              theme,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Column(
                crossAxisAlignment:
                    isSentByMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient:
                          isSentByMe
                              ? LinearGradient(
                                colors: [
                                  theme.primaryColor,
                                  theme.primaryColor.withOpacity(0.8),
                                ],
                              )
                              : LinearGradient(
                                colors: [Colors.grey[800]!, Colors.grey[700]!],
                              ),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isSentByMe ? 20 : 5),
                        bottomRight: Radius.circular(isSentByMe ? 5 : 20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isSentByMe
                                  ? theme.primaryColor
                                  : Colors.grey[600]!)
                              .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      message['message'],
                      style: TextStyle(
                        color: isSentByMe ? Colors.white : Colors.white,
                        fontSize: ResponsiveHelper.getValue(
                          context,
                          mobile: 14.0,
                          tablet: 16.0,
                          desktop: 18.0,
                        ),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (formattedTime.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isSentByMe) ...[
            const SizedBox(width: 8),
            _buildProfileAvatar(
              _currentUserProfilePic,
              _currentUserId,
              16,
              theme,
            ),
          ],
        ],
      ),
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
              imageUrl != null && imageUrl.trim().isNotEmpty
                  ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: radius * 2,
                    height: radius * 2,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => const Center(
                          child: SpinKitDoubleBounce(
                            color: Color(0xFF0A2D7B),
                            size: 40.0,
                          ),
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

  Widget _buildMessageInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withOpacity(0.8),
        border: Border(
          top: BorderSide(color: theme.primaryColor.withOpacity(0.2), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A3E),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color:
                      _isTyping
                          ? theme.primaryColor.withOpacity(0.5)
                          : Colors.grey.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        _isTyping
                            ? theme.primaryColor.withOpacity(0.2)
                            : Colors.black.withOpacity(0.1),
                    blurRadius: _isTyping ? 10 : 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  prefixIcon: Icon(
                    Icons.message_outlined,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 24,
              ),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}
