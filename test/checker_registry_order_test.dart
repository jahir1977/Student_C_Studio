import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/array_checker.dart';
import 'package:student_c_studio/services/checkers/brace_checker.dart';
import 'package:student_c_studio/services/checkers/break_continue_checker.dart';
import 'package:student_c_studio/services/checkers/default_checker_registry.dart';
import 'package:student_c_studio/services/checkers/do_while_checker.dart';
import 'package:student_c_studio/services/checkers/expression_checker.dart';
import 'package:student_c_studio/services/checkers/format_specifier_checker.dart';
import 'package:student_c_studio/services/checkers/function_checker.dart';
import 'package:student_c_studio/services/checkers/goto_checker.dart';
import 'package:student_c_studio/services/checkers/header_checker.dart';
import 'package:student_c_studio/services/checkers/identifier_checker_adapter.dart';
import 'package:student_c_studio/services/checkers/if_checker.dart';
import 'package:student_c_studio/services/checkers/input_output_checker.dart';
import 'package:student_c_studio/services/checkers/library_checker_registry.dart';
import 'package:student_c_studio/services/checkers/loop_checker.dart';
import 'package:student_c_studio/services/checkers/parenthesis_checker.dart';
import 'package:student_c_studio/services/checkers/pointer_checker_adapter.dart';
import 'package:student_c_studio/services/checkers/quote_checker.dart';
import 'package:student_c_studio/services/checkers/statement_checker_registry.dart';
import 'package:student_c_studio/services/checkers/string_checker_adapter.dart';
import 'package:student_c_studio/services/checkers/structural_checker_registry.dart';
import 'package:student_c_studio/services/checkers/switch_checker.dart';
import 'package:student_c_studio/services/checkers/while_checker.dart';

void main() {
  group('Checker registry execution order', () {
    test('early registry preserves stable order', () {
      final checkers = defaultCheckerRegistry.checkers;

      expect(checkers.length, 4);
      expect(checkers[0], isA<DoWhileChecker>());
      expect(checkers[1], isA<BreakContinueChecker>());
      expect(checkers[2], isA<GotoChecker>());
      expect(checkers[3], isA<ArrayChecker>());
    });

    test('statement registry preserves stable order', () {
      final checkers = statementCheckerRegistry.checkers;

      expect(checkers.length, 5);
      expect(checkers[0], isA<LoopChecker>());
      expect(checkers[1], isA<IfChecker>());
      expect(checkers[2], isA<SwitchChecker>());
      expect(checkers[3], isA<WhileChecker>());
      expect(checkers[4], isA<ExpressionChecker>());
    });

    test('structural registry preserves stable order', () {
      final checkers = structuralCheckerRegistry.checkers;

      expect(checkers.length, 6);
      expect(checkers[0], isA<HeaderChecker>());
      expect(checkers[1], isA<QuoteChecker>());
      expect(checkers[2], isA<ParenthesisChecker>());
      expect(checkers[3], isA<BraceChecker>());
      expect(checkers[4], isA<FunctionChecker>());
      expect(checkers[5], isA<IdentifierCheckerAdapter>());
    });

    test('library registry preserves stable order', () {
      final checkers = libraryCheckerRegistry.checkers;

      expect(checkers.length, 4);
      expect(checkers[0], isA<InputOutputChecker>());
      expect(checkers[1], isA<FormatSpecifierChecker>());
      expect(checkers[2], isA<StringCheckerAdapter>());
      expect(checkers[3], isA<PointerCheckerAdapter>());
    });
  });
}
