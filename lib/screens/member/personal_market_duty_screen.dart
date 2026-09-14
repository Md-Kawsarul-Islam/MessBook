import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mess_manager/models/market_schedule.dart';
import 'package:mess_manager/providers/market_schedule_provider.dart';
import 'package:mess_manager/providers/user_provider.dart';
import 'package:mess_manager/utils/app_constants.dart';
import 'package:mess_manager/utils/date_helpers.dart';

/// Screen for members to view their assigned market duties.
class PersonalMarketDutyScreen extends StatefulWidget {
  const PersonalMarketDutyScreen({super.key});

  @override
  State<PersonalMarketDutyScreen> createState() =>
      _PersonalMarketDutyScreenState();
}

class _PersonalMarketDutyScreenState extends State<PersonalMarketDutyScreen> {
  List<MarketSchedule> _marketDuties = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPersonalMarketDuties();
  }

  /// Fetches the market duties for the current logged-in member.
  Future<void> _fetchPersonalMarketDuties() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final marketScheduleProvider = Provider.of<MarketScheduleProvider>(
        context,
        listen: false,
      );

      final String? memberId = userProvider.currentMember?.id; // String ID
      final String? hostelId = userProvider.currentUser?.currentHostelId;
      if (memberId != null && hostelId != null) {
        _marketDuties = await marketScheduleProvider
            .fetchMarketSchedulesByMember(memberId, hostelId);
      } else {
        _marketDuties = [];
      }
    } catch (e) {
      debugPrint('Error fetching personal market duties: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load market duties: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.personalMarketDuty)),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _marketDuties.isEmpty
              ? const Center(child: Text('No market duties assigned to you.'))
              : ListView.builder(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                itemCount: _marketDuties.length,
                itemBuilder: (context, index) {
                  final duty = _marketDuties[index];
                  return Card(
                    margin: const EdgeInsets.only(
                      bottom: AppConstants.paddingSmall,
                    ),
                    elevation: 2,
                    child: ListTile(
                      title: Text(duty.dutyTitle),
                      subtitle: Text(
                        'Date: ${DateHelpers.formatDate(duty.scheduleDate)}\nDescription: ${duty.description}',
                      ),
                      leading: Icon(
                        Icons.calendar_today,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
