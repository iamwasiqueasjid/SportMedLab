import 'package:test_project/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:test_project/utils/message_type.dart';
import 'package:test_project/widgets/app_message_notifier.dart';

class CustomDrawer extends StatelessWidget {
  final String? userName;
  final String? photoUrl;
  final String role;

  const CustomDrawer({
    super.key,
    this.userName,
    this.photoUrl,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final AuthService authService = AuthService();
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    return Drawer(
      backgroundColor: const Color(0xFFF0F4F8),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: theme.primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundImage:
                      photoUrl != null
                          ? NetworkImage(photoUrl!)
                          : const AssetImage('assets/images/avatar.png')
                              as ImageProvider,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 10),
                Text(
                  userName ?? role,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  role,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            color:
                (currentRoute == '/doctorDashboard' ||
                        currentRoute == '/patientDashboard')
                    ? theme.primaryColor.withOpacity(
                      0.3,
                    ) // Full overlay for selected
                    : Colors.transparent,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Icon(Icons.dashboard, color: theme.primaryColor),
              title: Text(
                'Dashboard',
                style: TextStyle(color: theme.primaryColor),
              ),
              onTap: () async {
                Navigator.pop(context); // Close the drawer
                try {
                  final userRole = await authService.getUserRole();
                  final targetRoute =
                      userRole == 'Doctor'
                          ? '/doctorDashboard'
                          : '/patientDashboard';
                  if (currentRoute != targetRoute) {
                    Navigator.pushReplacementNamed(context, targetRoute);
                  } else {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      AppNotifier.show(
                        context,
                        'Already on $userRole Dashboard',
                        type: MessageType.info,
                      );
                    });
                  }
                } catch (e) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    AppNotifier.show(
                      context,
                      'Error fetching role: $e',
                      type: MessageType.error,
                    );
                  });
                  if (currentRoute != '/patientDashboard') {
                    Navigator.pushReplacementNamed(
                      context,
                      '/patientDashboard',
                    );
                  }
                }
              },
            ),
          ),
          Container(
            color:
                currentRoute == '/profile'
                    ? theme.primaryColor.withOpacity(
                      0.3,
                    ) // Full overlay for selected
                    : Colors.transparent,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Icon(Icons.person, color: theme.primaryColor),
              title: Text(
                'Profile',
                style: TextStyle(color: theme.primaryColor),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/profile');
              },
            ),
          ),
          Divider(color: Colors.grey[400]),
          Container(
            color: Colors.transparent, // No overlay for Logout
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Icon(Icons.logout, color: theme.primaryColor),
              title: Text(
                'Logout',
                style: TextStyle(color: theme.primaryColor),
              ),
              onTap: () {
                authService.signOut(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
