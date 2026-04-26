import 'package:csv/csv.dart';

import '../models/person.dart';

class CsvParserService {
  List<Person> parsePeopleCsv(String rawCsv) {
    final rows = const CsvToListConverter(eol: '\n').convert(rawCsv);
    if (rows.isEmpty) {
      return <Person>[];
    }

    final header = rows.first.map((item) => item.toString().trim().toLowerCase()).toList();
    final firstNameIndex = header.indexOf('first_name');
    final lastNameIndex = header.indexOf('last_name');
    final idIndex = header.indexOf('id');

    if (firstNameIndex == -1 || lastNameIndex == -1) {
      return <Person>[];
    }

    return rows.skip(1).where((row) {
      return row.length > firstNameIndex && row.length > lastNameIndex;
    }).map((row) {
      final id = idIndex != -1 && row.length > idIndex
          ? row[idIndex].toString().trim()
          : '';
      return Person(
        id: id,
        firstName: row[firstNameIndex].toString().trim(),
        lastName: row[lastNameIndex].toString().trim(),
      );
    }).toList();
  }
}
