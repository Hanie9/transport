import 'package:flutter/material.dart';

import '../shared/profile_screen.dart';

/// Redirects legacy vehicle route to profile with edit mode.
class VehicleProfileScreen extends StatelessWidget {
  const VehicleProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen(role: 'driver', editVehicleInitially: true);
  }
}
