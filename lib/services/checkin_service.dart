import '../core/supabase_client.dart';
import '../models/checkin.dart';
import '../models/person.dart';

class CheckInService {
  Future<List<CheckIn>> fetchCheckIns() async {
    final response = await SupabaseService.client
        .from('checkins')
        .select()
        .order('checked_in_at', ascending: false);
    return response.map((item) => CheckIn.fromMap(item)).toList();
  }

  Future<void> createCheckIn({
    required Person person,
    String notes = '',
  }) async {
    await SupabaseService.client.from('checkins').insert({
      'person_id': person.id,
      'first_name': person.firstName,
      'last_name': person.lastName,
      'checked_in_at': DateTime.now().toIso8601String(),
      'notes': notes,
    });
  }

  Future<void> deleteCheckInsByPersonIds(List<String> personIds) async {
    if (personIds.isEmpty) {
      return;
    }
    await SupabaseService.client
        .from('checkins')
        .delete()
        .inFilter('person_id', personIds);
  }
}
