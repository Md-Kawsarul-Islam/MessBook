import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mess_manager/models/expense_request.dart';
import 'package:mess_manager/providers/expense_request_provider.dart';
import 'package:mess_manager/providers/user_provider.dart';
import 'package:mess_manager/utils/date_helpers.dart';

class ManageRequestsScreen extends StatelessWidget {
  const ManageRequestsScreen({super.key});

  void _handleApproval(
    BuildContext context,
    ExpenseRequest request,
    bool isApprove,
  ) async {
    final provider = Provider.of<ExpenseRequestProvider>(
      context,
      listen: false,
    );

    bool success;
    if (isApprove) {
      success = await provider.approveRequest(request);
    } else {
      success = await provider.rejectRequest(request.hostelId, request.id!);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (isApprove
                    ? 'Request Approved & Added to Expenses'
                    : 'Request Rejected')
                : 'Operation failed',
          ),
          backgroundColor:
              success ? (isApprove ? Colors.green : Colors.grey) : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final requestProvider = Provider.of<ExpenseRequestProvider>(context);
    final hostelId = userProvider.currentUser?.currentHostelId;

    if (hostelId == null) {
      return const Scaffold(body: Center(child: Text('Data Loading Error')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Entry Requests')),
      body: StreamBuilder<List<ExpenseRequest>>(
        stream: requestProvider.getPendingRequestsStream(hostelId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pending requests!',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          final requests = snapshot.data!;

          return ListView.builder(
            itemCount: requests.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final req = requests[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            req.memberName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '৳${req.amount.toStringAsFixed(0)}',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Text(
                        req.items,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Requested: ${DateHelpers.formatDate(req.requestDate)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      if (requestProvider.isLoading)
                        const Center(child: LinearProgressIndicator())
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed:
                                  () => _handleApproval(context, req, false),
                              icon: const Icon(Icons.close, color: Colors.red),
                              label: const Text(
                                'Reject',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed:
                                  () => _handleApproval(context, req, true),
                              icon: const Icon(Icons.check),
                              label: const Text('Approve & Add'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
