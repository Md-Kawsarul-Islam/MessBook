import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mess_manager/models/expense_request.dart';
import 'package:mess_manager/providers/expense_request_provider.dart';
import 'package:mess_manager/providers/user_provider.dart';
import 'package:mess_manager/utils/app_constants.dart';
import 'package:mess_manager/utils/date_helpers.dart';

class ExpenseRequestScreen extends StatefulWidget {
  const ExpenseRequestScreen({super.key});

  @override
  State<ExpenseRequestScreen> createState() => _ExpenseRequestScreenState();
}

class _ExpenseRequestScreenState extends State<ExpenseRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemsController = TextEditingController();
  final _amountController = TextEditingController();

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final requestProvider = Provider.of<ExpenseRequestProvider>(
      context,
      listen: false,
    );

    final member = userProvider.currentMember;
    final hostelId = userProvider.currentUser?.currentHostelId;

    if (member == null || hostelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Member or Hostel not identified.'),
        ),
      );
      return;
    }

    final request = ExpenseRequest(
      memberId: member.id!,
      memberName: member.name,
      hostelId: hostelId,
      items: _itemsController.text,
      amount: double.tryParse(_amountController.text) ?? 0.0,
      requestDate: DateTime.now(),
    );

    final success = await requestProvider.submitRequest(request);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request submitted successfully!')),
      );
      _itemsController.clear();
      _amountController.clear();
      // Optional: Pop or stay
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit request.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final requestProvider = Provider.of<ExpenseRequestProvider>(context);
    final hostelId = userProvider.currentUser?.currentHostelId;
    final memberId = userProvider.currentMember?.id;

    if (hostelId == null || memberId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Entry Request')),
        body: const Center(child: Text('User information missing.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Entry Request (Shopping)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text(
                        'Submit New Shopping Request',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _itemsController,
                        decoration: const InputDecoration(
                          labelText: 'Shopping Items (Description)',
                          hintText: 'e.g., Vegetables, Oil, Spices',
                        ),
                        validator:
                            (val) => val!.isEmpty ? 'Please enter items' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Total Cost (৳)',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Enter amount';
                          if (double.tryParse(val) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed:
                            requestProvider.isLoading ? null : _submitRequest,
                        child:
                            requestProvider.isLoading
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text('Submit Request'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'My Recent Requests',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<ExpenseRequest>>(
              stream: requestProvider.getMyRequestsStream(hostelId, memberId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No requests found.');
                }
                final requests = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    Color statusColor = Colors.grey;
                    if (req.status == RequestStatus.approved) {
                      statusColor = Colors.green;
                    }
                    if (req.status == RequestStatus.rejected) {
                      statusColor = Colors.red;
                    }

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withValues(alpha: 0.2),
                          child: Icon(
                            req.status == RequestStatus.pending
                                ? Icons.hourglass_empty
                                : req.status == RequestStatus.approved
                                ? Icons.check
                                : Icons.close,
                            color: statusColor,
                          ),
                        ),
                        title: Text(req.items),
                        subtitle: Text(
                          '${DateHelpers.formatDate(req.requestDate)}\nStatus: ${req.status.toShortString()}',
                        ),
                        trailing: Text(
                          '৳${req.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
