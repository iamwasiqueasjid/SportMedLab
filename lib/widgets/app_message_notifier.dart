import 'package:flutter/material.dart';
import 'package:test_project/utils/message_type.dart';

class AppNotifier {
  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;

  static void show(
    BuildContext context,
    String message, {
    MessageType type = MessageType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (_isShowing) {
      hide();
    }

    _overlayEntry = OverlayEntry(
      builder:
          (context) => _NotificationWidget(
            message: message,
            type: type,
            onDismiss: hide,
          ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isShowing = true;

    // Auto-hide after duration
    Future.delayed(duration, () {
      if (_isShowing) {
        hide();
      }
    });
  }

  static void hide() {
    if (_overlayEntry != null && _isShowing) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _isShowing = false;
    }
  }
}

class _NotificationWidget extends StatefulWidget {
  final String message;
  final MessageType type;
  final VoidCallback onDismiss;

  const _NotificationWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _animationController.reverse();
    widget.onDismiss();
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case MessageType.success:
        return const Color(0xFF10B981); // Green
      case MessageType.error:
        return const Color(0xFFEF4444); // Red
      case MessageType.warning:
        return const Color(0xFFF59E0B); // Amber
      case MessageType.info:
        return const Color(0xFF3B82F6); // Blue
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case MessageType.success:
        return Icons.check_circle_outline;
      case MessageType.error:
        return Icons.error_outline;
      case MessageType.warning:
        return Icons.warning_amber_outlined;
      case MessageType.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Container(
            margin: const EdgeInsets.all(16),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: _getBackgroundColor(),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: _getBackgroundColor().withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_getIcon(), color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _dismiss,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Extension to make it even easier to use
extension AppNotifierExtension on BuildContext {
  void showNotification(
    String message, {
    MessageType type = MessageType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    AppNotifier.show(this, message, type: type, duration: duration);
  }
}


// USAGE
// // Basic usage
// AppNotifier.show(
//   context,
//   'Error loading course: $e',
//   type: MessageType.error,
// );

// // With custom duration
// AppNotifier.show(
//   context,
//   'Success! Course loaded successfully.',
//   type: MessageType.success,
//   duration: Duration(seconds: 5),
// );

// // Using the extension (optional)
// context.showNotification(
//   'This is an info message',
//   type: MessageType.info,
// );