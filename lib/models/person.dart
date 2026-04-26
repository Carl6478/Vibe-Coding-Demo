class Person {
  const Person({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  final String id;
  final String firstName;
  final String lastName;

  String get fullName => '$firstName $lastName';

  factory Person.fromMap(Map<String, dynamic> map) {
    return Person(
      id: map['id'].toString(),
      firstName: map['first_name'] as String? ?? '',
      lastName: map['last_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
    };
  }

  Map<String, dynamic> toInsertMap() {
    final map = <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
    };
    if (id.trim().isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }
}
