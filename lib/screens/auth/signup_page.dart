import 'package:flutter/material.dart';
import 'package:test_project/services/auth/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  color: Colors.white,
                  shadowColor:
                      theme.primaryColor, // Match LoginScreen's Card background
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(
                      22.0,
                    ), // Match LoginScreen padding
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch, // Match LoginScreen
                        children: [
                          // 🖼️ App Logo
                          Center(
                            child: Image.asset(
                              'assets/icons/Splash_Logo.png', // Replace with your logo path
                              width: 150, // Match LoginScreen
                              height:
                                  40, // Match LoginScreen (for 2042x484 aspect ratio)
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 14), // Match LoginScreen
                          // 👋 Welcome Text and Subtitle
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Get On Board!",
                                style: TextStyle(
                                  fontSize: 32, // Match LoginScreen
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              ),
                              Text(
                                "Create your profile to start your Journey.",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16, // Match LoginScreen
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30), // Match LoginScreen
                          // 📧 Email Field
                          TextFormField(
                            controller: _emailController,
                            style: TextStyle(color: theme.primaryColor),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(
                                Icons.email,
                                color: theme.primaryColor,
                              ),
                              hintText: 'Enter your email',
                              hintStyle: TextStyle(color: theme.primaryColor),
                              labelStyle: TextStyle(color: theme.primaryColor),
                              filled: true,
                              fillColor: Colors.grey[100],
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.primaryColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.primaryColor,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value!)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // 🔒 Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(color: theme.primaryColor),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(
                                Icons.lock,
                                color: theme.primaryColor,
                              ),
                              hintText: 'Enter your password',
                              hintStyle: TextStyle(color: theme.primaryColor),
                              labelStyle: TextStyle(color: theme.primaryColor),
                              filled: true,
                              fillColor: Colors.grey[100],
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.primaryColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.primaryColor,
                                  width: 2,
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: theme.primaryColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter your password';
                              }
                              if (value!.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // 🔒 Confirm Password Field
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            cursorColor: theme.primaryColor,
                            style: TextStyle(color: theme.primaryColor),
                            decoration: InputDecoration(
                              labelText: 'Re-Enter Password',
                              prefixIcon: Icon(
                                Icons.lock,
                                color: theme.primaryColor,
                              ),
                              hintText: 'Re-Enter your Password',
                              hintStyle: TextStyle(color: theme.primaryColor),
                              labelStyle: TextStyle(color: theme.primaryColor),
                              filled: true,
                              fillColor: Colors.grey[100],
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.primaryColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.primaryColor,
                                  width: 2,
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: theme.primaryColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please Re-Enter your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // 🔓 Continue Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    theme.primaryColor, // Match LoginScreen
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  String email = _emailController.text.trim();
                                  String password =
                                      _passwordController.text.trim();
                                  bool result = await _authService.signUp(
                                    email: email,
                                    password: password,
                                    context: context,
                                  );
                                  if (result) {
                                    _emailController.clear();
                                    _passwordController.clear();
                                    _confirmPasswordController.clear();
                                  }
                                }
                              },
                              child: const Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white, // Match LoginScreen
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12), // Match LoginScreen
                          // 🆕 Sign In Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: theme.primaryColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pushNamed(context, '/login');
                              },
                              child: Text(
                                'Already have an account? SIGN IN',
                                style: TextStyle(color: theme.primaryColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(theme.primaryColor),
                ),
                icon: Icon(Icons.arrow_back, color: Colors.white, size: 35),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/auth');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
