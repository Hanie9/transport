import 'package:go_router/go_router.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/coordinator/active_drivers_screen.dart';
import '../features/coordinator/add_cargo_screen.dart';
import '../features/coordinator/cargo_detail_screen.dart' as coordinator;
import '../features/coordinator/coordinator_home_screen.dart';
import '../features/coordinator/nearby_drivers_screen.dart';
import '../features/driver/cargo_detail_screen.dart';
import '../features/driver/driver_missions_screen.dart';
import '../features/driver/driver_home_screen.dart';
import '../features/driver/nearby_cargo_screen.dart';
import '../features/driver/route_screen.dart';
import '../features/driver/vehicle_profile_screen.dart';
import '../features/shared/home_screen.dart';
import '../features/shared/profile_screen.dart';
import '../features/shared/menu/about_screen.dart';
import '../features/shared/menu/change_password_screen.dart';
import '../features/shared/menu/help_screen.dart';
import '../features/shared/menu/settings_screen.dart';
import '../features/shared/menu/support_screen.dart';
import '../features/splash/splash_screen.dart';
import '../services/auth_service.dart';

class AppRouter {
  static GoRouter create(AuthService authService) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: authService,
      redirect: (context, state) {
        final isAuth = authService.isAuthenticated;
        final path = state.matchedLocation;
        final isAuthRoute = path == '/login' || path == '/signup';
        final isSplash = path == '/';

        if (isSplash) return null;
        if (!isAuth && !isAuthRoute) return '/login';
        if (isAuth && isAuthRoute) {
          final role = authService.currentUser?.role;
          return role?.name == 'driver' ? '/driver' : '/coordinator';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
        ShellRoute(
          builder: (_, __, child) => DriverShell(child: child),
          routes: [
            GoRoute(
              path: '/driver',
              builder: (_, __) => const HomeScreen(role: 'driver'),
            ),
            GoRoute(
              path: '/driver/cargos',
              builder: (_, __) => const DriverHomeScreen(),
            ),
            GoRoute(path: '/driver/missions', builder: (_, __) => const DriverMissionsScreen()),
            GoRoute(path: '/driver/nearby', builder: (_, __) => const NearbyCargoScreen()),
            GoRoute(
              path: '/driver/profile',
              builder: (_, state) => ProfileScreen(
                role: 'driver',
                editVehicleInitially: state.uri.queryParameters['editVehicle'] == '1',
              ),
            ),
            GoRoute(
              path: '/driver/vehicle',
              builder: (_, __) => const VehicleProfileScreen(),
            ),
            GoRoute(path: '/driver/settings', builder: (_, __) => const SettingsScreen()),
            GoRoute(path: '/driver/about', builder: (_, __) => const AboutScreen()),
            GoRoute(path: '/driver/help', builder: (_, __) => const HelpScreen(role: 'driver')),
            GoRoute(path: '/driver/support', builder: (_, __) => const SupportScreen()),
            GoRoute(path: '/driver/change-password', builder: (_, __) => const ChangePasswordScreen()),
          ],
        ),
        GoRoute(
          path: '/driver/cargo/:id',
          builder: (_, state) => CargoDetailScreen(
            cargoId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/driver/route/:id',
          builder: (_, state) => RouteScreen(
            cargoId: state.pathParameters['id']!,
          ),
        ),
        ShellRoute(
          builder: (_, __, child) => CoordinatorShell(child: child),
          routes: [
            GoRoute(
              path: '/coordinator',
              builder: (_, __) => const HomeScreen(role: 'coordinator'),
            ),
            GoRoute(
              path: '/coordinator/cargos',
              builder: (_, __) => const CoordinatorHomeScreen(),
            ),
            GoRoute(
              path: '/coordinator/drivers',
              builder: (_, __) => const ActiveDriversScreen(),
            ),
            GoRoute(
              path: '/coordinator/nearby-drivers',
              builder: (_, __) => const NearbyDriversScreen(),
            ),
            GoRoute(
              path: '/coordinator/profile',
              builder: (_, __) => const ProfileScreen(role: 'coordinator'),
            ),
            GoRoute(path: '/coordinator/settings', builder: (_, __) => const SettingsScreen()),
            GoRoute(path: '/coordinator/about', builder: (_, __) => const AboutScreen()),
            GoRoute(path: '/coordinator/help', builder: (_, __) => const HelpScreen(role: 'coordinator')),
            GoRoute(path: '/coordinator/support', builder: (_, __) => const SupportScreen()),
            GoRoute(path: '/coordinator/change-password', builder: (_, __) => const ChangePasswordScreen()),
          ],
        ),
        GoRoute(
          path: '/coordinator/add-cargo',
          builder: (_, __) => const AddCargoScreen(),
        ),
        GoRoute(
          path: '/coordinator/cargo/:id',
          builder: (_, state) => coordinator.CoordinatorCargoDetailScreen(
            cargoId: state.pathParameters['id']!,
          ),
        ),
      ],
    );
  }
}
