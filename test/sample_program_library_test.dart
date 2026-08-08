import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/data/sample_programs.dart';
import 'package:student_c_studio/models/sample_program.dart';

void main() {
  group('Sample program library', () {
    test('contains sample programs', () {
      expect(
        sampleProgramLibrary,
        isNotEmpty,
        reason: 'Sample program library must not be empty.',
      );
    });

    test('every sample has required information', () {
      for (final SampleProgram program in sampleProgramLibrary) {
        expect(
          program.id.trim(),
          isNotEmpty,
          reason: 'Sample program ID must not be empty.',
        );

        expect(
          program.titleBn.trim(),
          isNotEmpty,
          reason: 'Sample program title must not be empty.',
        );

        expect(
          program.topicTagBn.trim(),
          isNotEmpty,
          reason: 'Sample program topic must not be empty.',
        );

        expect(
          program.code.trim(),
          isNotEmpty,
          reason: '${program.id} must contain C source code.',
        );
      }
    });

    test('all sample IDs are unique', () {
      final List<String> ids = sampleProgramLibrary
          .map((SampleProgram program) => program.id)
          .toList();

      expect(
        ids.toSet().length,
        ids.length,
        reason: 'Every sample program must have a unique ID.',
      );
    });

    test('every sample contains a main function', () {
      for (final SampleProgram program in sampleProgramLibrary) {
        expect(
          program.code,
          contains('main()'),
          reason: '${program.id} must contain main().',
        );
      }
    });

    test('every sample starts with a C header', () {
      for (final SampleProgram program in sampleProgramLibrary) {
        expect(
          program.code.trimLeft(),
          startsWith('#include'),
          reason: '${program.id} must begin with a header.',
        );
      }
    });

    test('library contains Text Book programs', () {
      final Iterable<SampleProgram> programs = sampleProgramLibrary.where(
        (SampleProgram program) => program.category == ProgramCategory.textBook,
      );

      expect(
        programs,
        isNotEmpty,
        reason: 'Text Book category must contain at least one program.',
      );
    });

    test('library contains Board Question programs', () {
      final Iterable<SampleProgram> programs = sampleProgramLibrary.where(
        (SampleProgram program) =>
            program.category == ProgramCategory.boardQuestion,
      );

      expect(
        programs,
        isNotEmpty,
        reason: 'Board Question category must contain at least one program.',
      );
    });

    test('library contains Special Example programs', () {
      final Iterable<SampleProgram> programs = sampleProgramLibrary.where(
        (SampleProgram program) =>
            program.category == ProgramCategory.specialExample,
      );

      expect(
        programs,
        isNotEmpty,
        reason: 'Special Example category must contain at least one program.',
      );
    });

    test('every program belongs to a valid category', () {
      for (final SampleProgram program in sampleProgramLibrary) {
        expect(
          ProgramCategory.values,
          contains(program.category),
          reason: '${program.id} has an invalid category.',
        );
      }
    });

    test('library contains the expected topic groups', () {
      final Set<String> topics = sampleProgramLibrary
          .map((SampleProgram program) => program.topicTagBn)
          .toSet();

      expect(topics, contains('ভেরিয়েবল ও ডেটা টাইপ'));
      expect(topics, contains('গাণিতিক অপারেটর ও এক্সপ্রেশন'));
      expect(topics, contains('ইনপুট/আউটপুট (scanf/printf)'));
      expect(topics, contains('শর্ত নিয়ন্ত্রণ (if-else)'));
      expect(topics, contains('লুপ (while/do-while/for)'));
      expect(topics, contains('অ্যারে (Array)'));
      expect(topics, contains('স্ট্রিং (String)'));
      expect(topics, contains('ইউজার ডিফাইন্ড ফাংশন'));
      expect(topics, contains('সৃজনশীল প্রশ্ন সমাধান'));
    });

    test('user-defined function sample no longer shows warning text', () {
      final SampleProgram program = sampleProgramLibrary.firstWhere(
        (SampleProgram item) => item.id == 'p5_32_user_defined_function',
      );

      expect(
        program.titleBn,
        '৫.৩২ ইউজার ডিফাইন্ড ফাংশন',
      );

      expect(
        program.titleBn,
        isNot(contains('⚠️')),
      );
    });
  });
}
