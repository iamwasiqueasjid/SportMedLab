import 'package:test_project/services/auth_service.dart';
import 'package:flutter/material.dart';

class CustomSidebar extends StatefulWidget {
  final String userName;

  const CustomSidebar({super.key, required this.userName});

  @override
  _CustomSidebarState createState() => _CustomSidebarState();
}

class _CustomSidebarState extends State<CustomSidebar> {
  final _authService = AuthService();
  String? userName;
  String? photoUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // fetchUserData();
  }

  // Future<void> fetchUserData() async {
  //   final userData = await _authService.fetchUserData();
  //   if (userData != null) {
  //     setState(() {
  //       userName = userData['displayName'];
  //       photoUrl = userData['photoURL'];
  //       isLoading = false;
  //     });
  //   } else {
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: Container(
        // Let the theme decide background color for the drawer
        color: theme.colorScheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.transparent),
              currentAccountPicture: CircleAvatar(
                backgroundImage:
                    photoUrl != null
                        ? NetworkImage(photoUrl!) // Use the fetched photo URL
                        : AssetImage('assets/icons/Avatar.png')
                            as ImageProvider, // Use default local image
                backgroundColor: photoUrl == null ? Colors.blue : null,
              ),
              accountName:
                  isLoading
                      ? Text('Loading...', style: theme.textTheme.bodyLarge)
                      : Text(
                        userName ?? widget.userName,
                        style:
                            theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ) ??
                            TextStyle(fontWeight: FontWeight.bold),
                      ),
              accountEmail: null,
            ),
            ListTile(
              leading: Icon(Icons.home, color: theme.iconTheme.color),
              title: Text("Home", style: theme.textTheme.bodyLarge),
              onTap: () {
                Navigator.pushNamed(context, '/home');
              },
            ),
            ListTile(
              leading: Icon(Icons.star, color: theme.iconTheme.color),
              title: Text("Premium", style: theme.textTheme.bodyLarge),
              onTap: () {
                Navigator.pushNamed(context, '/premiumPackages');
              },
            ),
            ListTile(
              leading: Icon(Icons.flag, color: theme.iconTheme.color),
              title: Text("Challenge", style: theme.textTheme.bodyLarge),
              onTap: () {
                Navigator.pushNamed(context, '/chellenges');
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications, color: theme.iconTheme.color),
              title: Text("Notifications", style: theme.textTheme.bodyLarge),
              onTap: () {
                Navigator.pushNamed(context, '/notifications');
              },
            ),
            ListTile(
              leading: Icon(Icons.visibility_off, color: theme.iconTheme.color),
              title: Text("Hide Challenges", style: theme.textTheme.bodyLarge),
              onTap: () {
                Navigator.pushNamed(context, '/hiddenChellenges');
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: theme.iconTheme.color),
              title: Text("Settings", style: theme.textTheme.bodyLarge),
              onTap: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
            ListTile(
              leading: Icon(Icons.person, color: theme.iconTheme.color),
              title: Text("Profile", style: theme.textTheme.bodyLarge),
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
            const Spacer(),
            ListTile(
              leading: Icon(Icons.logout, color: theme.colorScheme.error),
              title: Text(
                "Log out",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              onTap: () {
                _authService.signOut(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
