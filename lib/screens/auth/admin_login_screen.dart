import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:mess_manager/providers/user_provider.dart';
import 'package:mess_manager/routes.dart';
import 'package:mess_manager/utils/app_constants.dart';
import 'package:mess_manager/utils/navigation_helper.dart';
import 'package:mess_manager/widgets/custom_button.dart';
import 'package:mess_manager/widgets/copyright_footer.dart';

/// Admin login screen for authentication.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkDatabaseStatus();
  }

  Future<void> _checkDatabaseStatus() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'admin')
              .limit(1)
              .get();
      if (snapshot.docs.isEmpty) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.registration,
          arguments: {'isAdminRegistration': true},
        );
      }
    } catch (e) {
      debugPrint('Error checking database status: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handles the admin login process.
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final userProvider = Provider.of<UserProvider>(context, listen: false);

      try {
        final bool success = await userProvider.login(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (success) {
          if (!mounted) return;
          if (userProvider.isAdmin) {
            NavigationHelper.navigateBasedOnAuth(
              context,
              userProvider.currentUser,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Only Admin users can log in here.'),
              ),
            );
            await userProvider.logout();
            if (!mounted) return;
            // Use NavigationHelper to go back to Login (clearing stack)
            NavigationHelper.navigateBasedOnAuth(context, null);
          }
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid email or password.')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.adminLoginTitle)),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.restaurant_menu_rounded,
                        size: 80,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      Text(
                        AppConstants.adminLoginTitle,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: Theme.of(context).primaryColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppConstants.paddingLarge),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email', // Use Email
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: AppConstants.passwordHint,
                          prefixIcon: Icon(Icons.lock),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppConstants.paddingLarge),
                      CustomButton(
                        text: AppConstants.loginButton,
                        onPressed: _login,
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      TextButton(
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pushReplacementNamed(AppRoutes.memberLogin);
                        },
                        child: const Text('Are you a member? Login here'),
                      ),

                      const SizedBox(height: 10),
                      const CopyrightFooter(),
                    ],
                  ),
                ),
              ),
    );
  }
}
