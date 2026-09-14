import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mess_manager/services/backup_service.dart';
import 'package:mess_manager/utils/app_constants.dart';
import 'package:mess_manager/utils/date_helpers.dart';
import 'package:path/path.dart' as path;

class AdminBackupScreen extends StatefulWidget {
  const AdminBackupScreen({super.key});

  @override
  State<AdminBackupScreen> createState() => _AdminBackupScreenState();
}

class _AdminBackupScreenState extends State<AdminBackupScreen> {
  final BackupService _backupService = BackupService();
  List<FileSystemEntity> _backups = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoading = true);
    final backups = await _backupService.getBackups();
    setState(() {
      _backups = backups;
      _isLoading = false;
    });
  }

  Future<void> _createBackup() async {
    setState(() => _isLoading = true);
    final filename = await _backupService.createBackup();
    if (filename != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup created: $filename')));
      await _loadBackups();
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to create backup')));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _restoreBackup(File file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirm Restore'),
            content: const Text(
              'Are you sure you want to restore from this backup?\n\n'
              'WARNING: This will overwrite existing data with the same IDs. '
              'This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Restore',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final success = await _backupService.restoreBackup(file);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Database restored successfully!')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to restore backup')));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _deleteBackup(File file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Backup'),
            content: const Text(
              'Are you sure you want to delete this backup file?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    await _backupService.deleteBackup(file);
    await _loadBackups();
  }

  @override
  Widget build(BuildContext context) {
    // Sort backups by date (newest first)
    _backups.sort(
      (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _createBackup,
        label: const Text('Create Backup'),
        icon: const Icon(Icons.save),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _backups.isEmpty
              ? const Center(child: Text('No backups found.'))
              : ListView.builder(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                itemCount: _backups.length,
                itemBuilder: (context, index) {
                  final file = _backups[index] as File;
                  final stat = file.statSync();
                  final filename = path.basename(file.path);
                  final sizeKb = (stat.size / 1024).toStringAsFixed(1);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.withValues(alpha: 0.1),
                        child: const Icon(Icons.backup, color: Colors.blue),
                      ),
                      title: Text(filename),
                      subtitle: Text(
                        '${DateHelpers.formatDate(stat.modified)} • $sizeKb KB',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.restore),
                            tooltip: 'Restore',
                            onPressed: () => _restoreBackup(file),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete',
                            onPressed: () => _deleteBackup(file),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
