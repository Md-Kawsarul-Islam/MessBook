import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mess_manager/providers/user_provider.dart';
import 'package:mess_manager/providers/member_provider.dart';
import 'package:mess_manager/utils/app_constants.dart';
import 'package:mess_manager/widgets/custom_button.dart';
import 'package:mess_manager/models/user_role.dart';
import 'package:mess_manager/providers/theme_provider.dart';
import 'package:mess_manager/routes.dart';

/// Screen to view and potentially edit the user's profile details.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _nameController = TextEditingController(
      text: userProvider.currentMember?.name ?? '',
    );
    _emailController = TextEditingController(
      text: userProvider.currentMember?.email ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Toggles the editing mode for the profile.
  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  /// Saves the updated profile details.
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final memberProvider = Provider.of<MemberProvider>(
        context,
        listen: false,
      );
      final hostelId = userProvider.currentUser?.currentHostelId;
      if (hostelId == null) {
        setState(() => _isLoading = false);
        return;
      }

      if (userProvider.currentMember != null) {
        final updatedMember = userProvider.currentMember!.copyWith(
          name: _nameController.text.trim(),
          email:
              _emailController.text.trim().isEmpty
                  ? null
                  : _emailController.text.trim(),
        );

        try {
          final bool success = await memberProvider.updateMember(
            updatedMember,
            hostelId,
          );
          if (success) {
            userProvider.updateCurrentMember(
              updatedMember,
            ); // Update provider's state
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully!')),
            );
            _toggleEditing(); // Exit editing mode
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to update profile.')),
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No member profile found to update.')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.profile),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.cancel : Icons.edit),
            onPressed: _toggleEditing,
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.currentUser;

          if (user == null) {
            return const Center(child: Text('User not logged in.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.person,
                        size: 80,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),
                  _buildProfileField(
                    'Username',
                    user.username,
                    Icons.account_circle,
                  ),
                  _buildProfileField(
                    'Role',
                    user.role.toShortString(),
                    Icons.security,
                  ),
                  _buildProfileField(
                    'Active Status',
                    user.isActive ? 'Active' : 'Inactive',
                    user.isActive ? Icons.check_circle : Icons.cancel,
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Card(
                    elevation: 0,
                    color: Theme.of(context).cardColor,
                    margin: const EdgeInsets.symmetric(
                      vertical: AppConstants.paddingSmall,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.withAlpha(50)),
                    ),
                    child: Consumer<ThemeProvider>(
                      builder: (context, themeProvider, _) {
                        return Column(
                          children: [
                            SwitchListTile(
                              title: const Text('Dark Mode'),
                              secondary: Icon(
                                themeProvider.isDarkMode
                                    ? Icons.dark_mode
                                    : Icons.light_mode,
                                color: Theme.of(context).primaryColor,
                              ),
                              value: themeProvider.isDarkMode,
                              onChanged: (value) {
                                themeProvider.toggleTheme(value);
                              },
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: Icon(
                                Icons.picture_as_pdf,
                                color: Theme.of(context).primaryColor,
                              ),
                              title: const Text('Generate Monthly Report'),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              ),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.generateReport,
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Text(
                    'Member Details:',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.badge),
                    ),
                    readOnly: !_isEditing,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Name cannot be empty';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email (Optional)',
                      prefixIcon: Icon(Icons.email),
                    ),
                    readOnly: !_isEditing,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),
                  if (_isEditing)
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : CustomButton(
                          text: AppConstants.saveButton,
                          onPressed: _saveProfile,
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileField(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppConstants.paddingSmall / 2,
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: AppConstants.paddingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelLarge),
                Text(value, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
