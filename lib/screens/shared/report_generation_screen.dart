import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:mess_manager/services/report_service.dart';
import 'package:mess_manager/providers/user_provider.dart';
import 'package:mess_manager/widgets/custom_button.dart';
import 'package:mess_manager/utils/app_constants.dart';

class ReportGenerationScreen extends StatefulWidget {
  const ReportGenerationScreen({super.key});

  @override
  State<ReportGenerationScreen> createState() => _ReportGenerationScreenState();
}

class _ReportGenerationScreenState extends State<ReportGenerationScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isLoading = false;

  final List<int> _years = List.generate(
    5,
    (index) => DateTime.now().year - index,
  );

  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reportService = Provider.of<ReportService>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentMember = userProvider.currentMember;

      if (currentMember == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No member profile found.')),
        );
        return;
      }
      final hostelId = userProvider.currentUser?.currentHostelId;
      if (hostelId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final pdfBytes = await reportService.generateMonthlyReport(
        _selectedMonth,
        _selectedYear,
        currentMember,
        hostelId,
      );

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Mess_Report_${_selectedMonth}_$_selectedYear.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to generate report: $e')));
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
      appBar: AppBar(title: const Text('Generate Report')),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _selectedMonth,
                            items: List.generate(12, (index) {
                              return DropdownMenuItem(
                                value: index + 1,
                                child: Text(
                                  DateFormat(
                                    'MMMM',
                                  ).format(DateTime(2023, index + 1)),
                                ),
                              );
                            }),
                            onChanged: (value) {
                              setState(() {
                                _selectedMonth = value!;
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: 'Month',
                            ),
                          ),
                        ),
                        const SizedBox(width: AppConstants.paddingMedium),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _selectedYear,
                            items:
                                _years.map((year) {
                                  return DropdownMenuItem(
                                    value: year,
                                    child: Text(year.toString()),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedYear = value!;
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: 'Year',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.paddingLarge),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            text: 'Download Report (PDF)',
                            onPressed: _generateReport,
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
