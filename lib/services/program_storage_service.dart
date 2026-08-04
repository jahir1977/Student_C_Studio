import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_program.dart';

class ProgramStorageLimitException implements Exception {
  const ProgramStorageLimitException();

  @override
  String toString() {
    return 'Maximum 100 programs reached.';
  }
}

class ProgramStorageService {
  const ProgramStorageService();

  static const int maximumPrograms = 100;

  static const String _programsKey = 'student_c_studio.saved_programs.v1';

  static const String _currentProgramIdKey =
      'student_c_studio.current_program_id.v1';

  static const String _nextProgramNumberKey =
      'student_c_studio.next_program_number.v1';

  Future<List<SavedProgram>> loadPrograms() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    final String? encodedPrograms = preferences.getString(_programsKey);

    if (encodedPrograms == null || encodedPrograms.trim().isEmpty) {
      return <SavedProgram>[];
    }

    try {
      final Object? decoded = jsonDecode(encodedPrograms);

      if (decoded is! List<Object?>) {
        return <SavedProgram>[];
      }

      final List<SavedProgram> programs = <SavedProgram>[];

      for (final Object? item in decoded) {
        if (item is! Map<Object?, Object?>) {
          continue;
        }

        final Map<String, Object?> json = <String, Object?>{};

        for (final MapEntry<Object?, Object?> entry in item.entries) {
          json[entry.key.toString()] = entry.value;
        }

        final SavedProgram program = SavedProgram.fromJson(json);

        if (program.id.isEmpty || program.programNumber <= 0) {
          continue;
        }

        programs.add(program);
      }

      programs.sort(
        (SavedProgram first, SavedProgram second) {
          return first.programNumber.compareTo(
            second.programNumber,
          );
        },
      );

      return programs;
    } on FormatException {
      return <SavedProgram>[];
    }
  }

  Future<int> programCount() async {
    final List<SavedProgram> programs = await loadPrograms();

    return programs.length;
  }

  Future<bool> hasReachedLimit() async {
    return await programCount() >= maximumPrograms;
  }

  Future<SavedProgram> createProgram({
    String sourceCode = '',
  }) async {
    final List<SavedProgram> programs = await loadPrograms();

    if (programs.length >= maximumPrograms) {
      throw const ProgramStorageLimitException();
    }

    final SharedPreferences preferences = await SharedPreferences.getInstance();

    final int programNumber = preferences.getInt(_nextProgramNumberKey) ?? 1;

    final DateTime now = DateTime.now();

    final SavedProgram program = SavedProgram(
      id: 'program-$programNumber-${now.microsecondsSinceEpoch}',
      programNumber: programNumber,
      sourceCode: sourceCode,
      createdAt: now,
      updatedAt: now,
    );

    programs.add(program);

    await _savePrograms(programs);

    await preferences.setInt(
      _nextProgramNumberKey,
      programNumber + 1,
    );

    await preferences.setString(
      _currentProgramIdKey,
      program.id,
    );

    return program;
  }

  Future<SavedProgram?> loadProgramById(
    String id,
  ) async {
    final List<SavedProgram> programs = await loadPrograms();

    for (final SavedProgram program in programs) {
      if (program.id == id) {
        return program;
      }
    }

    return null;
  }

  Future<SavedProgram?> loadCurrentProgram() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    final String? currentProgramId =
        preferences.getString(_currentProgramIdKey);

    if (currentProgramId == null || currentProgramId.isEmpty) {
      return null;
    }

    return loadProgramById(currentProgramId);
  }

  Future<void> setCurrentProgram(
    SavedProgram program,
  ) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _currentProgramIdKey,
      program.id,
    );
  }

  Future<SavedProgram> saveProgram(
    SavedProgram program, {
    required String sourceCode,
  }) async {
    final List<SavedProgram> programs = await loadPrograms();

    final int index = programs.indexWhere(
      (SavedProgram item) => item.id == program.id,
    );

    final SavedProgram updated = program.copyWith(
      sourceCode: sourceCode,
      updatedAt: DateTime.now(),
    );

    if (index < 0) {
      if (programs.length >= maximumPrograms) {
        throw const ProgramStorageLimitException();
      }

      programs.add(updated);
    } else {
      programs[index] = updated;
    }

    await _savePrograms(programs);
    await setCurrentProgram(updated);

    return updated;
  }

  Future<void> deleteProgram(
    SavedProgram program,
  ) async {
    final List<SavedProgram> programs = await loadPrograms();

    programs.removeWhere(
      (SavedProgram item) => item.id == program.id,
    );

    await _savePrograms(programs);

    final SharedPreferences preferences = await SharedPreferences.getInstance();

    final String? currentProgramId =
        preferences.getString(_currentProgramIdKey);

    if (currentProgramId != program.id) {
      return;
    }

    if (programs.isEmpty) {
      await preferences.remove(_currentProgramIdKey);
      return;
    }

    await preferences.setString(
      _currentProgramIdKey,
      programs.first.id,
    );
  }

  Future<void> _savePrograms(
    List<SavedProgram> programs,
  ) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    programs.sort(
      (SavedProgram first, SavedProgram second) {
        return first.programNumber.compareTo(
          second.programNumber,
        );
      },
    );

    final String encodedPrograms = jsonEncode(
      programs
          .map(
            (SavedProgram program) => program.toJson(),
          )
          .toList(),
    );

    await preferences.setString(
      _programsKey,
      encodedPrograms,
    );
  }
}
