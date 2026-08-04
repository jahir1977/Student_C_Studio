import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/models/saved_program.dart';

void main() {
  test('creates display name from program number', () {
    final SavedProgram program = SavedProgram(
      id: 'program-7',
      programNumber: 7,
      sourceCode: 'int main() { return 0; }',
      createdAt: DateTime(2026, 8, 4, 10),
      updatedAt: DateTime(2026, 8, 4, 11),
    );

    expect(program.displayName, 'Program 7');
  });

  test('converts SavedProgram to and from JSON', () {
    final SavedProgram program = SavedProgram(
      id: 'program-12',
      programNumber: 12,
      sourceCode: 'printf("Hello");',
      createdAt: DateTime(2026, 8, 4, 10),
      updatedAt: DateTime(2026, 8, 4, 11),
    );

    final SavedProgram restored = SavedProgram.fromJson(
      program.toJson(),
    );

    expect(restored.id, program.id);
    expect(restored.programNumber, program.programNumber);
    expect(restored.sourceCode, program.sourceCode);
    expect(restored.createdAt, program.createdAt);
    expect(restored.updatedAt, program.updatedAt);
  });

  test('copyWith updates only supplied fields', () {
    final SavedProgram program = SavedProgram(
      id: 'program-3',
      programNumber: 3,
      sourceCode: 'old code',
      createdAt: DateTime(2026, 8, 4, 10),
      updatedAt: DateTime(2026, 8, 4, 11),
    );

    final SavedProgram updated = program.copyWith(
      sourceCode: 'new code',
      updatedAt: DateTime(2026, 8, 4, 12),
    );

    expect(updated.id, program.id);
    expect(updated.programNumber, 3);
    expect(updated.sourceCode, 'new code');
    expect(updated.createdAt, program.createdAt);
    expect(
      updated.updatedAt,
      DateTime(2026, 8, 4, 12),
    );
  });
}
