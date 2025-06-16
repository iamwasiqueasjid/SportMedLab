import 'package:flutter/material.dart';
import 'package:test_project/utils/responsive_helper.dart';

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    BoxConstraints constraints,
    DeviceType deviceType,
  )
  builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        DeviceType deviceType;

        if (constraints.maxWidth >= ResponsiveHelper.tabletBreakpoint) {
          deviceType = DeviceType.desktop;
        } else if (constraints.maxWidth >= ResponsiveHelper.mobileBreakpoint) {
          deviceType = DeviceType.tablet;
        } else {
          deviceType = DeviceType.mobile;
        }

        return builder(context, constraints, deviceType);
      },
    );
  }
}

enum DeviceType { mobile, tablet, desktop }
