// Packages
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:test_project/screens/profile/edit_profile.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

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
import 'package:test_project/screens/doctor/blog_upload_screen.dart';
import 'package:test_project/screens/patient/patients_screen.dart';

// Theme files
import 'package:test_project/theme/app_theme.dart' show lightTheme, darkTheme;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (e) {
    throw Exception('Firebase initialization error: $e');
  }

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    throw Exception('Error loading .env file: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = true;

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
      theme: lightTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
      initialRoute: '/splash',

      supportedLocales: const [
        Locale('en'),
      ],
      localizationsDelegates: const [
        ...GlobalMaterialLocalizations.delegates,
        quill.FlutterQuillLocalizations.delegate,
      ],

      routes: {
        '/splash': (context) => const SplashScreen(),
        '/starterPage': (context) => const StarterPage(),
        '/auth': (context) => AuthenticationPage(),
        '/signUp': (context) => const SignUpScreen(),
        '/login': (context) => const LoginScreen(),
        '/profileSetup': (context) => const ProfileSetupScreen(),
        '/doctorDashboard': (context) => DoctorDashboard(),
        '/patientDashboard': (context) => PatientDashboard(),
        '/profile': (context) => const ProfileScreen(),
        '/blogUpload': (context) => const AdvancedBlogEditorScreen(),
        '/patientsBlog': (context) => const PatientsScreen(),
      },

      onGenerateRoute: (settings) {
        if (settings.name == '/courseDetails') {
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
