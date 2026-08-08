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
    List<SavedProgram> programs = await loadPrograms();

    if (programs.length >= maximumPrograms) {
      throw const ProgramStorageLimitException();
    }

    // পুরোনো data-তে কোনো numbering gap থাকলেও
    // নতুন Program তৈরির আগে 1, 2, 3... করে নেওয়া হবে।
    programs = _renumberPrograms(programs);

    final int programNumber = programs.length + 1;

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

    final SharedPreferences preferences = await SharedPreferences.getInstance();

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
    List<SavedProgram> programs = await loadPrograms();

    // কোনো পুরোনো numbering gap থাকলে এখানেও ঠিক করে নেওয়া হয়।
    programs = _renumberPrograms(programs);

    final int index = programs.indexWhere(
      (SavedProgram item) => item.id == program.id,
    );

    final DateTime now = DateTime.now();

    late final SavedProgram updated;

    if (index < 0) {
      if (programs.length >= maximumPrograms) {
        throw const ProgramStorageLimitException();
      }

      // Storage-এ program না থাকলে নতুন sequential number।
      updated = SavedProgram(
        id: program.id,
        programNumber: programs.length + 1,
        sourceCode: sourceCode,
        createdAt: program.createdAt,
        updatedAt: now,
      );

      programs.add(updated);
    } else {
      // খুব গুরুত্বপূর্ণ:
      // Editor-এর পুরোনো programNumber নয়,
      // storage-এর বর্তমান renumbered program ব্যবহার করা হবে।
      final SavedProgram storedProgram = programs[index];

      updated = storedProgram.copyWith(
        sourceCode: sourceCode,
        updatedAt: now,
      );

      programs[index] = updated;
    }

    await _savePrograms(programs);
    await setCurrentProgram(updated);

    return updated;
  }

  Future<void> deleteProgram(
    SavedProgram program,
  ) async {
    List<SavedProgram> programs = await loadPrograms();

    programs.removeWhere(
      (SavedProgram item) => item.id == program.id,
    );

    // Delete-এর পর:
    // Program 1, Program 3, Program 4
    // হয়ে যাবে:
    // Program 1, Program 2, Program 3
    programs = _renumberPrograms(programs);

    await _savePrograms(programs);

    final SharedPreferences preferences = await SharedPreferences.getInstance();

    final String? currentProgramId =
        preferences.getString(_currentProgramIdKey);

    if (currentProgramId != program.id) {
      return;
    }

    if (programs.isEmpty) {
      await preferences.remove(
        _currentProgramIdKey,
      );
      return;
    }

    await preferences.setString(
      _currentProgramIdKey,
      programs.first.id,
    );
  }

  List<SavedProgram> _renumberPrograms(
    List<SavedProgram> programs,
  ) {
    programs.sort(
      (SavedProgram first, SavedProgram second) {
        return first.programNumber.compareTo(
          second.programNumber,
        );
      },
    );

    final List<SavedProgram> renumberedPrograms = <SavedProgram>[];

    for (int i = 0; i < programs.length; i++) {
      final SavedProgram program = programs[i];

      renumberedPrograms.add(
        SavedProgram(
          id: program.id,
          programNumber: i + 1,
          sourceCode: program.sourceCode,
          createdAt: program.createdAt,
          updatedAt: program.updatedAt,
        ),
      );
    }

    return renumberedPrograms;
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
