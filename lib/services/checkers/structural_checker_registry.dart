import 'brace_checker.dart';
import 'checker_registry.dart';
import 'function_checker.dart';
import 'header_checker.dart';
import 'identifier_checker_adapter.dart';
import 'parenthesis_checker.dart';
import 'quote_checker.dart';

final CheckerRegistry structuralCheckerRegistry = CheckerRegistry(
  checkers: [
    HeaderChecker(),
    QuoteChecker(),
    ParenthesisChecker(),
    BraceChecker(),
    FunctionChecker(),
    IdentifierCheckerAdapter(),
  ],
);
