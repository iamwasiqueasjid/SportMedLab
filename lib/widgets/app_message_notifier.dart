// lib/widgets/app_message_notifier.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/message_type.dart'; // Make sure this path is correct

/// A custom, good-looking, and modern widget to display temporary messages
/// with custom slide-in/slide-out animations.
class AppMessageOverlayContent extends StatefulWidget {
  final String message;
  final MessageType type;
  final VoidCallback onDismissed; // Callback when animation is done
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;
  final Widget? leadingIcon;
  final Widget? trailingAction;

  const AppMessageOverlayContent({
    Key? key,
    required this.message,
    required this.onDismissed,
    this.type = MessageType.info,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.leadingIcon,
    this.trailingAction,
  }) : super(key: key);

  @override
  _AppMessageOverlayContentState createState() =>
      _AppMessageOverlayContentState();
}

class _AppMessageOverlayContentState extends State<AppMessageOverlayContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    AppNotifier._currentState = this;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // Animation duration
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0), // Starts below the screen
      end: Offset.zero, // Ends at its natural position
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Start animation after the widget is laid out
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _hideAndDispose() async {
    await _animationController.reverse(); // Slide out animation
    widget.onDismissed(); // Notify the overlay to remove
  }

  /// Determines the background color based on the message type.
  Color _getBackgroundColor(BuildContext context) {
    if (widget.backgroundColor != null) return widget.backgroundColor!;
    switch (widget.type) {
      case MessageType.success:
        return Colors.green.shade700;
      case MessageType.error:
        return Colors.red.shade700;
      case MessageType.info:
        return Theme.of(context).colorScheme.primary;
      case MessageType.warning:
        return Colors.orange.shade700;
    }
  }

  /// Determines the appropriate icon data based on the message type.
  IconData _getIconData() {
    switch (widget.type) {
      case MessageType.success:
        return Icons.check_circle_outline;
      case MessageType.error:
        return Icons.error_outline;
      case MessageType.info:
        return Icons.info_outline;
      case MessageType.warning:
        return Icons.warning_amber_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = widget.textColor ?? Colors.white;
    final effectiveIconColor = widget.iconColor ?? Colors.white;

    return Positioned(
      bottom: 16, // Adjust distance from bottom
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: _getBackgroundColor(context),
          borderRadius: BorderRadius.circular(12),
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ), // Reduced vertical padding
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Center content vertically
              children: [
                widget.leadingIcon ??
                    Icon(
                      _getIconData(),
                      color: effectiveIconColor,
                      size: 24,
                    ), // Adjust icon size if needed
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: TextStyle(
                      color: effectiveTextColor,
                      fontSize: 16,
                      height:
                          1.2, // Adjust line height to reduce vertical space
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
                ),
                widget.trailingAction ??
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: effectiveTextColor.withOpacity(0.8),
                        size: 20, // Smaller icon size for better balance
                      ),
                      onPressed: _hideAndDispose, // Manual dismiss
                      padding:
                          EdgeInsets
                              .zero, // Remove extra padding around IconButton
                      constraints:
                          const BoxConstraints(), // Remove default constraints
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A static helper class to easily show and manage the custom message notifier.
class AppNotifier {
  static OverlayEntry? _currentOverlayEntry;
  static Timer? _hideTimer;
  static _AppMessageOverlayContentState? _currentState;

  static void show(
    BuildContext context,
    String message, {
    MessageType type = MessageType.info,
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
    Color? textColor,
    Color? iconColor,
    Widget? leadingIcon,
    Widget? trailingAction,
  }) {
    // Hide any currently visible notifier before showing a new one
    // Create a new OverlayEntry
    _currentOverlayEntry = OverlayEntry(
      builder:
          (context) => AppMessageOverlayContent(
            message: message,
            type: type,
            backgroundColor: backgroundColor,
            textColor: textColor,
            iconColor: iconColor,
            leadingIcon: leadingIcon,
            trailingAction: trailingAction,
            onDismissed: () {
              // This callback is triggered when the message wants to disappear
              _currentOverlayEntry?.remove();
              _currentOverlayEntry = null;
              _currentState = null;
            },
          ),
    );

    // Set a timer to automatically hide the message after the duration
    _hideTimer?.cancel(); // Cancel any existing timer
    _hideTimer = Timer(duration, () {
      if (_currentState != null) {
        _currentState!._hideAndDispose();
      }
    });

    // Insert the overlay into the current context
    Overlay.of(context).insert(_currentOverlayEntry!);
  }

  /// Hides the currently displayed message notifier, if any.
  static void hide() {
    _hideTimer?.cancel();
    if (_currentState != null) {
      _currentState!._hideAndDispose();
    } else if (_currentOverlayEntry != null && _currentOverlayEntry!.mounted) {
      _currentOverlayEntry?.remove();
      _currentOverlayEntry = null;
    }
  }
}
