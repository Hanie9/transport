import 'package:flutter/material.dart';
import 'package:legestic/utils/route_map_geometry.dart';

/// Route-line colours from live vs free-flow congestion:
/// آبی = روان، نارنجی = نیمه‌سنگین، قرمز = سنگین.
abstract final class NeshanRouteStyle {
  /// روان / خلوت (`#250ECD`).
  static const Color routeLine = Color(0xFF250ECD);

  static const int routeLineArgb = 0xFF250ECD;

  /// نیمه‌سنگین (نارنجی).
  static const Color trafficModerate = Color(0xFFF8830B);

  /// سنگین (قرمز).
  static const Color trafficHeavy = Color(0xFFFF0C00);

  static const int trafficModerateArgb = 0xFFF8830B;
  static const int trafficHeavyArgb = 0xFFFF0C00;

  /// Kept for API compatibility — treated as روان (blue).
  static const Color trafficSmooth = routeLine;
  static const int trafficSmoothArgb = routeLineArgb;

  static const Color routeCasing = Color(0xFFFFFFFF);
  static const int routeCasingArgb = 0xFFFFFFFF;

  static const Color routeLineTranslucent = Color(0xCC250ECD);

  static Color colorForTrafficLevel(RouteTrafficLevel level) {
    switch (level) {
      case RouteTrafficLevel.heavy:
        return trafficHeavy;
      case RouteTrafficLevel.moderate:
        return trafficModerate;
      case RouteTrafficLevel.smooth:
      case RouteTrafficLevel.clear:
        return routeLine;
    }
  }

  static int argbForTrafficLevel(RouteTrafficLevel level) {
    switch (level) {
      case RouteTrafficLevel.heavy:
        return trafficHeavyArgb;
      case RouteTrafficLevel.moderate:
        return trafficModerateArgb;
      case RouteTrafficLevel.smooth:
      case RouteTrafficLevel.clear:
        return routeLineArgb;
    }
  }

  static double overviewLineWidth = 9;
  static double navigationLineWidth = 12;
  static double traveledLineWidth = 7;
}
