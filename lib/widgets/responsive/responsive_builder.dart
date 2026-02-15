import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// Responsive layout builder for different screen sizes
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;
  
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppConstants.mobileBreakpoint) {
          return mobile;
        } else if (constraints.maxWidth < AppConstants.tabletBreakpoint) {
          return tablet ?? mobile;
        } else {
          return desktop;
        }
      },
    );
  }
}

/// Helper class for responsive values
class Responsive {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < AppConstants.mobileBreakpoint;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= AppConstants.mobileBreakpoint && 
           width < AppConstants.tabletBreakpoint;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= AppConstants.tabletBreakpoint;
  }
  
  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < AppConstants.mobileBreakpoint) {
      return AppConstants.mobileColumns;
    } else if (width < AppConstants.desktopBreakpoint) {
      return AppConstants.tabletColumns;
    } else {
      return AppConstants.desktopColumns;
    }
  }
  
  static double getHorizontalPadding(BuildContext context) {
    if (isMobile(context)) {
      return 16.0;
    } else if (isTablet(context)) {
      return 24.0;
    } else {
      return 32.0;
    }
  }
}
