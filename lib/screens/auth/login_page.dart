import 'package:flutter/material.dart';
import 'package:test_project/services/auth_service.dart';
import 'package:test_project/utils/message_type.dart';
import 'package:test_project/widgets/app_message_notifier.dart';
// import 'package:test_project/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(theme.primaryColor),
                ),
                icon: Icon(Icons.arrow_back, color: Colors.white, size: 35),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 👋 Welcome Text
                          Text(
                            "Welcome Back,",
                            style: TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                          Text(
                            "Make it work, make it fast, make it right.",
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                          ),

                          const SizedBox(height: 30),
                          // 📧 Email Field
                          TextFormField(
                            controller: _emailController,
                            style: TextStyle(
                              color: theme.primaryColor,
                            ), // Fix text color
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
                            style: TextStyle(
                              color: theme.primaryColor,
                            ), // Fix text color
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
                          const SizedBox(height: 12),

                          // 🔁 Remember Me & Forgot Password
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    onChanged:
                                        (value) => setState(
                                          () => _rememberMe = value!,
                                        ),
                                    activeColor: theme.primaryColor,
                                  ),
                                  const Text(
                                    'Remember Me',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  if (_emailController.text.trim().isEmpty) {
                                    AppNotifier.show(
                                      context,
                                      'Please enter your Email first...',
                                      type: MessageType.warning,
                                    );
                                    return;
                                  }
                                  _authService.resetPassword(
                                    email: _emailController.text,
                                    context: context,
                                  );
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(color: theme.primaryColor),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 🔓 Sign In Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  bool result = await _authService.login(
                                    email: _emailController.text.trim(),
                                    password: _passwordController.text.trim(),
                                    context: context,
                                  );
                                  if (result) {
                                    _emailController.clear();
                                    _passwordController.clear();
                                  }
                                }
                              },
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 🆕 Create Account Button
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
                                Navigator.pushNamed(context, '/signUp');
                              },
                              child: Text(
                                'Don\'t have an account? SIGN UP',
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
          ],
        ),
      ),
    );
  }
}
