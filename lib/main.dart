import 'package:test_project/pages/authenticationPage.dart';
import 'package:test_project/pages/courseDetails.dart';
import 'package:test_project/pages/homePage.dart';
import 'package:test_project/pages/loginPage.dart';
import 'package:test_project/pages/profileSetupPage.dart';
import 'package:test_project/pages/signupPage.dart';
import 'package:test_project/pages/starterPage.dart';
import 'package:test_project/pages/studentDashboard.dart';
import 'package:test_project/pages/tutorDashboard.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

// Import your pages here
import 'package:test_project/pages/splashScreen.dart';
// Add your other page imports as needed, for example:
// import 'package:comsicon/pages/homePage.dart';
// import 'package:comsicon/pages/authPage.dart';
// etc.

// Import your theme files (you'll need to create these)
import 'package:test_project/theme/app_theme.dart' show lightTheme, darkTheme;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if Firebase is already initialized
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  /// Tracks whether the app should be in dark mode or light mode
  bool isDarkMode =
      true; // Default: Dark. Set to false if you want Light by default

  /// Method that toggles the theme; called from SettingsScreen
  void toggleTheme(bool enableDark) {
    setState(() {
      isDarkMode = enableDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Comsicon',

      // Provide both light and dark themes
      theme: lightTheme,
      darkTheme: darkTheme,

      // Dynamically pick which theme to use
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // Define initial route
      initialRoute: '/splash',

      // Define all routes
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/starterPage': (context) => const starterPage(), // Your starter page
        '/auth': (context) => AuthenticationPage(),
        '/signUp': (context) => const SignUpScreen(), // Your signup page
        '/login': (context) => const LoginScreen(), // Your login page
        '/profileSetup':
            (context) => const ProfileSetupScreen(), // Your profile setup page
        // Add all your other routes here, for example:
        '/home': (context) => HomePage(),
        '/tutorDashboard': (context) => TutorDashboard(),
        '/studentDashboard': (context) => StudentDashboard(),
        // '/login': (context) => LoginPage(),
        // '/signup': (context) => SignupPage(),
        // '/settings': (context) => SettingsPage(
        //   isDarkMode: isDarkMode,
        //   onDarkModeToggled: toggleTheme,
        // ),
        // Add more routes as needed
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/courseDetails') {
          // Extract the courseId from arguments
          final String courseId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => CourseDetailsScreen(courseId: courseId),
          );
        }
        return null;
      },
    );
  }
}
