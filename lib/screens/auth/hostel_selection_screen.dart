import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mess_manager/routes.dart';
import 'package:mess_manager/providers/user_provider.dart';

class HostelSelectionScreen extends StatefulWidget {
  const HostelSelectionScreen({super.key});

  @override
  State<HostelSelectionScreen> createState() => _HostelSelectionScreenState();
}

class _HostelSelectionScreenState extends State<HostelSelectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostelIdController = TextEditingController();
  bool _isLoading = false;

  Future<void> _joinHostel() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final success = await Provider.of<UserProvider>(
          context,
          listen: false,
        ).joinHostel(_hostelIdController.text.trim());

        if (!mounted) return;

        if (success) {
          // Navigate based on role, usually member dashboard after joining
          Navigator.pushReplacementNamed(context, AppRoutes.memberDashboard);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to join hostel. Check ID.")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _goToCreateHostel() {
    Navigator.pushNamed(context, AppRoutes.createHostel);
  }

  @override
  void dispose() {
    _hostelIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join or Create Hostel')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome! You need to join a hostel to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _hostelIdController,
                decoration: const InputDecoration(
                  labelText: 'Enter Hostel ID',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter a Hostel ID'
                            : null,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: _joinHostel,
                    child: const Text('Join Hostel'),
                  ),
              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 20),
              const Text("Don't have a hostel code?"),
              TextButton(
                onPressed: _goToCreateHostel,
                child: const Text('Create a New Hostel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
