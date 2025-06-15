import 'package:flutter/material.dart';

class ResponsiveHelper {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  static bool isPortrait(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.portrait;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  // Get responsive value based on screen size
  static T getValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    } else if (isTablet(context) && tablet != null) {
      return tablet;
    } else {
      return mobile;
    }
  }

  // Get columns count for grid
  static int getColumnsCount(BuildContext context) =>
      isDesktop(context) ? 2 : 1;

  // Get padding based on screen size
  static EdgeInsets getPadding(BuildContext context) => getValue(
    context,
    mobile: const EdgeInsets.only(left: 16.0, right: 16.0),
    tablet: const EdgeInsets.only(left: 24.0, right: 24),
    desktop: const EdgeInsets.only(left: 32.0, right: 32),
  );

  // Get responsive font size
  static double getFontSize(
    BuildContext context, {
    required double mobile,
    double tablet = 0,
    double desktop = 0,
  }) {
    final contextValue = mobile;
    tablet = tablet == 0 ? mobile * 1.1 : tablet;
    desktop = desktop == 0 ? mobile * 1.2 : desktop;

    return getValue(
      context,
      mobile: contextValue,
      tablet: tablet,
      desktop: desktop,
    );
  }
}

// Enum for device types
enum DeviceType { mobile, tablet, desktop }
