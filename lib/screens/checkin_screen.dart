import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/person.dart';
import '../providers/checkin_provider.dart';
import '../providers/people_provider.dart';
import '../widgets/checkin_dialog.dart';
import '../widgets/weather_indicator.dart';

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  bool _isBatchMode = false;
  bool _isBatchPanelExpanded = false;
  final Set<String> _selectedIds = <String>{};

  Future<void> _onPersonCheckIn(
    BuildContext context,
    Person person,
  ) async {
    final notes = await showDialog<String>(
      context: context,
      builder: (_) => const CheckInDialog(),
    );
    if (notes == null) {
      return;
    }
    await ref.read(checkInProvider.notifier).createCheckIn(person, notes: notes);
  }

  Future<void> _onPersonTap(Person person) async {
    if (_isBatchMode) {
      _toggleSelection(person.id);
      return;
    }
    await _onPersonCheckIn(context, person);
  }

  void _toggleBatchMode() {
    setState(() {
      _isBatchMode = !_isBatchMode;
      if (!_isBatchMode) {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _deleteSelectedPeople() async {
    if (_selectedIds.isEmpty) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete selected people?'),
        content: Text(
          'This will permanently delete ${_selectedIds.length} selected name(s).',
        ),
        actions: [
          TextButton(
            onPressed: () {
              final navigator = Navigator.of(dialogContext, rootNavigator: true);
              if (navigator.canPop()) {
                navigator.pop(false);
              }
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final navigator = Navigator.of(dialogContext, rootNavigator: true);
              if (navigator.canPop()) {
                navigator.pop(true);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    try {
      await ref.read(peopleProvider.notifier).deletePeopleByIds(_selectedIds);
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedIds.clear();
        _isBatchMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected names deleted.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $error')));
    }
  }

  Future<void> _checkInSelectedPeople(
    List<Person> filteredPeople,
    Set<String> checkedInIds,
  ) async {
    if (_selectedIds.isEmpty) {
      return;
    }

    final notes = await showDialog<String>(
      context: context,
      builder: (_) => const CheckInDialog(),
    );
    if (notes == null || !mounted) {
      return;
    }

    final selectedPeople = filteredPeople
        .where((person) => _selectedIds.contains(person.id))
        .toList();
    final peopleToCheckIn = selectedPeople
        .where((person) => !checkedInIds.contains(person.id))
        .toList();

    if (peopleToCheckIn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All selected people are already checked in.')),
      );
      return;
    }

    try {
      final notifier = ref.read(checkInProvider.notifier);
      for (final person in peopleToCheckIn) {
        await notifier.createCheckIn(person, notes: notes);
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _selectedIds.clear();
        _isBatchMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${peopleToCheckIn.length} people checked in successfully.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Batch check-in failed: $error')));
    }
  }

  Future<void> _checkOutSelectedPeople(Set<String> checkedInIds) async {
    if (_selectedIds.isEmpty) {
      return;
    }

    final idsToCheckOut = _selectedIds
        .where((id) => checkedInIds.contains(id))
        .toList();

    if (idsToCheckOut.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No selected people are currently checked in.')),
      );
      return;
    }

    try {
      await ref.read(checkInProvider.notifier).checkOutPeopleByIds(idsToCheckOut);
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedIds.clear();
        _isBatchMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${idsToCheckOut.length} people checked out successfully.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Batch check-out failed: $error')));
    }
  }

  Future<void> _deleteSinglePerson(Person person) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete person?'),
        content: Text('This will permanently delete ${person.fullName}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    try {
      await ref.read(peopleProvider.notifier).deletePeopleByIds({person.id});
      if (!mounted) {
        return;
      }
      _selectedIds.remove(person.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${person.fullName} deleted.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ui = Theme.of(context).extension<AppUiTokens>()!;
    final peopleState = ref.watch(peopleProvider);
    final visiblePeople = ref.watch(visiblePeopleProvider);
    final checkedInIds = ref.watch(checkedInIdsProvider);
    final statusFilter = ref.watch(peopleStatusFilterProvider);
    final sortOption = ref.watch(peopleSortProvider);
    final checkedInVisibleCount = visiblePeople
        .where((person) => checkedInIds.contains(person.id))
        .length;
    final visibleTotalCount = visiblePeople.length;
    final visibleProgress = visibleTotalCount == 0
        ? 0.0
        : checkedInVisibleCount / visibleTotalCount;
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width > 1100 ? (width - 1100) / 2 : 16.0;
    final isWideControls = width >= 960;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-In System'),
        actions: const [WeatherIndicator()],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            ui.spaceLg,
            horizontalPadding,
            ui.spaceLg,
          ),
          child: ListView(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  padding: EdgeInsets.all(ui.spaceXs / 2),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(ui.radiusMd),
                  ),
                  child: Row(
                    children: [
                      _buildFilterButton(
                        context,
                        label: 'All',
                        selected: statusFilter == PeopleStatusFilter.all,
                        onTap: () => ref.read(peopleStatusFilterProvider.notifier).state =
                            PeopleStatusFilter.all,
                      ),
                      _buildFilterButton(
                        context,
                        label: 'Checked In',
                        selected: statusFilter == PeopleStatusFilter.checkedIn,
                        onTap: () => ref.read(peopleStatusFilterProvider.notifier).state =
                            PeopleStatusFilter.checkedIn,
                      ),
                      _buildFilterButton(
                        context,
                        label: 'Not Checked In',
                        selected: statusFilter == PeopleStatusFilter.notCheckedIn,
                        onTap: () => ref.read(peopleStatusFilterProvider.notifier).state =
                            PeopleStatusFilter.notCheckedIn,
                      ),
                      SizedBox(width: ui.spaceSm),
                      _buildFilterProgress(
                        context,
                        checkedInCount: checkedInVisibleCount,
                        totalCount: visibleTotalCount,
                        progress: visibleProgress,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: ui.spaceLg),
              if (isWideControls)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildSearchPanel(context, sortOption)),
                    SizedBox(width: ui.spaceSm),
                    SizedBox(
                      width: 230,
                      child: _buildBatchPanelSection(
                        context,
                        visiblePeople: visiblePeople,
                        checkedInIds: checkedInIds,
                        compact: true,
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _buildSearchPanel(context, sortOption),
                    SizedBox(height: ui.spaceSm),
                    _buildBatchPanelSection(
                      context,
                      visiblePeople: visiblePeople,
                      checkedInIds: checkedInIds,
                    ),
                  ],
                ),
              SizedBox(height: ui.spaceSm),
              Text(
                _isBatchMode
                    ? 'Batch mode is active: tap rows to select, then run actions.'
                    : 'Tap a person row to check in quickly.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              SizedBox(height: ui.spaceSm),
              peopleState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
                data: (_) {
                  if (visiblePeople.isEmpty) {
                    return const Center(child: Text('No people found.'));
                  }
                  return Container(
                    padding: EdgeInsets.all(ui.spaceSm),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(ui.radiusLg),
                    ),
                    child: Column(
                      children: [
                        for (final person in visiblePeople)
                          _buildPersonRow(
                            context,
                            person: person,
                            isCheckedIn: checkedInIds.contains(person.id),
                            isSelected: _selectedIds.contains(person.id),
                          ),
                        SizedBox(height: ui.spaceXs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Showing ${visiblePeople.length} registered guests',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: _toggleBatchMode,
                              icon: Icon(_isBatchMode ? Icons.close : Icons.done_all),
                              label: Text(_isBatchMode ? 'Exit Batch' : 'Batch Mode'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final ui = Theme.of(context).extension<AppUiTokens>()!;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ui.spaceXs / 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(ui.radiusSm),
          boxShadow: selected
              ? [
                  BoxShadow(
                    blurRadius: 6,
                    color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
                  ),
                ]
              : null,
        ),
        child: TextButton(
          onPressed: onTap,
          child: Text(label),
        ),
      ),
    );
  }

  Widget _buildSearchPanel(BuildContext context, PeopleSortOption sortOption) {
    final colorScheme = Theme.of(context).colorScheme;
    final ui = Theme.of(context).extension<AppUiTokens>()!;
    return Container(
      padding: EdgeInsets.all(ui.spaceMd),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(ui.radiusLg),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person_search),
                hintText: 'Search by name...',
                filled: true,
                fillColor: colorScheme.surface.withValues(alpha: 0.75),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ui.radiusMd),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => ref.read(peopleSearchProvider.notifier).state = value,
            ),
          ),
          SizedBox(width: ui.spaceSm),
          SizedBox(
            width: 168,
            child: DropdownButtonFormField<PeopleSortOption>(
              initialValue: sortOption,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Sort',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(
                  value: PeopleSortOption.nameAsc,
                  child: Text('Name A-Z'),
                ),
                DropdownMenuItem(
                  value: PeopleSortOption.nameDesc,
                  child: Text('Name Z-A'),
                ),
                DropdownMenuItem(
                  value: PeopleSortOption.recentlyCheckedIn,
                  child: Text('Newest'),
                ),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                ref.read(peopleSortProvider.notifier).state = value;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterProgress(
    BuildContext context, {
    required int checkedInCount,
    required int totalCount,
    required double progress,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final ui = Theme.of(context).extension<AppUiTokens>()!;
    return Container(
      width: 180,
      padding: EdgeInsets.symmetric(
        horizontal: ui.spaceXs,
        vertical: ui.spaceXs / 2,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(ui.radiusSm),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$checkedInCount/$totalCount checked in',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: ui.spaceXs / 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(ui.radiusPill),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: progress,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchPanel(
    BuildContext context, {
    required List<Person> visiblePeople,
    required Set<String> checkedInIds,
    bool compact = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final ui = Theme.of(context).extension<AppUiTokens>()!;
    return Container(
      padding: EdgeInsets.all(ui.spaceMd),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(ui.radiusLg),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Batch Mode',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (!compact)
                      Text(
                        'Perform actions on multiple guests',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              SizedBox(width: ui.spaceXs),
              Switch(
                value: _isBatchMode,
                onChanged: (_) => _toggleBatchMode(),
              ),
            ],
          ),
          SizedBox(height: ui.spaceSm),
          Text(
            '${_selectedIds.length} items selected',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: ui.radiusSm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: !_isBatchMode || _selectedIds.isEmpty
                    ? null
                    : _deleteSelectedPeople,
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
              ),
              FilledButton.icon(
                onPressed: !_isBatchMode || _selectedIds.isEmpty
                    ? null
                    : () => _checkInSelectedPeople(visiblePeople, checkedInIds),
                icon: const Icon(Icons.login),
                label: const Text('Check In'),
              ),
              FilledButton.tonalIcon(
                onPressed: !_isBatchMode || _selectedIds.isEmpty
                    ? null
                    : () => _checkOutSelectedPeople(checkedInIds),
                icon: const Icon(Icons.logout),
                label: const Text('Check Out'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBatchPanelSection(
    BuildContext context, {
    required List<Person> visiblePeople,
    required Set<String> checkedInIds,
    bool compact = false,
  }) {
    final ui = Theme.of(context).extension<AppUiTokens>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            style: compact
                ? OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.symmetric(
                      horizontal: ui.spaceXs,
                      vertical: ui.spaceXs / 2,
                    ),
                  )
                : null,
            onPressed: () {
              setState(() => _isBatchPanelExpanded = !_isBatchPanelExpanded);
            },
            icon: Icon(_isBatchPanelExpanded ? Icons.expand_less : Icons.expand_more),
            label: Text(_isBatchPanelExpanded ? 'Hide Batch' : 'Batch Mode'),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState: _isBatchPanelExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: EdgeInsets.only(top: ui.spaceSm),
            child: _buildBatchPanel(
              context,
              visiblePeople: visiblePeople,
              checkedInIds: checkedInIds,
              compact: compact,
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildPersonRow(
    BuildContext context, {
    required Person person,
    required bool isCheckedIn,
    required bool isSelected,
  }) {
    final ui = Theme.of(context).extension<AppUiTokens>()!;
    return Padding(
      padding: EdgeInsets.only(bottom: ui.radiusSm),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(ui.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(ui.radiusLg),
          onTap: () => _onPersonTap(person),
          child: Container(
            padding: EdgeInsets.all(ui.spaceMd),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ui.radiusLg),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                if (_isBatchMode)
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleSelection(person.id),
                  ),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  child: Text(
                    person.firstName.isEmpty ? '?' : person.firstName[0].toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                SizedBox(width: ui.spaceSm),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWideRow = constraints.maxWidth >= 420;
                      if (!isWideRow) {
                        return Text(
                          person.fullName,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        );
                      }
                      return Row(
                        children: [
                          Expanded(
                            child: Text(
                              person.fullName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Reception Queue',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(width: ui.spaceXs),
                _buildStatusChip(context, isCheckedIn: isCheckedIn),
                SizedBox(width: ui.spaceXs),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: () => _deleteSinglePerson(person),
                  icon: const Icon(Icons.delete_outline),
                ),
                if (!isCheckedIn && !_isBatchMode)
                  FilledButton(
                    onPressed: () => _onPersonCheckIn(context, person),
                    child: const Text('Check-In'),
                  )
                else
                  IconButton(
                    onPressed: () => _onPersonTap(person),
                    icon: const Icon(Icons.more_vert),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, {required bool isCheckedIn}) {
    final colorScheme = Theme.of(context).colorScheme;
    final ui = Theme.of(context).extension<AppUiTokens>()!;
    final background = isCheckedIn
        ? colorScheme.primaryContainer
        : colorScheme.secondaryContainer;
    final foreground = isCheckedIn
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSecondaryContainer;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ui.radiusSm,
        vertical: ui.spaceXs - 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(ui.radiusPill),
      ),
      child: Text(
        isCheckedIn ? 'Checked In' : 'Not Checked In',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
