part of di;


class Module extends HashMap<Symbol, Provider> {

  static Map<Type, Symbol> _symbolNameCache = new Map<Type, Symbol>();

  Symbol _idFromType(Type type) {
    // A hack/workaround for reflectClass performance issue (dartbug.com/11108).
    var symbol = _symbolNameCache[type];
    if (symbol == null) {
      symbol = reflectClass(type).simpleName;
      _symbolNameCache[type] = symbol;
    }
    return symbol;
  }

  void value(Type id, value) {
    this[_idFromType(id)] = new _ValueProvider(value);
  }

  void type(Type id, Type type) {
    this[_idFromType(id)] = new _TypeProvider(type);
  }

  void provider(Type id, Provider provider) {
    this[_idFromType(id)] = provider;
  }

  void factory(Type id, Function factoryFn) {
    this[_idFromType(id)] = new _FactoryProvider(factoryFn);
  }
}