import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';
import '../models/checkin.dart';
import '../providers/checkin_provider.dart';

class LogScreen extends ConsumerStatefulWidget {
  const LogScreen({super.key});

  @override
  ConsumerState<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends ConsumerState<LogScreen> {
  String _searchQuery = '';
  bool _showOnlyWithNotes = false;

  @override
  Widget build(BuildContext context) {
    final checkinsState = ref.watch(checkInProvider);
    final ui = Theme.of(context).extension<AppUiTokens>()!;
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width > 1100 ? (width - 1100) / 2 : 16.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Check-In Log')),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            ui.spaceLg,
            horizontalPadding,
            ui.spaceLg,
          ),
          child: checkinsState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
            data: _buildLogContent,
          ),
        ),
      ),
    );
  }

  Widget _buildLogContent(List<CheckIn> checkins) {
    final colorScheme = Theme.of(context).colorScheme;
    final ui = Theme.of(context).extension<AppUiTokens>()!;
    final filteredLogs = checkins.where((item) {
      final query = _searchQuery.trim().toLowerCase();
      final matchesQuery =
          query.isEmpty ||
          item.fullName.toLowerCase().contains(query) ||
          item.notes.toLowerCase().contains(query);
      final matchesNotes = !_showOnlyWithNotes || item.notes.trim().isNotEmpty;
      return matchesQuery && matchesNotes;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live Activity Feed',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: ui.spaceXs / 2),
        Text(
          'Check-In History',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: ui.spaceLg),
        _buildControlsCard(filteredLogs.length, checkins.length),
        SizedBox(height: ui.spaceSm),
        Expanded(
          child: filteredLogs.isEmpty
              ? const Center(child: Text('No log entries found.'))
              : ListView.builder(
                  itemCount: filteredLogs.length,
                  itemBuilder: (_, index) => _buildLogRow(filteredLogs[index]),
                ),
        ),
        SizedBox(height: ui.spaceXs),
        Text(
          'Showing ${filteredLogs.length} of ${checkins.length} records',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildControlsCard(int filteredCount, int totalCount) {
    final colorScheme = Theme.of(context).colorScheme;
    final ui = Theme.of(context).extension<AppUiTokens>()!;
    return Container(
      padding: EdgeInsets.all(ui.spaceMd),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(ui.radiusLg),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search by name or notes...',
                    filled: true,
                    fillColor: colorScheme.surface.withValues(alpha: 0.75),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ui.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              SizedBox(width: ui.radiusSm),
              FilterChip(
                label: const Text('With Notes'),
                selected: _showOnlyWithNotes,
                onSelected: (value) => setState(() => _showOnlyWithNotes = value),
              ),
            ],
          ),
          SizedBox(height: ui.radiusSm),
          Text(
            '$filteredCount results • $totalCount total logs',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildLogRow(CheckIn item) {
    final colorScheme = Theme.of(context).colorScheme;
    final ui = Theme.of(context).extension<AppUiTokens>()!;
    final date = DateFormat('EEE, MMM d');
    final time = DateFormat('hh:mm a');

    return Padding(
      padding: EdgeInsets.only(bottom: ui.radiusSm),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(ui.radiusLg),
        child: Container(
          padding: EdgeInsets.all(ui.spaceMd),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ui.radiusLg),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: colorScheme.secondaryContainer,
                child: Text(
                  item.firstName.isEmpty ? '?' : item.firstName[0].toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              SizedBox(width: ui.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.fullName,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: ui.spaceXs / 2),
                    Text(
                      item.notes.trim().isEmpty ? 'No notes added.' : item.notes.trim(),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              SizedBox(width: ui.radiusSm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    date.format(item.checkedInAt.toLocal()),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: ui.spaceXs / 4),
                  Text(
                    time.format(item.checkedInAt.toLocal()),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
