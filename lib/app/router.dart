import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/app_page_transitions.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/coordinator/add_cargo_screen.dart';
import '../features/coordinator/cargo_detail_screen.dart' as coordinator;
import '../features/coordinator/coordinator_home_screen.dart';
import '../features/coordinator/edit_cargo_screen.dart';
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
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => AppPageTransitions.fade(
            key: state.pageKey,
            child: const SplashScreen(),
          ),
        ),
        GoRoute(
          path: '/login',
          pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
            key: state.pageKey,
            child: const LoginScreen(),
          ),
        ),
        GoRoute(
          path: '/signup',
          pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
            key: state.pageKey,
            child: const SignupScreen(),
          ),
        ),
        ShellRoute(
          builder: (context, state, child) => DriverShell(child: child),
          routes: [
            GoRoute(
              path: '/driver',
              pageBuilder: (context, state) =>
                  _noTransition(state, const HomeScreen(role: 'driver')),
            ),
            GoRoute(
              path: '/driver/cargos',
              pageBuilder: (context, state) =>
                  _noTransition(state, const DriverHomeScreen()),
            ),
            GoRoute(
              path: '/driver/missions',
              pageBuilder: (context, state) =>
                  _noTransition(state, const DriverMissionsScreen()),
            ),
            GoRoute(
              path: '/driver/nearby',
              pageBuilder: (context, state) =>
                  _noTransition(state, const NearbyCargoScreen()),
            ),
            GoRoute(
              path: '/driver/profile',
              pageBuilder: (context, state) => _noTransition(
                state,
                ProfileScreen(
                  role: 'driver',
                  editVehicleInitially:
                      state.uri.queryParameters['editVehicle'] == '1',
                ),
              ),
            ),
            GoRoute(
              path: '/driver/vehicle',
              pageBuilder: (context, state) =>
                  _noTransition(state, const VehicleProfileScreen()),
            ),
            GoRoute(
              path: '/driver/settings',
              pageBuilder: (context, state) =>
                  AppPageTransitions.sharedAxisHorizontal(
                    key: state.pageKey,
                    child: const SettingsScreen(),
                  ),
            ),
            GoRoute(
              path: '/driver/about',
              pageBuilder: (context, state) =>
                  AppPageTransitions.sharedAxisHorizontal(
                    key: state.pageKey,
                    child: const AboutScreen(),
                  ),
            ),
            GoRoute(
              path: '/driver/help',
              pageBuilder: (context, state) =>
                  AppPageTransitions.sharedAxisHorizontal(
                    key: state.pageKey,
                    child: const HelpScreen(role: 'driver'),
                  ),
            ),
            GoRoute(
              path: '/driver/support',
              pageBuilder: (context, state) =>
                  AppPageTransitions.sharedAxisHorizontal(
                    key: state.pageKey,
                    child: const SupportScreen(),
                  ),
            ),
            GoRoute(
              path: '/driver/change-password',
              pageBuilder: (context, state) =>
                  AppPageTransitions.sharedAxisHorizontal(
                    key: state.pageKey,
                    child: const ChangePasswordScreen(),
                  ),
            ),
          ],
        ),
        GoRoute(
          path: '/driver/cargo/:id',
          pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
            key: state.pageKey,
            child: CargoDetailScreen(cargoId: state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/driver/route/:id',
          pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
            key: state.pageKey,
            beginOffset: const Offset(0, 0.06),
            child: RouteScreen(cargoId: state.pathParameters['id']!),
          ),
        ),
        ShellRoute(
          builder: (context, state, child) => CoordinatorShell(child: child),
          routes: [
            GoRoute(
              path: '/coordinator',
              pageBuilder: (context, state) =>
                  _noTransition(state, const HomeScreen(role: 'coordinator')),
            ),
            GoRoute(
              path: '/coordinator/cargos',
              pageBuilder: (context, state) =>
                  _noTransition(state, const CoordinatorHomeScreen()),
            ),
            GoRoute(
              path: '/coordinator/drivers',
              redirect: (_, _) => '/coordinator/cargos',
            ),
            GoRoute(
              path: '/coordinator/nearby-drivers',
              redirect: (_, _) => '/coordinator/cargos',
            ),
            GoRoute(
              path: '/coordinator/profile',
              pageBuilder: (context, state) => _noTransition(
                state,
                const ProfileScreen(role: 'coordinator'),
              ),
            ),
            GoRoute(
              path: '/coordinator/settings',
              pageBuilder: (context, state) =>
                  AppPageTransitions.sharedAxisHorizontal(
                    key: state.pageKey,
                    child: const SettingsScreen(),
                  ),
            ),
            GoRoute(
              path: '/coordinator/about',
              pageBuilder: (context, state) =>
                  AppPageTransitions.sharedAxisHorizontal(
                    key: state.pageKey,
                    child: const AboutScreen(),
                  ),
            ),
            GoRoute(
              path: '/coordinator/help',
              pageBuilder: (context, state) =>
                  AppPageTransitions.sharedAxisHorizontal(
                    key: state.pageKey,
                    child: const HelpScreen(role: 'coordinator'),
                  ),
            ),
            GoRoute(
              path: '/coordinator/support',
              pageBuilder: (context, state) =>
                  AppPageTransitions.sharedAxisHorizontal(
                    key: state.pageKey,
                    child: const SupportScreen(),
                  ),
            ),
            GoRoute(
              path: '/coordinator/change-password',
              pageBuilder: (context, state) =>
                  AppPageTransitions.sharedAxisHorizontal(
                    key: state.pageKey,
                    child: const ChangePasswordScreen(),
                  ),
            ),
          ],
        ),
        GoRoute(
          path: '/coordinator/add-cargo',
          pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
            key: state.pageKey,
            child: const AddCargoScreen(),
          ),
        ),
        GoRoute(
          path: '/coordinator/cargo/:id/edit',
          pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
            key: state.pageKey,
            child: EditCargoScreen(cargoId: state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/coordinator/cargo/:id',
          pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
            key: state.pageKey,
            child: coordinator.CoordinatorCargoDetailScreen(
              cargoId: state.pathParameters['id']!,
            ),
          ),
        ),
      ],
    );
  }

  static NoTransitionPage<void> _noTransition(
    GoRouterState state,
    Widget child,
  ) {
    return NoTransitionPage<void>(key: state.pageKey, child: child);
  }
}
