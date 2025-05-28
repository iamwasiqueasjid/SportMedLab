import 'package:test_project/services/databaseHandler.dart';
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
    final DatabaseService _databaseService = DatabaseService();

    return Drawer(
      backgroundColor: const Color(0xFFF0F4F8), // Soft blue-gray background
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
                          : AssetImage('assets/images/avatar.png')
                              as ImageProvider,
                  backgroundColor: Colors.white,
                ),
                SizedBox(height: 10),
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
                ModalRoute.of(context)?.settings.name == '/doctorDashboard' ||
                ModalRoute.of(context)?.settings.name == '/patientDashboard',
            selectedTileColor: theme.primaryColor.withOpacity(0.1),
            onTap: () {
              Navigator.pop(context);
              _databaseService.getUserRole().then((userRole) {
                if (userRole == 'Doctor') {
                  Navigator.pushReplacementNamed(context, '/doctorDashboard');
                } else {
                  Navigator.pushReplacementNamed(context, '/patientDashboard');
                }
              });
            },
          ),
          ListTile(
            leading: Icon(Icons.person, color: theme.primaryColor),
            title: Text('Profile', style: TextStyle(color: theme.primaryColor)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),
          Divider(color: Colors.grey[400]),
          ListTile(
            leading: Icon(Icons.logout, color: theme.primaryColor),
            title: Text('Logout', style: TextStyle(color: theme.primaryColor)),
            onTap: () {
              _databaseService.signOut(context);
            },
          ),
        ],
      ),
    );
  }
}
