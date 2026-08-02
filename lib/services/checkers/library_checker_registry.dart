import 'checker_registry.dart';
import 'format_specifier_checker.dart';
import 'input_output_checker.dart';
import 'pointer_checker_adapter.dart';
import 'string_checker_adapter.dart';

final CheckerRegistry libraryCheckerRegistry = CheckerRegistry(
  checkers: [
    InputOutputChecker(),
    FormatSpecifierChecker(),
    StringCheckerAdapter(),
    PointerCheckerAdapter(),
  ],
);
