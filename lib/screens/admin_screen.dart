import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../providers/people_provider.dart';
import '../services/csv_parser.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final CsvParserService _parserService = CsvParserService();
  bool _isUploading = false;
  String? _selectedFileName;

  Future<void> _handleUploadCsv() async {
    setState(() => _isUploading = true);
    final pickerResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (!mounted) {
      return;
    }

    if (pickerResult == null || pickerResult.files.isEmpty) {
      setState(() => _isUploading = false);
      return;
    }

    final selectedFile = pickerResult.files.single;
    final bytes = selectedFile.bytes;
    if (bytes == null) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not read selected CSV file.')));
      return;
    }

    final csvContent = utf8.decode(bytes, allowMalformed: true);
    final people = _parserService.parsePeopleCsv(csvContent);
    if (people.isEmpty) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No valid people found. CSV must include first_name and last_name headers.',
          ),
        ),
      );
      return;
    }

    setState(() => _selectedFileName = selectedFile.name);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import people'),
        content: Text(
          'File "${selectedFile.name}" has ${people.length} record(s).\n\n'
          'Rows with an id update that person; rows without an id are added.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (!mounted) {
      return;
    }

    if (confirmed != true) {
      setState(() => _isUploading = false);
      return;
    }

    try {
      await ref.read(peopleProvider.notifier).addOrUpdatePeople(people);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported ${people.length} people from CSV.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import failed: $error')));
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ui = Theme.of(context).extension<AppUiTokens>()!;
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width > 1040 ? (width - 1040) / 2 : 16.0;
    final isWideLayout = width >= 980;

    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              ui.spaceLg + ui.spaceXs / 2,
              horizontalPadding,
              ui.spaceLg + ui.spaceXs / 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bulk Data Import',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: ui.spaceXs),
                Text(
                  'Streamline your workflow by importing people via CSV. '
                  'Ensure the file includes the required headers to maintain data integrity.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: ui.spaceLg + 4),
                if (isWideLayout)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            _buildFormatGuide(context),
                            SizedBox(height: ui.spaceMd),
                            _buildPreviousImports(context),
                          ],
                        ),
                      ),
                      SizedBox(width: ui.spaceLg),
                      Expanded(
                        flex: 7,
                        child: _buildUploadPanel(context),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildFormatGuide(context),
                      SizedBox(height: ui.spaceMd),
                      _buildUploadPanel(context),
                      SizedBox(height: ui.spaceMd),
                      _buildPreviousImports(context),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormatGuide(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ui = Theme.of(context).extension<AppUiTokens>()!;
    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ui.radiusLg)),
      child: Padding(
        padding: EdgeInsets.all(ui.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: ui.spaceXs),
                Text(
                  'CSV Format Guide',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            SizedBox(height: ui.spaceMd),
            _buildGuideItem(
              context,
              number: '01',
              text:
                  'The file must include headers: first_name,last_name. '
                  'You may also include an optional id column.',
            ),
            _buildGuideItem(
              context,
              number: '02',
              text:
                  'Rows with an existing id will update that person. '
                  'Rows without an id will create new records.',
            ),
            _buildGuideItem(
              context,
              number: '03',
              text:
                  'Use UTF-8 encoded CSV for best compatibility. '
                  'Keep data clean to avoid invalid row imports.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideItem(
    BuildContext context, {
    required String number,
    required String text,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final ui = Theme.of(context).extension<AppUiTokens>()!;
    return Padding(
      padding: EdgeInsets.only(bottom: ui.radiusSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: ui.radiusSm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousImports(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ui = Theme.of(context).extension<AppUiTokens>()!;
    final items = <({String name, String detail})>[
      (name: 'staff_roster_q3.csv', detail: '2,450 rows - Success'),
      (name: 'visitor_log_backup.csv', detail: '12,100 rows - Success'),
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ui.radiusLg)),
      child: Padding(
        padding: EdgeInsets.all(ui.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Previous Imports',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: ui.spaceSm),
            for (final item in items)
              Padding(
                padding: EdgeInsets.only(bottom: ui.radiusSm),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            item.detail,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 18,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadPanel(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ui = Theme.of(context).extension<AppUiTokens>()!;
    return Column(
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 350),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(ui.radiusLg),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.24), width: 1.4),
          ),
          child: Padding(
            padding: EdgeInsets.all(ui.spaceLg + 6),
            child: _isUploading
                ? _buildUploadingState(context)
                : _buildIdleUploadState(context),
          ),
        ),
        SizedBox(height: ui.spaceMd),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(ui.spaceMd),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(ui.radiusMd),
            border: Border.all(color: colorScheme.error.withValues(alpha: 0.24)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: colorScheme.error),
              SizedBox(width: ui.spaceXs),
              Expanded(
                child: Text(
                  'Data Overwrite Warning: importing rows with an existing id updates '
                  'existing entries. Verify your CSV before upload.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUploadingState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ui = Theme.of(context).extension<AppUiTokens>()!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: ui.spaceLg),
          Text(
            'Analyzing Data Structure...',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: ui.spaceXs - 2),
          Text(
            'Validating entries. Please do not close this window.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          SizedBox(height: ui.spaceLg + 2),
          LinearProgressIndicator(
            minHeight: 7,
            borderRadius: BorderRadius.circular(ui.radiusPill),
            backgroundColor: colorScheme.surface,
          ),
          SizedBox(height: ui.spaceXs),
          Text(
            'Processing...',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleUploadState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ui = Theme.of(context).extension<AppUiTokens>()!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.cloud_upload_outlined,
            color: Theme.of(context).colorScheme.primary,
            size: 34,
          ),
        ),
        SizedBox(height: ui.spaceMd),
        Text(
          'Upload CSV File',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: ui.spaceXs - 2),
        Text(
          'Select a CSV from your local device.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        SizedBox(height: ui.spaceLg),
        if (_selectedFileName != null)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: ui.spaceSm,
              vertical: ui.radiusSm,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(ui.radiusSm),
            ),
            child: Row(
              children: [
                const Icon(Icons.description_outlined, size: 18),
                SizedBox(width: ui.spaceXs),
                Expanded(
                  child: Text(
                    _selectedFileName!,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        if (_selectedFileName != null) SizedBox(height: ui.spaceMd),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isUploading ? null : _handleUploadCsv,
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload CSV File'),
          ),
        ),
      ],
    );
  }
}
