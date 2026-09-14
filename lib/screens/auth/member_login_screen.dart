import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mess_manager/providers/user_provider.dart';
import 'package:mess_manager/routes.dart';
import 'package:mess_manager/utils/app_constants.dart';
import 'package:mess_manager/utils/navigation_helper.dart';
import 'package:mess_manager/widgets/custom_button.dart';
import 'package:mess_manager/widgets/copyright_footer.dart';

/// Login screen for general members and managers.
class MemberLoginScreen extends StatefulWidget {
  const MemberLoginScreen({super.key});

  @override
  State<MemberLoginScreen> createState() => _MemberLoginScreenState();
}

class _MemberLoginScreenState extends State<MemberLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController =
      TextEditingController(); // Changed from username
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handles the member/manager login process.
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Login successful!')));
          // Navigate to the appropriate dashboard based on user role
          // Navigate based on hostel association and role
          // Navigate to the appropriate dashboard based on user role and hostel
          NavigationHelper.navigateBasedOnAuth(
            context,
            userProvider.currentUser,
          );
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
      appBar: AppBar(title: const Text(AppConstants.memberLoginTitle)),
      body: Center(
        child: SingleChildScrollView(
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
                  AppConstants.memberLoginTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.paddingLarge),
                TextFormField(
                  controller: _emailController, // Use email controller
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email', // Changed label
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
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
                      return 'Please enter password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.paddingLarge),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : CustomButton(
                      text: AppConstants.loginButton,
                      onPressed: _login,
                    ),
                const SizedBox(height: AppConstants.paddingMedium),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.registration,
                      arguments: {'isAdminRegistration': false},
                    );
                  },
                  child: const Text('Don\'t have an account? Register Now'),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushReplacementNamed(AppRoutes.adminLogin);
                  },
                  child: const Text('Admin Login'),
                ),
                const SizedBox(height: 10),
                const CopyrightFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
