import 'package:flutter/material.dart';

import 'models/admin_session.dart';
import 'services/admin_api_client.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_login_screen.dart';
import 'services/auth_service.dart';
import 'services/dashboard_service.dart';

void main() {
  runApp(const ETerminAdminApp());
}

class ETerminAdminApp extends StatefulWidget {
  const ETerminAdminApp({super.key});

  @override
  State<ETerminAdminApp> createState() => _ETerminAdminAppState();
}

class _ETerminAdminAppState extends State<ETerminAdminApp> {
  late final AuthService _authService = AuthService();
  late final DashboardService _dashboardService = DashboardService();
  AdminSession? _session;
  AdminApiClient? _apiClient;

  void _onAuthenticated(AdminSession session) {
    _apiClient?.dispose();
    _apiClient = AdminApiClient(token: session.token);
    setState(() => _session = session);
  }

  void _logout() {
    _apiClient?.dispose();
    _apiClient = null;
    setState(() => _session = null);
  }

  @override
  void dispose() {
    _authService.dispose();
    _dashboardService.dispose();
    _apiClient?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'eTermin Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF784B78),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F5F7),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: _session == null
          ? AdminLoginScreen(
              authService: _authService,
              onAuthenticated: _onAuthenticated,
            )
          : AdminDashboardScreen(
              session: _session!,
              apiClient: _apiClient!,
              dashboardService: _dashboardService,
              onLogout: _logout,
            ),
    );
  }
}
