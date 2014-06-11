part of di;

_DEFAULT_VALUE(_) => null;

typedef dynamic FactoryFn(Injector injector);

/**
 * If owned by a [Provider] P bound by the [defining] injector, then this
 * returns whether P is visible to the [requesting] injector.
 * See [Injector.get].
 */
typedef bool Visibility(Injector requesting, Injector defining);

/**
 * Produces an instance of some type, provided [factory] produces instances of
 * the dependencies that type.
 */
typedef Object TypeFactory(factory(Type type, Type annotation));

/**
 * Module contributes configuration information to an [Injector] by providing
 * a collection of type bindings that specify how each type is created.
 *
 * When an injector is created, it copies its configuration information from a
 * module. Defining additional type bindings after an injector is created has
 * no effect on that injector.
 */
class Module {
  final _providers = new HashMap<int, Provider>();
  final _childModules = <Module>[];
  Map<Type, TypeFactory> _typeFactories = new HashMap();

  Map<Type, TypeFactory> get typeFactories {
    if (_childModules.isEmpty) return _typeFactories;

    var factories = new HashMap.from(_typeFactories);
    _childModules.forEach((m) {
      if (m.typeFactories != null) {
        factories.addAll(m.typeFactories);
      }
    });
    return factories;
  }

  set typeFactories(Map<Type, TypeFactory> factories) {
    _typeFactories = factories;
  }

  void updateListWithBindings(List<Provider> providers) {
    _childModules.forEach((child) => child.updateListWithBindings(providers));
    _providers.forEach((k, v) {
      providers[k] = v;
    });
  }

  /**
   * Registers a binding for a given [type].
   *
   * The default behavior is to simply instantiate the type.
   *
   * The following parameters can be specified:
   *
   * * [toImplementation]: The given type will be instantiated using the [new]
   *   operator and the resulting instance will be injected.
   * * [toFactory]: The result of the factory function is the value that will
   *   be injected.
   * * [toValue]: The given value will be injected.
   * * [withAnnotation]: Type decorated with additional annotation.
   * * [visibility]: Function which determines if the requesting injector can
   *   see the type in the current injector.
   *
   * Up to one (0 or 1) of the following parameters can be specified at the
   * same time: [toImplementation], [toFactory], [toValue].
   */
  void bind(Type type, {dynamic toValue: _DEFAULT_VALUE,
      FactoryFn toFactory: _DEFAULT_VALUE, Type toImplementation,
      Type withAnnotation, Visibility visibility}) {
    bindByKey(new Key(type, withAnnotation), toValue: toValue,
        toFactory: toFactory, toImplementation: toImplementation,
        visibility: visibility);
  }

  /**
   * Same as [bind] except it takes [Key] instead of
   * [Type] [withAnnotation] combination.
   */
  void bindByKey(Key key, {dynamic toValue: _DEFAULT_VALUE,
      FactoryFn toFactory: _DEFAULT_VALUE, Type toImplementation,
      Visibility visibility}) {
    _checkBindArgs(toValue, toFactory, toImplementation);
    if (!identical(toValue, _DEFAULT_VALUE)) {
      _providers[key.id] = new ValueProvider(key.type, toValue, visibility);
    } else if (!identical(toFactory, _DEFAULT_VALUE)) {
      _providers[key.id] = new FactoryProvider(key.type, toFactory, visibility);
    } else {
      _providers[key.id] = new TypeProvider(
          toImplementation == null ? key.type : toImplementation, visibility);
    }
  }

  _checkBindArgs(toValue, toFactory, toImplementation) {
    int count = 0;
    if (!identical(toValue, _DEFAULT_VALUE)) count++;
    if (!identical(toFactory, _DEFAULT_VALUE)) count++;
    if (toImplementation != null) count++;
    if (count > 1) {
      throw 'Only one of following parameters can be specified: '
            'toValue, toFactory, toImplementation';
    }
    return true;
  }

  /**
   * Register a binding to a concrete value.
   *
   * The [value] is what actually will be injected.
   */
  @Deprecated("Use bind(type, toValue: value)")
  void value(Type id, value, {Type withAnnotation, Visibility visibility}) {
    bind(id, toValue: value, withAnnotation: withAnnotation,
        visibility: visibility);
  }

  /**
   * Registers a binding for a [Type].
   *
   * The default behavior is to simply instantiate the type.
   *
   * The following parameters can be specified:
   *
   * * [withAnnotation]: Type decorated with additional annotation.
   * * [implementedBy]: The type will be instantiated using the [new] operator
   *   and the resulting instance will be injected. If no type is provided,
   *   then it's implied that [type] should be instantiated.
   * * [visibility]: Function which determines fi the requesting injector can
   *   see the type in the current injector.
   */
  @Deprecated("Use bind(type, implementedBy: impl)")
  void type(Type type, {Type withAnnotation, Type implementedBy, Visibility visibility}) {
    bind(type, withAnnotation: withAnnotation, visibility: visibility,
        toImplementation: implementedBy);
  }

  /**
   * Register a binding to a factory function.
   *
   * The [factoryFn] will be called and the result of that function is the value
   * that will be injected.
   */
  @Deprecated("Use bind(type, toFactory: factory)")
  void factory(Type id, FactoryFn factoryFn, {Type withAnnotation,
      Visibility visibility}) {
    bind(id, withAnnotation: withAnnotation, visibility: visibility,
        toFactory: factoryFn);
  }

  @Deprecated("Use bindByKey(type, toFactory: factory)")
  void factoryByKey(Key key, FactoryFn factoryFn, {Visibility visibility}) {
    bindByKey(key, visibility: visibility, toFactory: factoryFn);
  }

  /**
   * Installs another module into this module. Bindings defined on this module
   * take precedence over the installed module.
   */
  void install(Module module) {
    _childModules.add(module);
  }
}
