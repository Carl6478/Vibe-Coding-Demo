class CheckIn {
  const CheckIn({
    required this.id,
    required this.personId,
    required this.firstName,
    required this.lastName,
    required this.checkedInAt,
    this.notes = '',
  });

  final String id;
  final String personId;
  final String firstName;
  final String lastName;
  final DateTime checkedInAt;
  final String notes;

  String get fullName => '$firstName $lastName';

  factory CheckIn.fromMap(Map<String, dynamic> map) {
    return CheckIn(
      id: map['id'].toString(),
      personId: map['person_id'].toString(),
      firstName: map['first_name'] as String? ?? '',
      lastName: map['last_name'] as String? ?? '',
      checkedInAt:
          DateTime.tryParse(map['checked_in_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      notes: map['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'person_id': personId,
      'first_name': firstName,
      'last_name': lastName,
      'checked_in_at': checkedInAt.toIso8601String(),
      'notes': notes,
    };
  }
}
