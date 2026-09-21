import 'package:latlong2/latlong.dart';
import 'package:legestic/services/neshan_models.dart';
import 'package:legestic/utils/route_map_geometry.dart';
import 'package:legestic/utils/route_progress.dart';

/// Minimum step length before we paint traffic on the route line.
const double kMinTrafficStepMeters = 25;

/// Matched steps must follow roughly the same geometry.
const double kMaxStepDistanceDrift = 0.55;

const double kMaxStepLocationMismatchMeters = 120;

/// Classifies step traffic by comparing live vs typical (or no-traffic) durations.
RouteTrafficLevel trafficLevelForStep(
  NeshanRouteStep live, {
  required NeshanRouteLeg liveLeg,
  NeshanRouteLeg? baselineLeg,
  int? stepIndex,
}) {
  if (live.isArrival || live.durationSeconds <= 0) {
    return RouteTrafficLevel.clear;
  }

  if (baselineLeg == null || baselineLeg.durationSeconds <= 0) {
    return RouteTrafficLevel.clear;
  }

  final baselineDuration = _baselineDurationForStep(
    live,
    liveLeg: liveLeg,
    baselineLeg: baselineLeg,
    stepIndex: stepIndex,
  );
  if (baselineDuration == null || baselineDuration <= 0) {
    return RouteTrafficLevel.clear;
  }

  if (live.distanceMeters > 0 &&
      live.distanceMeters < kMinTrafficStepMeters &&
      baselineDuration >= live.durationSeconds * 0.95) {
    return RouteTrafficLevel.clear;
  }

  return _trafficLevelFromComparison(
    liveSeconds: live.durationSeconds,
    baselineSeconds: baselineDuration,
    liveLeg: liveLeg,
    baselineLeg: baselineLeg,
    distanceMeters: live.distanceMeters,
  );
}

/// Scales step baseline to the live leg so route-wide free-flow optimism does
/// not paint every urban segment red. Result is relative congestion along the
/// route — stable at every map zoom.
double _calibratedBaselineSeconds({
  required double stepBaselineSeconds,
  required NeshanRouteLeg liveLeg,
  required NeshanRouteLeg baselineLeg,
}) {
  if (stepBaselineSeconds <= 0 || baselineLeg.durationSeconds <= 0) {
    return stepBaselineSeconds;
  }
  final legScale = liveLeg.durationSeconds / baselineLeg.durationSeconds;
  if (legScale <= 0) return stepBaselineSeconds;
  return stepBaselineSeconds * legScale;
}

RouteTrafficLevel _trafficLevelFromComparison({
  required double liveSeconds,
  required double baselineSeconds,
  required NeshanRouteLeg liveLeg,
  required NeshanRouteLeg baselineLeg,
  required double distanceMeters,
}) {
  if (baselineSeconds <= 0) return RouteTrafficLevel.clear;

  final calibrated = _calibratedBaselineSeconds(
    stepBaselineSeconds: baselineSeconds,
    liveLeg: liveLeg,
    baselineLeg: baselineLeg,
  );
  if (calibrated <= 0) return RouteTrafficLevel.clear;

  final delay = liveSeconds - calibrated;
  final ratio = liveSeconds / calibrated;

  // Short steps are noisy — high ratios with tiny delays are not "heavy".
  if (distanceMeters > 0 && distanceMeters < kMinTrafficStepMeters) {
    if (delay < 20 && ratio < 1.25) return RouteTrafficLevel.clear;
  }

  // سنگین — only a real jam, not a traffic light or urban slowdown.
  if ((delay >= 75 && ratio >= 1.45) || delay >= 120) {
    return RouteTrafficLevel.heavy;
  }
  // نیمه‌سنگین
  if ((delay >= 35 && ratio >= 1.28) || delay >= 60) {
    return RouteTrafficLevel.moderate;
  }
  // روان
  return RouteTrafficLevel.clear;
}

double? _baselineDurationForStep(
  NeshanRouteStep live, {
  required NeshanRouteLeg liveLeg,
  required NeshanRouteLeg baselineLeg,
  int? stepIndex,
}) {
  final matched = _matchingBaselineStep(
    live,
    liveLeg: liveLeg,
    baselineLeg: baselineLeg,
    stepIndex: stepIndex,
  );
  if (matched != null && matched.durationSeconds > 0) {
    if (live.distanceMeters > 0 && matched.distanceMeters > 0) {
      final drift =
          (matched.distanceMeters - live.distanceMeters).abs() /
          live.distanceMeters;
      if (drift > kMaxStepDistanceDrift) {
        // Wrong geometry pair — do not invent congestion from a distance share.
        return null;
      }
    }
    return matched.durationSeconds;
  }

  return null;
}

/// Picks the baseline step that corresponds to [live].
NeshanRouteStep? _matchingBaselineStep(
  NeshanRouteStep live, {
  required NeshanRouteLeg liveLeg,
  required NeshanRouteLeg baselineLeg,
  int? stepIndex,
}) {
  final sameStepCount = liveLeg.steps.length == baselineLeg.steps.length;

  // Pair by index only when that step is actually the same place.
  // A same-count fallback without coordinates is kept; a far index match
  // is ignored so urban free-flow is not painted red.
  if (stepIndex != null &&
      stepIndex >= 0 &&
      stepIndex < baselineLeg.steps.length) {
    final atIndex = baselineLeg.steps[stepIndex];
    if (!atIndex.isArrival && atIndex.durationSeconds > 0) {
      final liveLoc = live.startLocation;
      final baseLoc = atIndex.startLocation;
      if (liveLoc != null && baseLoc != null) {
        final dist = distanceMeters(
          LatLng(liveLoc.latitude, liveLoc.longitude),
          LatLng(baseLoc.latitude, baseLoc.longitude),
        );
        if (dist <= kMaxStepLocationMismatchMeters) return atIndex;
      } else if (sameStepCount) {
        return atIndex;
      }
    }
  }

  final loc = live.startLocation;
  if (loc != null) {
    final livePoint = LatLng(loc.latitude, loc.longitude);
    NeshanRouteStep? best;
    var bestDist = double.infinity;

    for (final candidate in baselineLeg.steps) {
      if (candidate.isArrival || candidate.startLocation == null) continue;
      final candidatePoint = LatLng(
        candidate.startLocation!.latitude,
        candidate.startLocation!.longitude,
      );
      final dist = distanceMeters(livePoint, candidatePoint);
      if (dist <= kMaxStepLocationMismatchMeters && dist < bestDist) {
        bestDist = dist;
        best = candidate;
      }
    }
    if (best != null) return best;
  }

  return null;
}

RouteTrafficLevel mergeTrafficLevels(
  RouteTrafficLevel a,
  RouteTrafficLevel b,
) {
  if (a == RouteTrafficLevel.heavy || b == RouteTrafficLevel.heavy) {
    return RouteTrafficLevel.heavy;
  }
  if (a == RouteTrafficLevel.moderate || b == RouteTrafficLevel.moderate) {
    return RouteTrafficLevel.moderate;
  }
  if (a == RouteTrafficLevel.smooth || b == RouteTrafficLevel.smooth) {
    return RouteTrafficLevel.smooth;
  }
  return RouteTrafficLevel.clear;
}

bool isStepCongested(
  NeshanRouteStep step, {
  required NeshanRouteLeg liveLeg,
  NeshanRouteLeg? baselineLeg,
  int? stepIndex,
}) =>
    trafficLevelForStep(
      step,
      liveLeg: liveLeg,
      baselineLeg: baselineLeg,
      stepIndex: stepIndex,
    ) ==
    RouteTrafficLevel.heavy;
