import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_project/screens/patient/patient_dashboard.dart';
import 'package:test_project/screens/profile/profile_setup_page.dart';
import 'package:test_project/screens/launch/starter_page.dart';
import 'package:test_project/services/auth/auth_service.dart';
import 'package:test_project/screens/launch/splash_screen.dart';
import 'package:test_project/screens/auth/authentication_page.dart';
import 'package:test_project/screens/auth/login_page.dart';
import 'package:test_project/screens/auth/signup_page.dart';
import 'package:test_project/screens/chat/chat_screen.dart';
import 'package:test_project/screens/doctor/doctor_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:test_project/theme/app_theme.dart' show lightTheme, darkTheme;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:test_project/screens/courses/course_details_screen.dart';

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

  // Initialize shared_preferences and check rememberMe
  final prefs = await SharedPreferences.getInstance();
  final rememberMe = prefs.getBool('remember_me') ?? true;
  if (!rememberMe) {
    // Clear session if rememberMe was false
    await firebase_auth.FirebaseAuth.instance.signOut();
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
      title: 'Christos Poulis',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
      initialRoute: '/splash',
      supportedLocales: const [Locale('en')],
      localizationsDelegates: const [
        ...GlobalMaterialLocalizations.delegates,
        quill.FlutterQuillLocalizations.delegate,
      ],
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/authWrapper': (context) => const AuthWrapper(),
        '/starterPage': (context) => const StarterPage(),
        '/auth': (context) => AuthenticationPage(),
        '/signUp': (context) => const SignUpScreen(),
        '/login': (context) => const LoginScreen(),
        '/profileSetup': (context) => const ProfileSetupScreen(),
        '/doctorDashboard': (context) => const DoctorDashboard(),
        '/patientDashboard': (context) => const PatientDashboard(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/chat') {
          final arguments = settings.arguments as Map<String, dynamic>?;
          return PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder:
                (context, animation, secondaryAnimation) =>
                    ChatScreen(arguments: arguments),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              const begin = Offset(0.0, 1.0); // Slide from bottom
              const end = Offset.zero;
              const curve = Curves.easeInOut;

              final tween = Tween(
                begin: begin,
                end: end,
              ).chain(CurveTween(curve: curve));

              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          );
        }
        if (settings.name == '/courseDetails') {
          final String courseId = settings.arguments as String;
          return MaterialPageRoute(
            builder:
                (context) => CourseDetailsScreen(
                  courseId: courseId,
                ),
          );
        }
        return null;
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return StreamBuilder<firebase_auth.User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: SpinKitDoubleBounce(color: Color(0xFF0A2D7B), size: 40.0),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder(
            future: authService.fetchUserData(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Colors.white,
                  body: Center(
                    child: SpinKitDoubleBounce(
                      color: Color(0xFF0A2D7B),
                      size: 40.0,
                    ),
                  ),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data != null) {
                final user = userSnapshot.data!;
                if (user.displayName.isEmpty) {
                  return const ProfileSetupScreen();
                }
                return user.role == 'Doctor'
                    ? const DoctorDashboard()
                    : const PatientDashboard();
              } else {
                return const ProfileSetupScreen();
              }
            },
          );
        } else {
          return const StarterPage();
        }
      },
    );
  }
}
