import 'dart:math';

class PersonIdGenerator {
  PersonIdGenerator({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  String nextId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final randomPart = List.generate(
      8,
      (_) => _alphabet[_random.nextInt(_alphabet.length)],
    ).join();
    return 'person_$timestamp$randomPart';
  }

  static const String _alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
}
