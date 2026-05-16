import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reception_app/services/csv_parser.dart';

void main() {
  test('sample CSV file matches the people import format', () async {
    final csv = await File('sample_data/reception_people_import.csv').readAsString();
    final people = CsvParserService().parsePeopleCsv(csv);

    expect(people, hasLength(20));
    expect(people.first.id, 'person_lina_haddad');
    expect(people.first.firstName, 'Lina');
    expect(people.first.lastName, 'Haddad');
    expect(people.last.id, 'person_basel_farah');
    expect(people.last.firstName, 'Basel');
    expect(people.last.lastName, 'Farah');
    expect(people.every((person) => person.firstName.isNotEmpty), isTrue);
    expect(people.every((person) => person.lastName.isNotEmpty), isTrue);
  });
}
