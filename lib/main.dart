// Packages
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:test_project/screens/profile/edit_profile.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Pages
import 'package:test_project/screens/splash_screen.dart';
import 'package:test_project/screens/auth/authentication_page.dart';
import 'package:test_project/screens/course_details.dart';
import 'package:test_project/screens/auth/login_page.dart';
import 'package:test_project/screens/profile/profile_setup_page.dart';
import 'package:test_project/screens/auth/signup_page.dart';
import 'package:test_project/screens/starter_page.dart';
import 'package:test_project/screens/patient/patient_dashboard.dart';
import 'package:test_project/screens/doctor/doctor_dashboard.dart';

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

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    throw Exception('Error loading .env file: $e');
  }

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = true;

  // Method that toggles the theme;
  void toggleTheme(bool enableDark) {
    setState(() {
      isDarkMode = enableDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      title: 'Comsicon',

      // Provide both light and dark themes
      theme: lightTheme,
      // darkTheme: darkTheme,

      // Dynamically pick which theme to use
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/splash',
      // Define all routes
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/starterPage': (context) => const starterPage(),
        '/auth': (context) => AuthenticationPage(),
        '/signUp': (context) => const SignUpScreen(),
        '/login': (context) => const LoginScreen(),
        '/profileSetup': (context) => const ProfileSetupScreen(),
        '/doctorDashboard': (context) => DoctorDashboard(),
        '/patientDashboard': (context) => PatientDashboard(),
        '/profile': (context) => const ProfileScreen(),
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
