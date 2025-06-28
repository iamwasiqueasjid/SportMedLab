import 'package:flutter/material.dart';
import 'package:test_project/utils/responsive_extension.dart';
import 'package:test_project/utils/responsive_helper.dart';
import 'package:test_project/utils/responsive_widget.dart';

class StarterPage extends StatelessWidget {
  const StarterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ResponsiveBuilder(
          builder: (context, constraints, deviceType) {
            return _buildResponsiveLayout(context, deviceType);
          },
        ),
      ),
    );
  }

  Widget _buildResponsiveLayout(BuildContext context, DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.desktop:
        return _buildDesktopLayout(context);
      case DeviceType.tablet:
        return _buildTabletLayout(context);
      // case DeviceType.mobile:
      default:
        return _buildMobileLayout(context);
    }
  }

  // Mobile Layout (Original)
  Widget _buildMobileLayout(BuildContext context) {
    return Padding(
      padding: context.allPadding.copyWith(
        top: context.largeSpacing,
        bottom: context.largeSpacing,
      ),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: context.largeSpacing * 2),
                _buildProfileImage(context, DeviceType.mobile),
                SizedBox(height: context.mediumSpacing),
                _buildTextContent(context, DeviceType.mobile),
              ],
            ),
          ),
          _buildButton(context, DeviceType.mobile),
        ],
      ),
    );
  }

  // Tablet Layout
  Widget _buildTabletLayout(BuildContext context) {
    return Padding(
      padding: context.allPadding.copyWith(
        top: context.largeSpacing,
        bottom: context.largeSpacing,
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Left side - Image
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [_buildProfileImage(context, DeviceType.tablet)],
                  ),
                ),
                SizedBox(width: context.largeSpacing),
                // Right side - Text content
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_buildTextContent(context, DeviceType.tablet)],
                  ),
                ),
              ],
            ),
          ),
          _buildButton(context, DeviceType.tablet),
        ],
      ),
    );
  }

  // Desktop Layout
  Widget _buildDesktopLayout(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        padding: context.allPadding.copyWith(
          top: context.largeSpacing,
          bottom: context.largeSpacing,
        ),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  // Left side - Image (larger)
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildProfileImage(context, DeviceType.desktop),
                      ],
                    ),
                  ),
                  SizedBox(width: context.largeSpacing * 2),
                  // Right side - Text content
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextContent(context, DeviceType.desktop),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Center the button on desktop
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _buildButton(context, DeviceType.desktop),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage(BuildContext context, DeviceType deviceType) {
    final imageSize = ResponsiveHelper.getValue(
      context,
      mobile: const Size(320, 360),
      tablet: const Size(280, 320),
      desktop: const Size(380, 420),
    );

    final borderRadius = ResponsiveHelper.getValue(
      context,
      mobile: 25.0,
      tablet: 22.0,
      desktop: 28.0,
    );

    final borderWidth = ResponsiveHelper.getValue(
      context,
      mobile: 5.0,
      tablet: 4.0,
      desktop: 6.0,
    );

    return Container(
      width: imageSize.width,
      height: imageSize.height,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF0A2D7B), width: borderWidth),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: ResponsiveHelper.getValue(
              context,
              mobile: 12.0,
              tablet: 14.0,
              desktop: 16.0,
            ),
            offset: Offset(
              0,
              ResponsiveHelper.getValue(
                context,
                mobile: 6.0,
                tablet: 7.0,
                desktop: 8.0,
              ),
            ),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - borderWidth),
        child: Image.asset(
          'assets/images/christos.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[100],
              child: Icon(
                Icons.person,
                size: imageSize.width * 0.3,
                color: Colors.grey[400],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextContent(BuildContext context, DeviceType deviceType) {
    final isDesktopOrTablet = deviceType != DeviceType.mobile;

    return Column(
      crossAxisAlignment:
          isDesktopOrTablet
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
      children: [
        Text(
          "Christos Poulis",
          style: TextStyle(
            fontSize: ResponsiveHelper.getFontSize(
              context,
              mobile: 22.0,
              tablet: 24.0,
              desktop: 26.0,
            ),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0A2D7B),
            letterSpacing: 1.2,
          ),
          textAlign: isDesktopOrTablet ? TextAlign.left : TextAlign.center,
        ),
        SizedBox(height: context.smallSpacing),
        Text(
          "Transform Your Body,\nTransform Your Life",
          style: TextStyle(
            fontSize: ResponsiveHelper.getFontSize(
              context,
              mobile: 28.0,
              tablet: 32.0,
              desktop: 36.0,
            ),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            height: 1.3,
          ),
          textAlign: isDesktopOrTablet ? TextAlign.left : TextAlign.center,
        ),
        SizedBox(height: context.smallSpacing),
        Text(
          "Join our fitness community and start building a healthier, stronger version of yourself — one step at a time.",
          style: TextStyle(
            fontSize: ResponsiveHelper.getFontSize(
              context,
              mobile: 16.0,
              tablet: 18.0,
              desktop: 20.0,
            ),
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
            height: 1.4,
          ),
          textAlign: isDesktopOrTablet ? TextAlign.left : TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildButton(BuildContext context, DeviceType deviceType) {
    final buttonHeight = ResponsiveHelper.getValue(
      context,
      mobile: 18.0,
      tablet: 20.0,
      desktop: 22.0,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/auth');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A2D7B),
              padding: EdgeInsets.symmetric(vertical: buttonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getValue(
                    context,
                    mobile: 16.0,
                    tablet: 18.0,
                    desktop: 20.0,
                  ),
                ),
              ),
              elevation: ResponsiveHelper.getValue(
                context,
                mobile: 8.0,
                tablet: 10.0,
                desktop: 12.0,
              ),
            ),
            child: Text(
              "Let's Get Started",
              style: TextStyle(
                fontSize: ResponsiveHelper.getFontSize(
                  context,
                  mobile: 18.0,
                  tablet: 20.0,
                  desktop: 22.0,
                ),
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
        SizedBox(height: context.mediumSpacing),
      ],
    );
  }
}
