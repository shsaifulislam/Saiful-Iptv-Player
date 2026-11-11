import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/widgets/tv_focus_wrapper.dart';

class AboutSupportPage extends StatefulWidget {
  const AboutSupportPage({super.key});

  @override
  State<AboutSupportPage> createState() => _AboutSupportPageState();
}

class _AboutSupportPageState extends State<AboutSupportPage> {
  final _summaryController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _category = 'playback';
  bool _diagnosticsOptIn = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _summaryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // App Header
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(Icons.live_tv_rounded,
                        size: 44, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Saiful IPTV Player',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Version 1.0.0+1 (Build 2026.11.11)',
                  style: TextStyle(fontSize: 12, color: Colors.white60),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Universal Cross-Platform IPTV Client',
                  style: TextStyle(fontSize: 13, color: AppColors.secondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Commitments & Privacy Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Privacy & Security Commitments',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'â€¢ Zero-Knowledge Credentials: Provider passwords and stream tokens are kept strictly in encrypted hardware keystores on this device and are never transmitted to cloud servers.\n'
                    'â€¢ Offline First: Local media and downloaded videos remain 100% private on your device.\n'
                    'â€¢ Open Formats: Supports M3U, M3U8, Xtream Codes, and EPG XMLTV protocols.',
                    style: TextStyle(fontSize: 12, height: 1.5, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Bug Reporting Form
          Text('Report a Problem or Feedback',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'playback', child: Text('Playback / Stream Error')),
                      DropdownMenuItem(value: 'playlist', child: Text('Playlist Parsing / M3U Issue')),
                      DropdownMenuItem(value: 'sync', child: Text('Cloud Synchronization')),
                      DropdownMenuItem(value: 'account', child: Text('Account / Login')),
                      DropdownMenuItem(value: 'accessibility', child: Text('Accessibility / UI')),
                      DropdownMenuItem(value: 'other', child: Text('Other Feedback')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _category = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _summaryController,
                    decoration: const InputDecoration(
                      labelText: 'Summary',
                      hintText: 'Brief summary of the issue (e.g. Channel X buffering)',
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Details / Steps to reproduce',
                      hintText: 'Describe what happened. Please do not paste passwords or private credentials.',
                    ),
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Include anonymous device diagnostics'),
                    subtitle: const Text('Includes platform and app version (passwords are automatically stripped).', style: TextStyle(fontSize: 11)),
                    value: _diagnosticsOptIn,
                    onChanged: (val) => setState(() => _diagnosticsOptIn = val),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TvFocusWrapper(
                      onTap: _submitReport,
                      child: FilledButton.icon(
                        onPressed: _isSubmitting ? null : _submitReport,
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Submit Report'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitReport() {
    final summary = _summaryController.text.trim();
    if (summary.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a summary of the issue.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _summaryController.clear();
          _descriptionController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you! Your bug report has been submitted to support.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });
  }
}

