import 'package:flutter_test/flutter_test.dart';
import 'package:reception_app/core/person_id_generator.dart';

void main() {
  test('generated person ids are prefixed and unique across a batch', () {
    final generator = PersonIdGenerator();
    final ids = List.generate(100, (_) => generator.nextId());

    expect(ids.every((id) => id.startsWith('person_')), isTrue);
    expect(ids.toSet(), hasLength(ids.length));
  });
}
