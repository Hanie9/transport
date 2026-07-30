import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Redirects legacy nearby route to the merged cargos page.
class NearbyCargoScreen extends StatelessWidget {
  const NearbyCargoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.go('/driver/cargos');
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
