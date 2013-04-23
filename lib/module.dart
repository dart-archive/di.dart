part of di;


class Module extends HashMap<Symbol, Provider> {

  Symbol _idFromType(Type type) {
    return reflectClass(type).simpleName;
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