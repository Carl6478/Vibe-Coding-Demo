import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/checkin.dart';
import '../models/person.dart';
import '../services/checkin_service.dart';

final checkInServiceProvider =
    Provider<CheckInService>((ref) => CheckInService());

final checkedInIdsProvider = Provider<Set<String>>((ref) {
  final checkins = ref.watch(checkInProvider).value ?? <CheckIn>[];
  return checkins.map((item) => item.personId).toSet();
});

final checkInProvider =
    StateNotifierProvider<CheckInNotifier, AsyncValue<List<CheckIn>>>((ref) {
  return CheckInNotifier(ref.watch(checkInServiceProvider));
});

class CheckInNotifier extends StateNotifier<AsyncValue<List<CheckIn>>> {
  CheckInNotifier(this._checkInService) : super(const AsyncValue.loading()) {
    loadCheckIns();
  }

  final CheckInService _checkInService;

  Future<void> loadCheckIns() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_checkInService.fetchCheckIns);
  }

  Future<void> createCheckIn(Person person, {String notes = ''}) async {
    await _checkInService.createCheckIn(person: person, notes: notes);
    await loadCheckIns();
  }

  Future<void> checkOutPeopleByIds(List<String> personIds) async {
    await _checkInService.deleteCheckInsByPersonIds(personIds);
    await loadCheckIns();
  }
}
