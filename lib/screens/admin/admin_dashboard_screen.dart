import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mess_manager/providers/user_provider.dart';
import 'package:mess_manager/providers/member_provider.dart';
import 'package:mess_manager/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:mess_manager/models/user.dart';
import 'package:mess_manager/models/user_role.dart';
import 'package:mess_manager/models/hostel.dart';
import 'package:mess_manager/routes.dart';
import 'package:mess_manager/utils/app_constants.dart';
import 'package:mess_manager/widgets/copyright_footer.dart';
import 'package:mess_manager/widgets/dashboard_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Admin dashboard for System Management (Hostels & Users).
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = false;
  List<User> _users = [];
  // System Stats
  Hostel? _currentHostel;
  List<Hostel> _ownedHostels = [];

  // System Stats
  // System Stats
  int _totalHostels = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  /// Fetches users, members, hostel info, and stats.
  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final memberProvider = Provider.of<MemberProvider>(
        context,
        listen: false,
      );
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // 0. Fetch Owned Hostels (As Super Admin, ideally fetch ALL, but keeping existing logic for now)
      _ownedHostels = await userProvider.fetchOwnedHostels();
      _totalHostels = _ownedHostels.length;

      // 1. Fetch Users (Only for current hostel if exists)
      final currentUser = userProvider.currentUser;
      if (currentUser != null && currentUser.currentHostelId != null) {
        final String hostelId = currentUser.currentHostelId!;
        _users =
            (await authService.getAllUsers(
              hostelId,
            )).where((u) => u.role != UserRole.admin).toList();
      } else {
        _users = [];
      }

      // 2. Fetch Hostel Context & Data
      if (currentUser != null && currentUser.currentHostelId != null) {
        final String hostelId = currentUser.currentHostelId!;

        // Fetch Hostel Details
        final hostelDoc =
            await FirebaseFirestore.instance
                .collection('hostels')
                .doc(hostelId)
                .get();
        if (hostelDoc.exists) {
          _currentHostel = Hostel.fromFirestore(hostelDoc);
        }

        // Fetch Members
        await memberProvider.fetchAllMembers(hostelId);
        // Fetch Members
        await memberProvider.fetchAllMembers(hostelId);
        // Note: We are no longer mapping member names here, accessing User data directly.
      } else {}
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Toggles the active status of a user.
  Future<void> _toggleActiveStatus(User user) async {
    if (user.uid == null) return;
    setState(() {
      _isLoading = true;
    });
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      final bool success = await authService.updateUserActiveStatus(
        user.uid!,
        !user.isActive,
      );
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.username} active status updated.')),
        );
        _fetchDashboardData(); // Refresh list
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update active status.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Changes a user's role.
  Future<void> _changeUserRole(User user) async {
    if (user.uid == null) return;
    final UserRole? selectedRole = await showDialog<UserRole>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Change Role for ${user.username}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Simple Radio List
              ...UserRole.values
                  .where(
                    (role) => role != UserRole.admin && role != UserRole.none,
                  )
                  .map((role) {
                    return ListTile(
                      title: Text(role.toShortString()),
                      leading: Icon(
                        user.role == role
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: Theme.of(context).primaryColor,
                      ),
                      onTap: () {
                        Navigator.of(context).pop(role);
                      },
                    );
                  }),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    if (selectedRole != null && selectedRole != user.role) {
      setState(() {
        _isLoading = true;
      });
      final authService = Provider.of<AuthService>(context, listen: false);
      try {
        final bool success = await authService.changeUserRole(
          user.uid!,
          selectedRole,
        );
        if (success) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${user.username}\'s role changed to ${selectedRole.toShortString()}.',
              ),
            ),
          );
          _fetchDashboardData(); // Refresh list
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to change user role.')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  /// Deletes a user.
  Future<void> _deleteUser(User user) async {
    if (user.uid == null) return;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete User'),
          content: Text(
            'Are you sure you want to delete user "${user.username}"? This action is irreversible.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });
      final authService = Provider.of<AuthService>(context, listen: false);
      try {
        final bool success = await authService.deleteUser(user.uid!);
        if (!mounted) return;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.username} deleted successfully.')),
          );
          _fetchDashboardData(); // Refresh list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete user.')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  /// Handles user logout.
  Future<void> _logout() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.memberLogin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _fetchDashboardData,
                child: CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(
                          AppConstants.paddingMedium,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSystemStats(),
                            const SizedBox(height: AppConstants.paddingLarge),
                            _buildHostelsListSection(),
                            const SizedBox(height: AppConstants.paddingLarge),
                            if (_currentHostel != null) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'User Management',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Chip(
                                    label: Text('${_users.length} Users'),
                                    backgroundColor: Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.1),
                                    labelStyle: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppConstants.paddingSmall),
                              _buildUserList(),
                            ],
                            const SizedBox(height: 40),
                            _buildFactoryResetButton(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [CopyrightFooter()],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: true,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: const Text(
          'Admin Portal',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white, // Ensure text is visible on gradient
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColorDark,
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _fetchDashboardData,
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: _logout,
          tooltip: AppConstants.logoutButton,
        ),
      ],
    );
  }

  Widget _buildFactoryResetButton() {
    return Center(
      child: OutlinedButton.icon(
        onPressed: _resetSystem,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        icon: const Icon(Icons.warning_amber_rounded),
        label: const Text('FACTORY RESET SYSTEM'),
      ),
    );
  }

  Widget _buildSystemStats() {
    return Row(
      children: [
        Expanded(
          child: DashboardCard(
            title: 'Total Hostels',
            value: _totalHostels.toString(),
            icon: Icons.apartment,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: AppConstants.paddingSmall),
        Expanded(
          child: DashboardCard(
            title: 'Total Members',
            value: _users.length.toString(),
            icon: Icons.group,
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildHostelsListSection() {
    if (_ownedHostels.isEmpty) {
      return Center(
        child: Column(
          children: [
            const Text('No hostels found.'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _navigateToCreateHostel,
              child: const Text('Create First Hostel'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Hostels',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _navigateToCreateHostel,
              icon: const Icon(Icons.add),
              label: const Text('Add New'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _ownedHostels.length,
            itemBuilder: (context, index) {
              final hostel = _ownedHostels[index];
              final isSelected = _currentHostel?.id == hostel.id;

              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 12, bottom: 4, top: 4),
                child: Card(
                  elevation: isSelected ? 4 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side:
                        isSelected
                            ? BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            )
                            : BorderSide.none,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      if (!isSelected && hostel.id != null) {
                        _switchHostel(hostel.id!);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    isSelected
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey.shade200,
                                child: Icon(
                                  Icons.apartment,
                                  color:
                                      isSelected ? Colors.white : Colors.grey,
                                ),
                              ),
                              if (isSelected)
                                Chip(
                                  label: const Text(
                                    'Active',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                  backgroundColor: Colors.green.withValues(
                                    alpha: 0.1,
                                  ),
                                  labelStyle: const TextStyle(
                                    color: Colors.green,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            hostel.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            hostel.address ?? 'No Address',
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "ID: ${hostel.inviteCode ?? 'N/A'}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18),
                                    onPressed:
                                        () => _showEditHostelDialog(hostel),
                                    tooltip: 'Edit',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _deleteHostel(hostel),
                                    tooltip: 'Delete',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- User Management Section ---

  String _userFilter = 'All'; // 'All', 'Manager', 'Member'

  Widget _buildUserList() {
    if (_currentHostel == null) return const SizedBox.shrink();

    List<User> filteredUsers = _users;
    if (_userFilter == 'Manager') {
      filteredUsers = _users.where((u) => u.role == UserRole.manager).toList();
    } else if (_userFilter == 'Member') {
      filteredUsers = _users.where((u) => u.role == UserRole.member).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All'),
              const SizedBox(width: 8),
              _buildFilterChip('Manager'),
              const SizedBox(width: 8),
              _buildFilterChip('Member'),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.paddingMedium),

        if (filteredUsers.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('No users found.')),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              // Find member details if available (optional mapping)
              // Implementation note: Ideally we map user to member profile if needed,
              // but here we just show what we have in User object + maybe fetch member name if separate.
              // Assuming user.username is the primary display for now as per existing code.

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor:
                        user.role == UserRole.manager
                            ? Colors.orange.withValues(alpha: 0.2)
                            : Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1),
                    child: Text(
                      user.username.isNotEmpty
                          ? user.username[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color:
                            user.role == UserRole.manager
                                ? Colors.orange
                                : Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    user.username,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              user.role == UserRole.manager
                                  ? Colors.orange.withValues(alpha: 0.1)
                                  : Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Role: ${user.role.toShortString().toUpperCase()}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color:
                                user.role == UserRole.manager
                                    ? Colors.orange
                                    : Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Email: ${user.email}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (String choice) {
                      if (choice == 'toggle_active') {
                        _toggleActiveStatus(user);
                      } else if (choice == 'change_role') {
                        _changeUserRole(user);
                      } else if (choice == 'delete_user') {
                        _deleteUser(user);
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'toggle_active',
                          child: Row(
                            children: [
                              Icon(
                                user.isActive
                                    ? Icons.block
                                    : Icons.check_circle,
                                color:
                                    user.isActive ? Colors.grey : Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(user.isActive ? 'Deactivate' : 'Activate'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'change_role',
                          child: Row(
                            children: [
                              Icon(Icons.admin_panel_settings, size: 20),
                              SizedBox(width: 8),
                              Text('Change Role'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem<String>(
                          value: 'delete_user',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_forever,
                                color: Colors.red,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Delete User',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final bool isSelected = _userFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _userFilter = label;
          });
        }
      },
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Future<void> _showEditHostelDialog(Hostel hostel) async {
    // ignore: unnecessary_null_comparison
    if (hostel == null) return;

    final nameController = TextEditingController(text: hostel.name);
    final addressController = TextEditingController(text: hostel.address);
    final inviteCodeController = TextEditingController(text: hostel.inviteCode);

    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Hostel Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Hostel Name'),
                ),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                TextField(
                  controller: inviteCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Hostel ID (Auto-Generated)',
                    helperText: "Unique ID for members to join",
                  ),
                  readOnly: true,
                  enabled: false,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final updatedHostel = Hostel(
          id: hostel.id,
          name: nameController.text.trim(),
          address: addressController.text.trim(),
          inviteCode: inviteCodeController.text.trim(),
          ownerId: hostel.ownerId,
          createdAt: hostel.createdAt,
        );

        await FirebaseFirestore.instance
            .collection('hostels')
            .doc(hostel.id)
            .update(updatedHostel.toFirestore());

        await _fetchDashboardData(); // Refresh UI
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hostel details updated!')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteHostel(Hostel hostel) async {
    // ignore: unnecessary_null_comparison
    if (hostel == null) return;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete Hostel'),
          content: Text(
            'Are you sure you want to delete "${hostel.name}"?\n\n'
            'This will delete the hostel reference. (Note: Data cleanup might be needed manually if not automated).',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance
            .collection('hostels')
            .doc(hostel.id)
            .delete();
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Hostel deleted.')));
        // Switch to another hostel or clear selection
        // For now, just re-fetch, which might lead to empty state
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        // We might need to clear currentHostelId in user record too if we want to be clean
        if (userProvider.currentUser != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userProvider.currentUser!.uid)
              .update({'currentHostelId': null});
        }

        await _fetchDashboardData();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting hostel: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetSystem() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController codeController = TextEditingController();
        return AlertDialog(
          title: const Text('FACTORY RESET'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'WARNING: This will DELETE ALL DATA (Users, Hostels, Meals, Expenses) and cannot be undone.\n\n'
                'Type "DELETE" to confirm.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Confirmation Code',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                if (codeController.text == 'DELETE') {
                  Navigator.of(context).pop(true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Incorrect code.')),
                  );
                }
              },
              child: const Text(
                'DELETE EVERYTHING',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      if (!mounted) return;
      setState(() => _isLoading = true);

      try {
        final firestore = FirebaseFirestore.instance;
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final currentUser = userProvider.currentUser;

        if (currentUser == null) {
          throw Exception('Current admin user context not found.');
        }

        // 1. Delete all Hostels and their subcollections
        final hostelSnapshot = await firestore.collection('hostels').get();
        for (var doc in hostelSnapshot.docs) {
          final hostelRef = doc.reference;
          await _deleteCollection(hostelRef.collection('mealEntries'));
          await _deleteCollection(hostelRef.collection('expenses'));
          await _deleteCollection(hostelRef.collection('contributions'));
          await _deleteCollection(hostelRef.collection('members'));
          await _deleteCollection(hostelRef.collection('marketSchedules'));
          await hostelRef.delete();
        }

        // 2. Delete all Users
        final userSnapshot = await firestore.collection('users').get();
        for (var doc in userSnapshot.docs) {
          await doc.reference.delete();
        }

        // 3. Delete current Admin Auth account
        try {
          await fa.FirebaseAuth.instance.currentUser?.delete();
        } catch (e) {
          debugPrint("Error deleting auth user: $e");
        }

        // 4. Clear SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('System Reset Complete. Restarting...')),
        );

        // 5. Navigate to Register/Login
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.memberLogin, (route) => false);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Reset Failed: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteCollection(CollectionReference collection) async {
    final snapshot = await collection.get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> _switchHostel(String hostelId) async {
    setState(() => _isLoading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.switchHostel(hostelId);
      await _fetchDashboardData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to switch hostel: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToCreateHostel() {
    Navigator.pushNamed(context, AppRoutes.createHostel).then((_) {
      _fetchDashboardData(); // Refresh if they created one
    });
  }
}
