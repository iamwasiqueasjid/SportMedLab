import 'package:test_project/services/auth_service.dart';
import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  final String? userName;
  final String? photoUrl;
  final String role;

  const CustomDrawer({
    Key? key,
    this.userName,
    this.photoUrl,
    required this.role,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final AuthService _authService = AuthService();
    final currentRoute = ModalRoute.of(context)?.settings.name;

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
          ListTile(
            leading: Icon(Icons.dashboard, color: theme.primaryColor),
            title: Text(
              'Dashboard',
              style: TextStyle(color: theme.primaryColor),
            ),
            selected:
                currentRoute == '/doctorDashboard' ||
                currentRoute == '/patientDashboard',
            selectedTileColor: theme.primaryColor.withOpacity(0.1),
            onTap: () async {
              Navigator.pop(context); // Close the drawer

              try {
                final userRole = await _authService.getUserRole();
                final targetRoute =
                    userRole == 'Doctor'
                        ? '/doctorDashboard'
                        : '/patientDashboard';

                if (currentRoute != targetRoute) {
                  Navigator.pushReplacementNamed(context, targetRoute);
                } else {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Already on $userRole Dashboard')),
                    );
                  });
                }
              } catch (e) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error fetching role: $e')),
                  );
                });

                if (currentRoute != '/patientDashboard') {
                  Navigator.pushReplacementNamed(context, '/patientDashboard');
                }
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.person, color: theme.primaryColor),
            title: Text('Profile', style: TextStyle(color: theme.primaryColor)),
            selected: currentRoute == '/profile',
            selectedTileColor: theme.primaryColor.withOpacity(0.1),
            onTap: () {
              Navigator.pop(context);

              Navigator.pushReplacementNamed(context, '/profile');
            },
          ),
          Divider(color: Colors.grey[400]),
          ListTile(
            leading: Icon(Icons.logout, color: theme.primaryColor),
            title: Text('Logout', style: TextStyle(color: theme.primaryColor)),
            onTap: () {
              _authService.signOut(context);
            },
          ),
        ],
      ),
    );
  }
}
