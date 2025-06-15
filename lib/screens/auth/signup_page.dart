import 'package:flutter/material.dart';
import 'package:test_project/services/auth/auth_service.dart';
import 'package:test_project/utils/responsive_extension.dart';
import 'package:test_project/utils/responsive_helper.dart';
import 'package:test_project/utils/responsive_widget.dart';

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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
            ResponsiveBuilder(
              builder: (context, constraints, deviceType) {
                return _buildResponsiveLayout(context, theme, deviceType);
              },
            ),
            Positioned(
              top: context.smallSpacing,
              left: context.smallSpacing,
              child: IconButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(theme.primaryColor),
                ),
                icon: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: ResponsiveHelper.getValue(
                    context,
                    mobile: 30.0,
                    tablet: 35.0,
                    desktop: 40.0,
                  ),
                ),
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

  Widget _buildResponsiveLayout(
    BuildContext context,
    ThemeData theme,
    DeviceType deviceType,
  ) {
    switch (deviceType) {
      case DeviceType.desktop:
        return _buildDesktopLayout(context, theme);
      case DeviceType.tablet:
        return _buildTabletLayout(context, theme);
      case DeviceType.mobile:
        return _buildMobileLayout(context, theme);
    }
  }

  Widget _buildMobileLayout(BuildContext context, ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        padding: context.allPadding,
        child: Card(
          elevation: 4,
          color: Colors.white,
          shadowColor: theme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.mediumSpacing),
          ),
          child: Padding(
            padding: context.allPadding,
            child: _buildFormContent(context, theme),
          ),
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, ThemeData theme) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: context.horizontalPadding,
        child: Card(
          elevation: 6,
          color: Colors.white,
          shadowColor: theme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.mediumSpacing),
          ),
          child: Padding(
            padding: context.allPadding.copyWith(
              top: context.mediumSpacing,
              bottom: context.mediumSpacing,
            ),
            child: _buildFormContent(context, theme),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, ThemeData theme) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        padding: context.horizontalPadding,
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Center(
                child: Image.asset(
                  'assets/icons/Splash_Logo.png',
                  width: ResponsiveHelper.getValue(
                    context,
                    mobile: 150.0,
                    tablet: 180.0,
                    desktop: 200.0,
                  ),
                  height: ResponsiveHelper.getValue(
                    context,
                    mobile: 40.0,
                    tablet: 48.0,
                    desktop: 56.0,
                  ),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(width: context.largeSpacing),
            Expanded(
              flex: 2,
              child: Card(
                elevation: 8,
                color: Colors.white,
                shadowColor: theme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.mediumSpacing),
                ),
                child: Padding(
                  padding: context.allPadding.copyWith(
                    top: context.largeSpacing,
                    bottom: context.largeSpacing,
                  ),
                  child: _buildFormContent(context, theme),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormContent(BuildContext context, ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🖼️ App Logo (not shown in desktop since it's outside the card)
          if (ResponsiveHelper.isMobile(context) ||
              ResponsiveHelper.isTablet(context))
            Center(
              child: Image.asset(
                'assets/icons/Splash_Logo.png',
                width: ResponsiveHelper.getValue(
                  context,
                  mobile: 150.0,
                  tablet: 180.0,
                  desktop: 200.0,
                ),
                height: ResponsiveHelper.getValue(
                  context,
                  mobile: 40.0,
                  tablet: 48.0,
                  desktop: 56.0,
                ),
                fit: BoxFit.contain,
              ),
            ),
          if (ResponsiveHelper.isMobile(context) ||
              ResponsiveHelper.isTablet(context))
            SizedBox(height: context.mediumSpacing),
          // 👋 Welcome Text and Subtitle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Get On Board!",
                style: context.responsiveHeadlineLarge.copyWith(
                  color: theme.primaryColor,
                ),
              ),
              SizedBox(height: context.smallSpacing),
              Text(
                "Create your profile to start your Journey.",
                style: context.responsiveBodyLarge,
              ),
            ],
          ),
          SizedBox(height: context.largeSpacing),
          // 📧 Email Field
          TextFormField(
            controller: _emailController,
            style: context.responsiveBodyLarge.copyWith(
              color: theme.primaryColor,
            ),
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(
                Icons.email,
                color: theme.primaryColor,
                size: ResponsiveHelper.getValue(
                  context,
                  mobile: 24.0,
                  tablet: 26.0,
                  desktop: 28.0,
                ),
              ),
              hintText: 'Enter your email',
              hintStyle: context.responsiveBodyMedium.copyWith(
                color: theme.primaryColor,
              ),
              labelStyle: context.responsiveBodyMedium.copyWith(
                color: theme.primaryColor,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.smallSpacing),
                borderSide: BorderSide(color: theme.primaryColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.smallSpacing),
                borderSide: BorderSide(color: theme.primaryColor, width: 2),
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
          SizedBox(height: context.mediumSpacing),
          // 🔒 Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: context.responsiveBodyLarge.copyWith(
              color: theme.primaryColor,
            ),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(
                Icons.lock,
                color: theme.primaryColor,
                size: ResponsiveHelper.getValue(
                  context,
                  mobile: 24.0,
                  tablet: 26.0,
                  desktop: 28.0,
                ),
              ),
              hintText: 'Enter your password',
              hintStyle: context.responsiveBodyMedium.copyWith(
                color: theme.primaryColor,
              ),
              labelStyle: context.responsiveBodyMedium.copyWith(
                color: theme.primaryColor,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.smallSpacing),
                borderSide: BorderSide(color: theme.primaryColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.smallSpacing),
                borderSide: BorderSide(color: theme.primaryColor, width: 2),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: theme.primaryColor,
                  size: ResponsiveHelper.getValue(
                    context,
                    mobile: 24.0,
                    tablet: 26.0,
                    desktop: 28.0,
                  ),
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
          SizedBox(height: context.mediumSpacing),
          // 🔒 Confirm Password Field
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            style: context.responsiveBodyLarge.copyWith(
              color: theme.primaryColor,
            ),
            decoration: InputDecoration(
              labelText: 'Re-Enter Password',
              prefixIcon: Icon(
                Icons.lock,
                color: theme.primaryColor,
                size: ResponsiveHelper.getValue(
                  context,
                  mobile: 24.0,
                  tablet: 26.0,
                  desktop: 28.0,
                ),
              ),
              hintText: 'Re-Enter your Password',
              hintStyle: context.responsiveBodyMedium.copyWith(
                color: theme.primaryColor,
              ),
              labelStyle: context.responsiveBodyMedium.copyWith(
                color: theme.primaryColor,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.smallSpacing),
                borderSide: BorderSide(color: theme.primaryColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.smallSpacing),
                borderSide: BorderSide(color: theme.primaryColor, width: 2),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: theme.primaryColor,
                  size: ResponsiveHelper.getValue(
                    context,
                    mobile: 24.0,
                    tablet: 26.0,
                    desktop: 28.0,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
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
          SizedBox(height: context.mediumSpacing),
          // 🔓 Continue Button
          SizedBox(
            width: double.infinity,
            height: ResponsiveHelper.getValue(
              context,
              mobile: 50.0,
              tablet: 55.0,
              desktop: 60.0,
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.smallSpacing),
                ),
              ),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  String email = _emailController.text.trim();
                  String password = _passwordController.text.trim();
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
              child: Text(
                'Continue',
                style: context.responsiveTitleLarge.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: context.smallSpacing),
          // 🆕 Sign In Button
          SizedBox(
            width: double.infinity,
            height: ResponsiveHelper.getValue(
              context,
              mobile: 50.0,
              tablet: 55.0,
              desktop: 60.0,
            ),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.smallSpacing),
                ),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child: Text(
                'Already have an account? SIGN IN',
                style: context.responsiveBodyLarge.copyWith(
                  color: theme.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
