import 'package:flutter/material.dart';
import 'package:test_project/services/databaseHandler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  bool _rememberMe = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔙 Back Arrow
                IconButton(
                  icon: Icon(Icons.arrow_back, color: theme.primaryColor),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 10),

                // 👋 Welcome Text
                Row(
                  children: [
                    Text(
                      "Welcome back,",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Discover Limitless Choices and Unmatched Convenience.",
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 32),

                // 📧 Email Field
                TextFormField(
                  controller: _emailController,
                  style: TextStyle(color: theme.primaryColor), // Fix text color
                  decoration: InputDecoration(
                    labelText: 'Your Email',
                    hintText: 'Enter your email',
                    hintStyle: TextStyle(color: theme.primaryColor),
                    labelStyle: TextStyle(color: theme.primaryColor),
                    filled: true,
                    fillColor: Colors.grey[100],
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.primaryColor),
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
                    if (value?.isEmpty ?? true)
                      return 'Please enter your email';
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
                  style: TextStyle(color: theme.primaryColor), // Fix text color
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    hintStyle: TextStyle(color: theme.primaryColor),
                    labelStyle: TextStyle(color: theme.primaryColor),
                    filled: true,
                    fillColor: Colors.grey[100],
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.primaryColor),
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
                    if (value?.isEmpty ?? true)
                      return 'Please enter your password';
                    if (value!.length < 6)
                      return 'Password must be at least 6 characters';
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
                              (value) => setState(() => _rememberMe = value!),
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
                        // Forgot password logic
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(color: theme.primaryColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

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
                        bool result = await _databaseService.login(
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
                      style: TextStyle(fontSize: 16, color: Colors.white),
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
                      'Create Account',
                      style: TextStyle(color: theme.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(height: 1, width: 50, color: Colors.grey[400]),
                    const SizedBox(width: 8),
                    const Text("Or", style: TextStyle(color: Colors.black54)),
                    const SizedBox(width: 8),
                    Container(height: 1, width: 50, color: Colors.grey[400]),
                  ],
                ),
                const SizedBox(height: 16),

                // ✅ Google Sign-In Button Styled
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    icon: Image.asset(
                      'assets/images/google_icon.jpg',
                      height: 24,
                    ), // make sure the asset exists
                    label: Text("Sign in with Google"),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
