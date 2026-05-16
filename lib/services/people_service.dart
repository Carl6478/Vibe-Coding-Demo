import '../core/person_id_generator.dart';
import '../core/supabase_client.dart';
import '../models/person.dart';
import 'checkin_service.dart';

class PeopleService {
  PeopleService({
    CheckInService? checkInService,
    PersonIdGenerator? personIdGenerator,
  }) : _checkInService = checkInService ?? CheckInService(),
       _personIdGenerator = personIdGenerator ?? PersonIdGenerator();

  final CheckInService _checkInService;
  final PersonIdGenerator _personIdGenerator;

  Future<List<Person>> fetchPeople() async {
    final response = await SupabaseService.client
        .from('people')
        .select()
        .order('last_name');
    return response.map((item) => Person.fromMap(item)).toList();
  }

  Future<void> addOrUpdatePeople(List<Person> people) async {
    if (people.isEmpty) {
      return;
    }

    final withIds = people
        .where((person) => person.id.trim().isNotEmpty)
        .toList();
    final withoutIds = people
        .where((person) => person.id.trim().isEmpty)
        .toList();

    final client = SupabaseService.client;
    if (withIds.isNotEmpty) {
      await client
          .from('people')
          .upsert(withIds.map((person) => person.toInsertMap()).toList());
    }

    if (withoutIds.isNotEmpty) {
      final generatedPeople = withoutIds
          .map(
            (person) => Person(
              id: _personIdGenerator.nextId(),
              firstName: person.firstName,
              lastName: person.lastName,
            ),
          )
          .toList();
      await client
          .from('people')
          .insert(
            generatedPeople.map((person) => person.toInsertMap()).toList(),
          );
    }
  }

  Future<void> deletePeopleByIds(List<String> ids) async {
    if (ids.isEmpty) {
      return;
    }
    await _checkInService.deleteCheckInsByPersonIds(ids);
    await SupabaseService.client.from('people').delete().inFilter('id', ids);
  }
}
