import 'package:flutter/material.dart';
import 'package:test_project/services/auth/auth_service.dart';
import 'package:test_project/utils/message_type.dart';
import 'package:test_project/widgets/app_message_notifier.dart';

class CustomBottomNavBar extends StatefulWidget {
  final String currentRoute;

  const CustomBottomNavBar({Key? key, required this.currentRoute})
    : super(key: key);

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  late int _selectedIndex;

  // Define the routes for navigation
  final List<String> _routes = [
    '/patientDashboard',
    '/blogs',
    '/poseDetection',
    '/messaging',
    '/profile',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize selected index based on current route
    _selectedIndex = _routes.indexOf(widget.currentRoute);
    if (_selectedIndex == -1)
      _selectedIndex = 0; // Default to 0 if route not found
  }

  void _onItemTapped(int index) async {
    final AuthService authService = AuthService();
    final targetRoute = _routes[index];

    // Check if already on the target route
    if (widget.currentRoute == targetRoute) {
      AppNotifier.show(context, 'Already on this page', type: MessageType.info);
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    // Navigate to the selected route
    Navigator.pushReplacementNamed(context, targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 25,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.dashboard_outlined, 0), // Dashboard
            _buildNavItem(Icons.article_outlined, 1), // Blogs
            _buildNavItem(Icons.fitness_center_outlined, 2), // Live Exercise
            _buildNavItem(Icons.chat_bubble_outline, 3), // Messaging
            _buildNavItem(Icons.person_outline, 4), // Profile
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Icon(
          icon,
          color:
              isSelected
                  ? const Color(0xFF0A2D7B)
                  : Colors.black.withOpacity(0.5),
          size: isSelected ? 34 : 28,
        ),
      ),
    );
  }
}
