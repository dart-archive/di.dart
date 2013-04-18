part of di;


class Module extends HashMap<String, Provider> {

  void value(Type id, value) {
    this[id.toString()] = new _ValueProvider(value);
  }

  void type(Type id, Type type) {
    this[id.toString()] = new _TypeProvider(type);
  }

  void provider(Type id, Provider provider) {
    this[id.toString()] = provider;
  }

  void factory(Type id, Function factoryFn) {
    this[id.toString()] = new _FactoryProvider(factoryFn);
  }
}