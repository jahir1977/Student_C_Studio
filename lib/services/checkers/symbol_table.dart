import '../models/symbol.dart';

class SymbolTable {

  final Map<String, SymbolInfo> _symbols = {};

  bool contains(String name) {
    return _symbols.containsKey(name);
  }

  SymbolInfo? get(String name) {
    return _symbols[name];
  }

  void add(SymbolInfo symbol) {
    _symbols[symbol.name] = symbol;
  }

  List<SymbolInfo> get all =>
      _symbols.values.toList();
}