import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'admin/admin_login_screen.dart';
import 'admin/admin_shell.dart';
import 'screens/auth_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/food_detail_screen.dart';
import 'screens/home_shell.dart';
import 'screens/splash_screen.dart';
import 'state/app_state.dart';
import 'theme.dart';

/// Light/dark switch shared by the whole app (toggle lives on the profile tab).
final themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);

class Routes {
  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
  static const item = '/item';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const admin = '/admin';
  static const adminDashboard = '/admin/dashboard';
}

class HungryHasteApp extends StatelessWidget {
  const HungryHasteApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: state,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeMode,
        builder: (context, mode, _) => MaterialApp(
          title: 'Hungry Haste',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: mode,
          initialRoute: Routes.splash,
          onGenerateRoute: _route,
        ),
      ),
    );
  }

  Route<dynamic> _route(RouteSettings s) {
    // Supports web deep links such as /#/item?id=lamb-biryani.
    final uri = Uri.parse(s.name ?? '/');
    Widget page = switch (uri.path) {
      Routes.splash => const SplashScreen(),
      Routes.login => const AuthScreen(),
      Routes.home => const _RequireUser(child: HomeShell()),
      Routes.item => _RequireUser(
          child: FoodDetailScreen(itemId: s.arguments as String? ?? uri.queryParameters['id'] ?? '')),
      Routes.cart => const _RequireUser(child: CartScreen()),
      Routes.checkout => const _RequireUser(child: CheckoutScreen()),
      Routes.admin => const AdminLoginScreen(),
      Routes.adminDashboard => const _RequireUser(admin: true, child: AdminShell()),
      _ => const SplashScreen(),
    };
    return MaterialPageRoute(builder: (_) => page, settings: s);
  }
}

/// Sends signed-out visitors (e.g. a deep link to /home) to the right login.
class _RequireUser extends StatelessWidget {
  const _RequireUser({required this.child, this.admin = false});
  final Widget child;
  final bool admin;

  @override
  Widget build(BuildContext context) {
    final user = context.select<AppState, Object?>((s) => s.user);
    final isAdmin = context.select<AppState, bool>((s) => s.user?.isAdmin ?? false);
    if (user != null && (!admin || isAdmin)) return child;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(admin ? Routes.admin : Routes.splash, (_) => false);
      }
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
