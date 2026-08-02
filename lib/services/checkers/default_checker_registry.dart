import 'array_checker.dart';
import 'break_continue_checker.dart';
import 'checker_registry.dart';
import 'do_while_checker.dart';
import 'goto_checker.dart';

final CheckerRegistry defaultCheckerRegistry = CheckerRegistry(
  checkers: [
    DoWhileChecker(),
    BreakContinueChecker(),
    GotoChecker(),
    ArrayChecker(),
  ],
);
