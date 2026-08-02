import 'compiler_checker.dart';

class CheckerRegistry {
  final List<CompilerChecker> checkers;

  const CheckerRegistry({
    required this.checkers,
  });
}
