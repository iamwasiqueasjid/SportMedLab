import 'package:flutter/material.dart';
import 'package:test_project/services/databaseHandler.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: theme.primaryColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    'Sign Up',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Using example@gmail.com to Sign Up',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    style: theme.textTheme.bodyLarge,
                    decoration: _inputDecoration(
                      theme,
                      'Your Email',
                      'Enter your email',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: theme.textTheme.bodyLarge,
                    decoration: _inputDecoration(
                      theme,
                      'Your Password',
                      'Enter your password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: theme.iconTheme.color,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    style: theme.textTheme.bodyLarge,
                    decoration: _inputDecoration(
                      theme,
                      'Re-enter Password',
                      'Re-enter your password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: theme.iconTheme.color,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          String email = _emailController.text.trim();
                          String password = _passwordController.text.trim();
                          String confirmPassword =
                              _confirmPasswordController.text.trim();

                          if (email.isEmpty ||
                              password.isEmpty ||
                              confirmPassword.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please fill all fields"),
                              ),
                            );
                            return;
                          }

                          if (password != confirmPassword) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Password does not match"),
                              ),
                            );
                            return;
                          }

                          bool result = await _databaseService.signUp(
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
                      child: Text(
                        'Continue',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Or Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade400)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text("Or"),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade400)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Google Sign-Up Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      icon: Image.asset(
                        'assets/images/google_icon.jpg',
                        height: 24,
                      ), // make sure the asset exists
                      label: Text("Sign Up with Google"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        // Google sign-up logic here
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Already have account
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account?",
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed:
                            () => Navigator.pushReplacementNamed(
                              context,
                              '/login',
                            ),
                        child: Text(
                          "Login",
                          style: TextStyle(color: theme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    ThemeData theme,
    String label,
    String hint, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: theme.primaryColor),
      labelStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.primaryColor,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.primaryColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.primaryColor),
      ),
      suffixIcon: suffixIcon,
    );
  }
}
