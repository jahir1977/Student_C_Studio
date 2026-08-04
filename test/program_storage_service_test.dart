import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    final program = await storageService.createProgram(
      sourceCode: 'int main() { return 0; }',
    );

    expect(program.programNumber, 1);
    expect(program.displayName, 'Program 1');
    expect(program.sourceCode, contains('main'));

    final current = await storageService.loadCurrentProgram();

    expect(current?.id, program.id);
  });

  test('creates programs with increasing numbers', () async {
    final first = await storageService.createProgram();

    final second = await storageService.createProgram();

    final third = await storageService.createProgram();

    expect(first.programNumber, 1);
    expect(second.programNumber, 2);
    expect(third.programNumber, 3);
  });

  test('deleted program number is not reused', () async {
    final first = await storageService.createProgram();

    await storageService.createProgram();

    await storageService.deleteProgram(first);

    final third = await storageService.createProgram();

    expect(third.programNumber, 3);
  });

  test('loads programs in program-number order', () async {
    await storageService.createProgram();
    await storageService.createProgram();
    await storageService.createProgram();

    final programs = await storageService.loadPrograms();

    expect(
      programs.map((program) => program.programNumber),
      <int>[1, 2, 3],
    );
  });

  test('auto-save updates source code', () async {
    final program = await storageService.createProgram();

    final updated = await storageService.saveProgram(
      program,
      sourceCode: 'printf("Saved");',
    );

    final loaded = await storageService.loadProgramById(
      program.id,
    );

    expect(updated.sourceCode, 'printf("Saved");');
    expect(loaded?.sourceCode, 'printf("Saved");');
    expect(
      updated.updatedAt.isBefore(program.updatedAt),
      isFalse,
    );
  });

  test('deletes selected program', () async {
    final first = await storageService.createProgram();

    final second = await storageService.createProgram();

    await storageService.deleteProgram(first);

    final programs = await storageService.loadPrograms();

    expect(programs, hasLength(1));
    expect(programs.single.id, second.id);
  });

  test('deleting current program selects first remaining program', () async {
    final first = await storageService.createProgram();

    final second = await storageService.createProgram();

    await storageService.setCurrentProgram(first);
    await storageService.deleteProgram(first);

    final current = await storageService.loadCurrentProgram();

    expect(current?.id, second.id);
  });

  test('reports program count and limit state', () async {
    expect(await storageService.programCount(), 0);
    expect(await storageService.hasReachedLimit(), isFalse);

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
