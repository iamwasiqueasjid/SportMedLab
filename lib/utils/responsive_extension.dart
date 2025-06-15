import 'package:flutter/material.dart';
import 'responsive_helper.dart';

extension ResponsiveExtension on BuildContext {
  // Text styles with responsive design patterns
  TextStyle get responsiveHeadlineLarge => AppTextStyle.headlineLarge.copyWith(
    fontSize: ResponsiveHelper.getValue(
      this,
      mobile: 26,
      tablet: 30,
      desktop: 36,
    ),
  );

  TextStyle get responsiveHeadlineMedium =>
      AppTextStyle.headlineMedium.copyWith(
        fontSize: ResponsiveHelper.getValue(
          this,
          mobile: 24,
          tablet: 28,
          desktop: 32,
        ),
      );

  TextStyle get responsiveTitleLarge => AppTextStyle.titleLarge.copyWith(
    fontSize: ResponsiveHelper.getValue(
      this,
      mobile: 18,
      tablet: 20,
      desktop: 22,
    ),
  );

  TextStyle get responsiveBodyLarge => AppTextStyle.bodyLarge.copyWith(
    fontSize: ResponsiveHelper.getValue(
      this,
      mobile: 14,
      tablet: 16,
      desktop: 18,
    ),
  );

  TextStyle get responsiveBodyMedium => AppTextStyle.bodyMedium.copyWith(
    fontSize: ResponsiveHelper.getValue(
      this,
      mobile: 12,
      tablet: 14,
      desktop: 16,
    ),
  );

  // Responsive spacing
  double get smallSpacing =>
      ResponsiveHelper.getValue(this, mobile: 8.0, tablet: 12.0, desktop: 16.0);

  double get mediumSpacing => ResponsiveHelper.getValue(
    this,
    mobile: 16.0,
    tablet: 24.0,
    desktop: 32.0,
  );

  double get largeSpacing => ResponsiveHelper.getValue(
    this,
    mobile: 24.0,
    tablet: 32.0,
    desktop: 40.0,
  );

  // Responsive padding
  EdgeInsets get horizontalPadding => EdgeInsets.symmetric(
    horizontal: ResponsiveHelper.getValue(
      this,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    ),
  );

  EdgeInsets get verticalPadding => EdgeInsets.symmetric(
    vertical: ResponsiveHelper.getValue(
      this,
      mobile: 12.0,
      tablet: 16.0,
      desktop: 20.0,
    ),
  );

  EdgeInsets get allPadding => EdgeInsets.all(
    ResponsiveHelper.getValue(this, mobile: 16.0, tablet: 20.0, desktop: 24.0),
  );
}

// App text styles (you can customize these according to your design)
class AppTextStyle {
  static const TextStyle headlineLarge = TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  static const TextStyle titleLarge = TextStyle(
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontWeight: FontWeight.normal,
    color: Colors.black87,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontWeight: FontWeight.normal,
    color: Colors.black54,
  );
}
