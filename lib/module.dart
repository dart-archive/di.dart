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
  final Map<Type, _Provider> _providers = new HashMap<Type, _Provider>();
  final List<Module> _childModules = <Module>[];

  /**
   * Compiles and returs bindings map by performing depth-first traversal of the
   * child (installed) modules.
   */
  Map<Type, _Provider> get _bindings {
    Map<Type, _Provider> res = new HashMap<Type, _Provider>();
    _childModules.forEach((child) => res.addAll(child._bindings));
    res.addAll(_providers);
    return res;
  }

  /**
   * Register binding to a concrete value.
   *
   * The [value] is what actually will be injected.
   */
  void value(Type id, value,
      {CreationStrategy creation, Visibility visibility}) {
    _providers[id] = new _ValueProvider(value, creation, visibility);
  }

  /**
   * Register binding to a [Type].
   *
   * The [implementedBy] will be instantiated using [new] operator and the
   * resulting instance will be injected. If no type is provided, then it's
   * implied that [id] should be instantiated.
   */
  void type(Type id, {Type implementedBy, CreationStrategy creation,
      Visibility visibility}) {
    _providers[id] = new _TypeProvider(
        implementedBy == null ? id : implementedBy, creation, visibility);
  }

  /**
   * Register binding to a factory function.abstract
   *
   * The [factoryFn] will be called and all its arguments will get injected.
   * The result of that function is the value that will be injected.
   */
  void factory(Type id, FactoryFn factoryFn,
      {CreationStrategy creation, Visibility visibility}) {
    _providers[id] = new _FactoryProvider(factoryFn, creation, visibility);
  }

  /**
   * Installs another module into this module. Bindings defined on this module
   * take precidence over the installed module.
   */
  void install(Module module) => _childModules.add(module);
}

/** Deafault creation strategy is to instantiate on the defining injector. */
dynamic _defaultCreationStrategy(Injector requesting, Injector defining,
    dynamic factory()) => factory();

/** By default all values are visible to child injectors. */
bool _defaultVisibility(_, __) => true;


typedef Object ObjectFactory(Type type);

abstract class _Provider {
  final CreationStrategy creationStrategy;
  final Visibility visibility;

  _Provider(_creationStrategy, _visibility)
      : creationStrategy = _creationStrategy == null ?
            _defaultCreationStrategy : _creationStrategy,
        visibility = _visibility == null ?
            _defaultVisibility : _visibility;

  dynamic get(Injector injector, ObjectFactory getInstanceByType, error);
}

class _ValueProvider extends _Provider {
  dynamic value;

  _ValueProvider(this.value, [CreationStrategy creationStrategy,
                              Visibility visibility])
      : super(creationStrategy, visibility);

  dynamic get(Injector injector, getInstanceByType, error) {
    return value;
  }
}

class _TypeProvider extends _Provider {
  final Type type;

  _TypeProvider(Type this.type, [CreationStrategy creationStrategy,
                                 Visibility visibility])
      : super(creationStrategy, visibility);

  dynamic get(Injector injector, getInstanceByType, error) {
    return injector.newInstanceOf(type, getInstanceByType, error);
  }
}

class _FactoryProvider extends _Provider {
  final Function factoryFn;

  _FactoryProvider(Function this.factoryFn, [CreationStrategy creationStrategy,
                                             Visibility visibility])
      : super(creationStrategy, visibility);

  dynamic get(Injector injector, getInstanceByType, error) {
    return factoryFn(getInstanceByType(Injector));
  }
}
