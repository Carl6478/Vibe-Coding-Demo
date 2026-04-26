import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/checkin_provider.dart';
import '../models/checkin.dart';
import '../models/person.dart';
import '../services/people_service.dart';

final peopleServiceProvider = Provider<PeopleService>((ref) {
  return PeopleService(checkInService: ref.watch(checkInServiceProvider));
});
final peopleSearchProvider = StateProvider<String>((ref) => '');
final peopleStatusFilterProvider =
    StateProvider<PeopleStatusFilter>((ref) => PeopleStatusFilter.all);
final peopleSortProvider =
    StateProvider<PeopleSortOption>((ref) => PeopleSortOption.nameAsc);

final peopleProvider =
    StateNotifierProvider<PeopleNotifier, AsyncValue<List<Person>>>((ref) {
  return PeopleNotifier(ref, ref.watch(peopleServiceProvider));
});

final filteredPeopleProvider = Provider<List<Person>>((ref) {
  final peopleState = ref.watch(peopleProvider);
  final query = ref.watch(peopleSearchProvider).trim().toLowerCase();
  final people = peopleState.value ?? <Person>[];
  if (query.isEmpty) {
    return people;
  }

  return people.where((person) {
    return person.fullName.toLowerCase().contains(query) ||
        person.id.toLowerCase().contains(query);
  }).toList();
});

final visiblePeopleProvider = Provider<List<Person>>((ref) {
  final people = ref.watch(filteredPeopleProvider);
  final statusFilter = ref.watch(peopleStatusFilterProvider);
  final sortOption = ref.watch(peopleSortProvider);
  final checkedInIds = ref.watch(checkedInIdsProvider);
  final checkIns = ref.watch(checkInProvider).value ?? <CheckIn>[];
  final latestCheckInByPerson = <String, DateTime>{};

  for (final checkIn in checkIns) {
    final existing = latestCheckInByPerson[checkIn.personId];
    if (existing == null || checkIn.checkedInAt.isAfter(existing)) {
      latestCheckInByPerson[checkIn.personId] = checkIn.checkedInAt;
    }
  }

  var result = people.where((person) {
    switch (statusFilter) {
      case PeopleStatusFilter.checkedIn:
        return checkedInIds.contains(person.id);
      case PeopleStatusFilter.notCheckedIn:
        return !checkedInIds.contains(person.id);
      case PeopleStatusFilter.all:
        return true;
    }
  }).toList();

  result.sort((a, b) {
    switch (sortOption) {
      case PeopleSortOption.nameAsc:
        return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
      case PeopleSortOption.nameDesc:
        return b.fullName.toLowerCase().compareTo(a.fullName.toLowerCase());
      case PeopleSortOption.recentlyCheckedIn:
        final aTime = latestCheckInByPerson[a.id];
        final bTime = latestCheckInByPerson[b.id];
        if (aTime == null && bTime == null) {
          return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
        }
        if (aTime == null) {
          return 1;
        }
        if (bTime == null) {
          return -1;
        }
        return bTime.compareTo(aTime);
    }
  });

  return result;
});

enum PeopleStatusFilter { all, checkedIn, notCheckedIn }

enum PeopleSortOption { nameAsc, nameDesc, recentlyCheckedIn }

class PeopleNotifier extends StateNotifier<AsyncValue<List<Person>>> {
  PeopleNotifier(this.ref, this._peopleService)
    : super(const AsyncValue.loading()) {
    loadPeople();
  }

  final Ref ref;
  final PeopleService _peopleService;

  Future<void> loadPeople() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_peopleService.fetchPeople);
  }

  Future<void> addOrUpdatePeople(List<Person> people) async {
    await _peopleService.addOrUpdatePeople(people);
    await loadPeople();
  }

  Future<void> deletePeopleByIds(Set<String> ids) async {
    await _peopleService.deletePeopleByIds(ids.toList());
    await ref.read(checkInProvider.notifier).loadCheckIns();
    await loadPeople();
  }
}
