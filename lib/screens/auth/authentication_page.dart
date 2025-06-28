import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:test_project/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:test_project/utils/message_type.dart';
import 'package:test_project/utils/responsive_extension.dart';
import 'package:test_project/utils/responsive_widget.dart';
import 'package:test_project/widgets/app_message_notifier.dart';
import 'package:test_project/utils/responsive_helper.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({super.key});

  @override
  AuthenticationPageState createState() => AuthenticationPageState();
}

class AuthenticationPageState extends State<AuthenticationPage> {
  final PageController _pageController = PageController();
  final _authService = AuthService();
  int _currentPage = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _autoSlide();
    });
  }

  void _autoSlide() async {
    while (true) {
      await Future.delayed(const Duration(seconds: 4));
      if (mounted) {
        setState(() {
          _currentPage = (_currentPage + 1) % 4;
        });
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final Color primaryColor = const Color(0xFF0A2D7B);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: ResponsiveBuilder(
              builder: (context, constraints, deviceType) {
                return _buildResponsiveLayout(
                  context,
                  size,
                  primaryColor,
                  deviceType,
                );
              },
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: SpinKitDoubleBounce(
                  color: const Color(0xFF0A2D7B),
                  size: ResponsiveHelper.getValue(
                    context,
                    mobile: 40.0,
                    tablet: 50.0,
                    desktop: 60.0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResponsiveLayout(
    BuildContext context,
    Size size,
    Color primaryColor,
    DeviceType deviceType,
  ) {
    switch (deviceType) {
      case DeviceType.desktop:
        return _buildDesktopLayout(context, size, primaryColor);
      case DeviceType.tablet:
        return _buildTabletLayout(context, size, primaryColor);
      // case DeviceType.mobile:
      default:
        return _buildMobileLayout(context, size, primaryColor);
    }
  }

  // Mobile Layout (Original)
  Widget _buildMobileLayout(
    BuildContext context,
    Size size,
    Color primaryColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: context.largeSpacing),
        _buildImageSlider(context, size),
        _buildPageIndicators(context, primaryColor),
        SizedBox(height: context.mediumSpacing),
        _buildTextSection(context, primaryColor),
        const Spacer(),
        _buildButtonsSection(context, size, primaryColor),
        SizedBox(height: context.largeSpacing),
      ],
    );
  }

  // Tablet Layout
  Widget _buildTabletLayout(
    BuildContext context,
    Size size,
    Color primaryColor,
  ) {
    return Padding(
      padding: context.horizontalPadding,
      child: Row(
        children: [
          // Left side - Image slider
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildImageSlider(context, size),
                SizedBox(height: context.smallSpacing),
                _buildPageIndicators(context, primaryColor),
              ],
            ),
          ),
          SizedBox(width: context.largeSpacing),
          // Right side - Content
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextSection(context, primaryColor),
                SizedBox(height: context.largeSpacing),
                _buildButtonsSection(context, size, primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Desktop Layout
  Widget _buildDesktopLayout(
    BuildContext context,
    Size size,
    Color primaryColor,
  ) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        padding: context.allPadding,
        child: Row(
          children: [
            // Left side - Image slider (larger)
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildImageSlider(context, size),
                  SizedBox(height: context.mediumSpacing),
                  _buildPageIndicators(context, primaryColor),
                ],
              ),
            ),
            SizedBox(width: context.largeSpacing * 2),
            // Right side - Content (smaller)
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextSection(context, primaryColor),
                  SizedBox(height: context.largeSpacing),
                  _buildButtonsSection(context, size, primaryColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSlider(BuildContext context, Size size) {
    final sliderHeight = ResponsiveHelper.getValue(
      context,
      mobile: size.height * 0.45,
      tablet: size.height * 0.5,
      desktop: size.height * 0.6,
    );

    return SizedBox(
      height: sliderHeight,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: 4,
        itemBuilder: (context, index) {
          return Image.asset(
            'assets/images/slider_${index + 1}.png',
            fit: BoxFit.contain,
            height: sliderHeight,
            width: size.width,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[100],
                child: const Icon(Icons.error),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPageIndicators(BuildContext context, Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        bool isActive = _currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          margin: EdgeInsets.symmetric(horizontal: context.smallSpacing / 2),
          width: isActive ? 12.0 : 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            color: isActive ? primaryColor : Colors.grey,
            borderRadius: BorderRadius.circular(4.0),
          ),
        );
      }),
    );
  }

  Widget _buildTextSection(BuildContext context, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Train with the Best',
          style: context.responsiveHeadlineLarge.copyWith(color: primaryColor),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: context.smallSpacing),
        Text(
          "Your body can stand almost anything—it's your mind you have to convince.",
          style: context.responsiveBodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildButtonsSection(
    BuildContext context,
    Size size,
    Color primaryColor,
  ) {
    final buttonWidth = ResponsiveHelper.getValue(
      context,
      mobile: size.width * 0.8,
      tablet: double.infinity,
      desktop: double.infinity,
    );

    return Column(
      children: [
        _buildButton(
          context,
          'Login',
          () => Navigator.pushNamed(context, '/login'),
          primaryColor,
          buttonWidth,
        ),
        SizedBox(height: context.smallSpacing),
        _buildButton(
          context,
          'Sign Up',
          () => Navigator.pushNamed(context, '/signUp'),
          primaryColor,
          buttonWidth,
        ),
        SizedBox(height: context.smallSpacing),
        _buildGoogleButton(context, buttonWidth),
        SizedBox(height: context.mediumSpacing),
        _buildTermsText(context),
      ],
    );
  }

  Widget _buildButton(
    BuildContext context,
    String text,
    VoidCallback onPressed,
    Color color,
    double width,
  ) {
    return SizedBox(
      width: width,
      height: ResponsiveHelper.getValue(
        context,
        mobile: 50.0,
        tablet: 55.0,
        desktop: 60.0,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 4,
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            fontSize: ResponsiveHelper.getFontSize(context, mobile: 16.0),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton(BuildContext context, double width) {
    return SizedBox(
      width: width,
      height: ResponsiveHelper.getValue(
        context,
        mobile: 50.0,
        tablet: 55.0,
        desktop: 60.0,
      ),
      child: OutlinedButton.icon(
        icon: Image.asset(
          'assets/images/google_icon.jpg',
          height: ResponsiveHelper.getValue(
            context,
            mobile: 24.0,
            tablet: 26.0,
            desktop: 28.0,
          ),
        ),
        label: Text(
          "Continue with Google",
          style: TextStyle(
            fontSize: ResponsiveHelper.getFontSize(context, mobile: 16.0),
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black87,
          side: BorderSide(color: Colors.grey.shade400),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed:
            _isLoading
                ? null
                : () async {
                  setState(() {
                    _isLoading = true;
                  });

                  try {
                    await _authService.signInWithGoogle(context: context);
                  } catch (e) {
                    if (mounted) {
                      AppNotifier.show(
                        context,
                        'Google sign-in failed. Please try again.',
                        type: MessageType.error,
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                },
      ),
    );
  }

  Widget _buildTermsText(BuildContext context) {
    return Text(
      'By continuing you agree to Christos Poulis\'s\nTerms of Services & Privacy Policy',
      style: context.responsiveBodyMedium.copyWith(color: Colors.grey[700]),
      textAlign: TextAlign.center,
    );
  }
}
