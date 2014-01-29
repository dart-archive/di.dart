part of di;

typedef dynamic FactoryFn(Injector injector);

/**
 * Creation strategy is asked to return an instance of the type after
 * [Injector.get] locates the defining injector that has no instance cached.
 * [directInstantation] is true when an instance is created directly from
 * [Injector.instantiate].
 */
typedef dynamic CreationStrategy(
  Injector requesting,
  Injector defining,
  dynamic factory()
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
 * the injector creates a copy of the module and all subsequent changes to the
 * module have no effect.
 */
class Module {
  final Map<Key, _Provider> _providers = <Key, _Provider>{};
  final List<Module> _childModules = <Module>[];

  Map<Key, _Provider> _providersCache;

  /**
   * Compiles and returs bindings map by performing depth-first traversal of the
   * child (installed) modules.
   */
  Map<Key, _Provider> get _bindings {
    if (_isDirty) {
      _providersCache = <Key, _Provider>{};
      _childModules.forEach((child) => _providersCache.addAll(child._bindings));
      _providersCache.addAll(_providers);
    }
    return _providersCache;
  }

  /**
   * TODO Update docs
   *
   * Register binding to a [Type].
   *
   * The [implementedBy] will be instantiated using [new] operator and the
   * resulting instance will be injected. If no type is provided, then it's
   * implied that [id] should be instantiated.
   */
  void bind(Type type, {List<Type> withAnnotations, toValue, Type toType,
    FactoryFn toFactory, CreationStrategy creation, Visibility visibility}) {
    if ( [toType, toValue, toFactory].where((e) => e != null ).length > 1 )
      throw new InvalidBindingError('There has to be at most one element to '
          'which type is bound to.');
    _dirty();
    Key key = new Key(type, annotations: withAnnotations);
    if (toValue != null) {
      _providers[key] = new _ValueProvider(toValue, creation, visibility);
    } else {
      _providers[key] = new _TypeProvider(
          toType == null ? type : toType, creation, visibility);
    }
  }

  /**
   * Register binding to a factory function.abstract
   *
   * // TODO (@markovuksanovic) See what we can do with the factory.
   *
   * The [factoryFn] will be called and all its arguments will get injected.
   * The result of that function is the value that will be injected.
   */
  void factory(Type id, FactoryFn factoryFn,
      {CreationStrategy creation, Visibility visibility}) {
    _dirty();
    _providers[new Key(id)] = new _FactoryProvider(factoryFn, creation, visibility);
  }

  /**
   * Installs another module into this module. Bindings defined on this module
   * take precidence over the installed module.
   */
  void install(Module module) {
    _childModules.add(module);
    _dirty();
  }

  _dirty() {
    _providersCache = null;
  }

  bool get _isDirty =>
      _providersCache == null || _childModules.any((m) => m._isDirty);
}

/** Deafault creation strategy is to instantiate on the defining injector. */
dynamic _defaultCreationStrategy(Injector requesting, Injector defining,
    dynamic factory()) => factory();

/** By default all values are visible to child injectors. */
bool _defaultVisibility(_, __) => true;

typedef Object ObjectFactory(Key type, Injector requestor);

abstract class _Provider {
  final CreationStrategy creationStrategy;
  final Visibility visibility;

  _Provider(this.creationStrategy, this.visibility);

  dynamic get(Injector injector, Injector requestor, ObjectFactory getInstanceByKey, error);
}

class _ValueProvider extends _Provider {
  dynamic value;

  _ValueProvider(this.value, [CreationStrategy creationStrategy,
                              Visibility visibility])
      : super(creationStrategy, visibility);

  dynamic get(Injector injector, Injector requestor, ObjectFactory getInstanceByKey, error) =>
      value;
}

class _TypeProvider extends _Provider {
  final Type type;

  _TypeProvider(this.type, [CreationStrategy creationStrategy,
                            Visibility visibility])
      : super(creationStrategy, visibility);

  dynamic get(Injector injector, Injector requestor, ObjectFactory getInstanceByKey, error) =>
      injector.newInstanceOf(type, getInstanceByKey, requestor, error);

}

class _FactoryProvider extends _Provider {
  final Function factoryFn;

  _FactoryProvider(this.factoryFn, [CreationStrategy creationStrategy,
                                    Visibility visibility])
      : super(creationStrategy, visibility);

  dynamic get(Injector injector, Injector requestor, ObjectFactory getInstanceByKey, error) =>
      factoryFn(injector);
}
