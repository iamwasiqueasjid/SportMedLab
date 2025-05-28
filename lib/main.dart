// Packages
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:test_project/pages/edit_profile.dart';

// Pages
import 'package:test_project/pages/splashScreen.dart';
import 'package:test_project/pages/authenticationPage.dart';
import 'package:test_project/pages/courseDetails.dart';
import 'package:test_project/pages/homePage.dart';
import 'package:test_project/pages/loginPage.dart';
import 'package:test_project/pages/profileSetupPage.dart';
import 'package:test_project/pages/signupPage.dart';
import 'package:test_project/pages/starterPage.dart';
import 'package:test_project/pages/patientDashboard.dart';
import 'package:test_project/pages/doctorDashboard.dart';

// Theme files
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
      home: const SplashScreen(), // Set the initial screen to SplashScreen
      debugShowCheckedModeBanner: false,
      title: 'Comsicon',

      // Provide both light and dark themes
      theme: lightTheme,
      darkTheme: darkTheme,

      // Dynamically pick which theme to use
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // Define initial route
      initialRoute: '/splash', // Change this to your initial route
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
        '/doctorDashboard': (context) => DoctorDashboard(),
        '/patientDashboard': (context) => PatientDashboard(),
        '/profile': (context) => const ProfileScreen(),
        // '/login': (context) => LoginPage(),
        // '/signup': (context) => SignupPage(),-===========[[[[]]]]        // '/settings': (context) => SettingsPage(
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
