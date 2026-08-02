import 'checker_registry.dart';
import 'expression_checker.dart';
import 'if_checker.dart';
import 'loop_checker.dart';
import 'switch_checker.dart';
import 'while_checker.dart';

final CheckerRegistry statementCheckerRegistry = CheckerRegistry(
  checkers: [
    LoopChecker(),
    IfChecker(),
    SwitchChecker(),
    WhileChecker(),
    ExpressionChecker(),
  ],
);
