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
typedef bool Visibility(Injector requesting, Injector defining);


/**
 * A collection of type bindings. Once the module is passed into the injector,
 * the injector created a copy of the module and all subsequent changes to the
 * module have no effect.
 */
class Module {
  Map<Symbol, _ProviderMetadata> _mappings =
      new HashMap<Symbol, _ProviderMetadata>();

  /**
   * Register binding to a concrete value.
   *
   * The [value] is what actually will be injected.
   */
  void value(Type id, value, {
      CreationStrategy creation, Visibility visibility}) {
    _mappings[getTypeSymbol(id)] =
        new _ProviderMetadata(new _ValueProvider(value),
            creation, visibility);
  }

  /**
   * Register binding to a [Type].
   *
   * The [type] will be instantiated using [new] operator and the resulting
   * instance will be injected.
   */
  void type(Type id, Type type, {
      CreationStrategy creation, Visibility visibility}) {
    _mappings[getTypeSymbol(id)] =
        new _ProviderMetadata(new _TypeProvider(getTypeSymbol(type)),
            creation, visibility);
  }

  /**
   * Register binding to a provider.
   *
   * The [provider] has to implement [get] method which returns the actual
   * value that will be injected.
   */
  void provider(Type id, Provider provider, {
      CreationStrategy creation, Visibility visibility}) {
    _mappings[getTypeSymbol(id)] =
        new _ProviderMetadata(provider, creation, visibility);
  }

  /**
   * Register binding to a factory function.abstract
   *
   * The [factoryFn] will be called and all its arguments will get injected.
   * The result of that function is the value that will be injected.
   */
  void factory(Type id, Function factoryFn, {
      CreationStrategy creation, Visibility visibility}) {
    _mappings[getTypeSymbol(id)] =
        new _ProviderMetadata(new _FactoryProvider(factoryFn),
                              creation, visibility);
  }

  // TODO(vojta): another hacky backdoor, clean this up
  void _symbolMetaProvider(Symbol id, _ProviderMetadata metaData) {
    _mappings[id] = metaData;
  }
}

/** Deafault creation strategy is to instantiate on the defining injector. */
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
