import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_c_studio/models/saved_program.dart';
import 'package:student_c_studio/services/program_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const ProgramStorageService storageService = ProgramStorageService();

  setUp(() {
    SharedPreferences.setMockInitialValues(
      <String, Object>{},
    );
  });

  test('creates Program 1 and makes it current', () async {
    final SavedProgram program = await storageService.createProgram(
      sourceCode: 'int main() { return 0; }',
    );

    expect(program.programNumber, 1);
    expect(program.displayName, 'Program 1');
    expect(program.sourceCode, contains('main'));

    final SavedProgram? current = await storageService.loadCurrentProgram();

    expect(current?.id, program.id);
  });

  test('creates programs with increasing numbers', () async {
    final SavedProgram first = await storageService.createProgram();

    final SavedProgram second = await storageService.createProgram();

    final SavedProgram third = await storageService.createProgram();

    expect(first.programNumber, 1);
    expect(second.programNumber, 2);
    expect(third.programNumber, 3);
  });

  test(
    'deleted program numbers are renumbered sequentially',
    () async {
      final SavedProgram first = await storageService.createProgram();

      final SavedProgram second = await storageService.createProgram();

      final SavedProgram third = await storageService.createProgram();

      await storageService.deleteProgram(second);

      final List<SavedProgram> remaining = await storageService.loadPrograms();

      expect(remaining, hasLength(2));

      expect(remaining[0].id, first.id);
      expect(remaining[0].programNumber, 1);

      expect(remaining[1].id, third.id);
      expect(remaining[1].programNumber, 2);

      final SavedProgram newProgram = await storageService.createProgram();

      expect(newProgram.programNumber, 3);
    },
  );

  test(
    'program numbering restarts from 1 after deleting all programs',
    () async {
      final SavedProgram first = await storageService.createProgram();

      final SavedProgram second = await storageService.createProgram();

      await storageService.deleteProgram(first);
      await storageService.deleteProgram(second);

      final List<SavedProgram> remaining = await storageService.loadPrograms();

      expect(remaining, isEmpty);

      final SavedProgram newProgram = await storageService.createProgram();

      expect(newProgram.programNumber, 1);
      expect(newProgram.displayName, 'Program 1');
    },
  );

  test('loads programs in program-number order', () async {
    await storageService.createProgram();
    await storageService.createProgram();
    await storageService.createProgram();

    final List<SavedProgram> programs = await storageService.loadPrograms();

    expect(
      programs.map(
        (SavedProgram program) => program.programNumber,
      ),
      <int>[1, 2, 3],
    );
  });

  test('auto-save updates source code', () async {
    final SavedProgram program = await storageService.createProgram();

    final SavedProgram updated = await storageService.saveProgram(
      program,
      sourceCode: 'printf("Saved");',
    );

    final SavedProgram? loaded = await storageService.loadProgramById(
      program.id,
    );

    expect(
      updated.sourceCode,
      'printf("Saved");',
    );

    expect(
      loaded?.sourceCode,
      'printf("Saved");',
    );

    expect(
      updated.updatedAt.isBefore(
        program.updatedAt,
      ),
      isFalse,
    );
  });

  test('deletes selected program', () async {
    final SavedProgram first = await storageService.createProgram();

    final SavedProgram second = await storageService.createProgram();

    await storageService.deleteProgram(first);

    final List<SavedProgram> programs = await storageService.loadPrograms();

    expect(programs, hasLength(1));
    expect(programs.single.id, second.id);
    expect(programs.single.programNumber, 1);
  });

  test(
    'deleting current program selects first remaining program',
    () async {
      final SavedProgram first = await storageService.createProgram();

      final SavedProgram second = await storageService.createProgram();

      await storageService.setCurrentProgram(first);
      await storageService.deleteProgram(first);

      final SavedProgram? current = await storageService.loadCurrentProgram();

      expect(current?.id, second.id);
      expect(current?.programNumber, 1);
    },
  );

  test('reports program count and limit state', () async {
    expect(
      await storageService.programCount(),
      0,
    );

    expect(
      await storageService.hasReachedLimit(),
      isFalse,
    );

    for (int index = 0;
        index < ProgramStorageService.maximumPrograms;
        index++) {
      await storageService.createProgram();
    }

    expect(
      await storageService.programCount(),
      ProgramStorageService.maximumPrograms,
    );

    expect(
      await storageService.hasReachedLimit(),
      isTrue,
    );
  });

  test('rejects program 101', () async {
    for (int index = 0;
        index < ProgramStorageService.maximumPrograms;
        index++) {
      await storageService.createProgram();
    }

    expect(
      storageService.createProgram(),
      throwsA(
        isA<ProgramStorageLimitException>(),
      ),
    );
  });
}
