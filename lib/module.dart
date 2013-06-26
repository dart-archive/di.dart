part of di;

typedef dynamic Factory();

/**
 * Creation strategy is asked to return an instance of the type after
 * [Injector.get] locates the defining injector that has no instance cached.
 * [directInstantation] is true when an instance is created directly from
 * [Injector.instantiate].
 */
typedef dynamic CreationStrategy(
  Symbol type,
  Injector requesting,
  Injector defining,
  bool directInstantation,
  Factory factory
);

/**
 * Visibility determines if the instance in the defining module is visible to
 * the requesting injector. If true is returned, then the instance from the
 * defining injector is provided. If false is returned, the injector keeps
 * walking up the tree to find another visible instance.
 */
typedef bool Visibility(
  Injector requesting,
  Injector defining
);


class Module {
  Map<Symbol, _ProviderMetadata> _mappings =
      new HashMap<Symbol, _ProviderMetadata>();

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

  void value(Type id, value, {
      CreationStrategy creation, Visibility visibility}) {
    _mappings[_idFromType(id)] =
        new _ProviderMetadata(new _ValueProvider(value),
            creation, visibility);
  }

  void type(Type id, Type type, {
      CreationStrategy creation, Visibility visibility}) {
    _mappings[_idFromType(id)] =
        new _ProviderMetadata(new _TypeProvider(_idFromType(type)),
            creation, visibility);
  }

  void provider(Type id, Provider provider, {
      CreationStrategy creation, Visibility visibility}) {
    _mappings[_idFromType(id)] =
        new _ProviderMetadata(provider, creation, visibility);
  }

  void factory(Type id, Function factoryFn, {
      CreationStrategy creation, Visibility visibility}) {
    _mappings[_idFromType(id)] =
        new _ProviderMetadata(new _FactoryProvider(factoryFn),
                              creation, visibility);
  }

  // TODO(vojta): another hacky backdoor, clean this up
  void symbolMetaProvider(Symbol id, _ProviderMetadata metaData) {
    _mappings[id] = metaData;
  }
}

/** Deafault create stratrategy is to instantiate on the defining injector. */
dynamic _defaultCreationStrategy(Symbol type, Injector requesting,
    Injector defining, bool direct, Factory factory) => factory();

/** By default all values are visible to child injectors. */
bool _defaultVisibility(_, __) => true;

class _ProviderMetadata {
  Provider provider;
  CreationStrategy creation;
  Visibility visibility;

  _ProviderMetadata(this.provider,
      [CreationStrategy this.creation, Visibility this.visibility]) {
    if (creation == null) {
      creation = _defaultCreationStrategy;
    }
    if (visibility == null) {
      visibility = _defaultVisibility;
    }
  }
}
