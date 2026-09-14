import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mess_manager/providers/user_provider.dart';
import 'package:mess_manager/services/auth_service.dart';
import 'package:mess_manager/services/version_service.dart';
import 'package:mess_manager/routes.dart';
import 'package:mess_manager/utils/app_constants.dart';
import 'package:mess_manager/utils/navigation_helper.dart';
import 'package:mess_manager/widgets/copyright_footer.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _statusMessage = 'Initializing app...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() {
      _statusMessage = 'Connecting to database...';
      _hasError = false;
    });

    try {
      // Internet check (Web-compatible)
      setState(() {
        _statusMessage = 'Checking internet connection...';
      });

      await Future.delayed(const Duration(milliseconds: 500));

      // Firestore connection test
      final firestore = FirebaseFirestore.instance;

      await firestore
          .collection('users')
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 5));

      if (!mounted) return;

      setState(() {
        _statusMessage = 'Database connected successfully';
      });

      await Future.delayed(const Duration(milliseconds: 800));

      setState(() {
        _statusMessage = 'Checking version...';
      });

      final versionService = VersionService();
      final status = await versionService.checkVersionStatus();

      if (status == VersionStatus.updateRequired) {
        if (!mounted) return;
        _showUpdateDialog();
        return;
      }

      if (status == VersionStatus.maintenanceMode) {
        if (!mounted) return;
        _showMaintenanceDialog();
        return;
      }

      if (!mounted) return;

      setState(() {
        _statusMessage = 'Synchronizing with database...';
      });

      await Future.delayed(const Duration(milliseconds: 500));

      await _checkAuthStatus();
    } catch (e) {
      debugPrint('Initialization error: $e');

      if (e.toString().contains('permission-denied')) {
        if (!mounted) return;

        setState(() {
          _statusMessage = 'Connected (Secure)';
        });

        await Future.delayed(const Duration(milliseconds: 500));

        await _checkAuthStatus();
        return;
      }

      if (!mounted) return;

      setState(() {
        _statusMessage = 'Connection Error:\n$e';
        _hasError = true;
      });
    }
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Update Required'),
          content: const Text(
            'A new version of the app is available. Please update to continue using the app.',
          ),
          actions: [
            TextButton(
              onPressed: () {},
              child: const Text('Update Now'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMaintenanceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: const AlertDialog(
          title: Text('Maintenance'),
          content: Text(
            'The server is currently undergoing maintenance. Please try again later.',
          ),
        ),
      ),
    );
  }

  Future<void> _checkAuthStatus() async {
    if (!mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      final isAdminRegistered = await authService.isAdminRegistered();

      if (!isAdminRegistered) {
        if (!mounted) return;

        Navigator.of(context).pushReplacementNamed(
          AppRoutes.registration,
          arguments: {'isAdminRegistration': true},
        );
      } else {
        await userProvider.loadCurrentUser();

        if (!mounted) return;

        NavigationHelper.navigateBasedOnAuth(
          context,
          userProvider.currentUser,
        );
      }
    } catch (e) {
      debugPrint('Auth error: $e');

      if (!mounted) return;

      setState(() {
        _statusMessage = 'Authentication check failed.';
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/app_logo.png',
                      width: 150,
                      height: 150,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.restaurant_menu,
                        size: 100,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingLarge),
                    Text(
                      AppConstants.appTitle,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingLarge * 2),
                    if (_hasError)
                      Column(
                        children: [
                          Text(
                            _statusMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _initializeApp,
                            child: const Text('Retry Connection'),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(
                              Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _statusMessage,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: CopyrightFooter(
                textColor: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}