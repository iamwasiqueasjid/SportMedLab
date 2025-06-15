import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:test_project/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:test_project/utils/message_type.dart';
import 'package:test_project/widgets/app_message_notifier.dart';
import 'package:test_project/utils/responsive_helper.dart'; // Ensure this is imported

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
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              // Wrap Column in SingleChildScrollView
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: ResponsiveHelper.getValue(
                        context,
                        mobile: 35.0,
                        tablet: 50.0,
                        desktop: 70.0,
                      ),
                    ),

                    // Slider (Responsive height and width)
                    SizedBox(
                      height: ResponsiveHelper.getValue(
                        context,
                        mobile: MediaQuery.of(context).size.height * 0.45,
                        tablet: MediaQuery.of(context).size.height * 0.5,
                        desktop: MediaQuery.of(context).size.height * 0.6,
                      ),
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
                            height: ResponsiveHelper.getValue(
                              context,
                              mobile: MediaQuery.of(context).size.height * 0.5,
                              tablet: MediaQuery.of(context).size.height * 0.6,
                              desktop: MediaQuery.of(context).size.height * 0.7,
                            ),
                            width: MediaQuery.of(context).size.width,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[100],
                                child: const Icon(Icons.error),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    // Page Indicators (Responsive spacing)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        bool isActive = _currentPage == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          margin: EdgeInsets.symmetric(
                            horizontal: ResponsiveHelper.getValue(
                              context,
                              mobile: 4.0,
                              tablet: 6.0,
                              desktop: 8.0,
                            ),
                          ),
                          width: ResponsiveHelper.getValue(
                            context,
                            mobile: 12.0,
                            tablet: 14.0,
                            desktop: 16.0,
                          ),
                          height: ResponsiveHelper.getValue(
                            context,
                            mobile: 8.0,
                            tablet: 10.0,
                            desktop: 12.0,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isActive
                                    ? const Color(0xFF0A2D7B)
                                    : Colors.grey,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        );
                      }),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getValue(
                        context,
                        mobile: 30.0,
                        tablet: 40.0,
                        desktop: 50.0,
                      ),
                    ),

                    // Text Section (Responsive padding and font sizes)
                    Padding(
                      padding: ResponsiveHelper.getPadding(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Train with the Best',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getFontSize(
                                context,
                                mobile: 24.0,
                                tablet: 28.0,
                                desktop: 32.0,
                              ),
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0A2D7B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(
                            height: ResponsiveHelper.getValue(
                              context,
                              mobile: 8.0,
                              tablet: 10.0,
                              desktop: 12.0,
                            ),
                          ),
                          Text(
                            'Your body can stand almost anything—it’s your mind you have to convince.',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getFontSize(
                                context,
                                mobile: 16.0,
                                tablet: 18.0,
                                desktop: 20.0,
                              ),
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Buttons Section (Responsive padding and sizing)
                    Padding(
                      padding: ResponsiveHelper.getPadding(context),
                      child: Column(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A2D7B),
                              minimumSize: Size(
                                ResponsiveHelper.getValue(
                                  context,
                                  mobile:
                                      MediaQuery.of(context).size.width * 0.8,
                                  tablet:
                                      MediaQuery.of(context).size.width * 0.7,
                                  desktop:
                                      MediaQuery.of(context).size.width * 0.5,
                                ),
                                50,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              elevation: 4,
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: ResponsiveHelper.getValue(
                              context,
                              mobile: 10.0,
                              tablet: 15.0,
                              desktop: 20.0,
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A2D7B),
                              minimumSize: Size(
                                ResponsiveHelper.getValue(
                                  context,
                                  mobile:
                                      MediaQuery.of(context).size.width * 0.8,
                                  tablet:
                                      MediaQuery.of(context).size.width * 0.7,
                                  desktop:
                                      MediaQuery.of(context).size.width * 0.5,
                                ),
                                50,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              elevation: 4,
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, '/signUp');
                            },
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: ResponsiveHelper.getValue(
                              context,
                              mobile: 10.0,
                              tablet: 15.0,
                              desktop: 20.0,
                            ),
                          ),

                          // Google Sign-In Button
                          SizedBox(
                            width: ResponsiveHelper.getValue(
                              context,
                              mobile: MediaQuery.of(context).size.width * 0.8,
                              tablet: MediaQuery.of(context).size.width * 0.7,
                              desktop: MediaQuery.of(context).size.width * 0.5,
                            ),
                            height: 50,
                            child: OutlinedButton.icon(
                              icon: Image.asset(
                                'assets/images/google_icon.jpg',
                                height: 24,
                              ),
                              label: Text("Continue with Google"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black87,
                                side: BorderSide(color: Colors.grey.shade400),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                minimumSize: Size(
                                  ResponsiveHelper.getValue(
                                    context,
                                    mobile:
                                        MediaQuery.of(context).size.width * 0.8,
                                    tablet:
                                        MediaQuery.of(context).size.width * 0.7,
                                    desktop:
                                        MediaQuery.of(context).size.width * 0.5,
                                  ),
                                  50,
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
                                          await _authService.signInWithGoogle(
                                            context: context,
                                          );
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
                          ),
                          SizedBox(
                            height: ResponsiveHelper.getValue(
                              context,
                              mobile: 25.0,
                              tablet: 30.0,
                              desktop: 40.0,
                            ),
                          ),
                          Text(
                            'By continuing you agree to Christos Poulis\'s\nTerms of Services & Privacy Policy',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getFontSize(
                                context,
                                mobile: 12.0,
                                tablet: 14.0,
                                desktop: 16.0,
                              ),
                              color: Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getValue(
                        context,
                        mobile: 35.0,
                        tablet: 50.0,
                        desktop: 70.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: Center(
                child: SpinKitDoubleBounce(
                  color: const Color(0xFF0A2D7B),
                  size: 40.0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
