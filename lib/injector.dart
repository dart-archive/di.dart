part of di;

class Injector {
  final bool allowImplicitInjection;

  static const List<Symbol> _PRIMITIVE_TYPES = const <Symbol>[
    const Symbol('dynamic'), const Symbol('num'), const Symbol('int'),
    const Symbol('double'), const Symbol('String'), const Symbol('bool')
  ];

  final Injector parent;

  final Map<Symbol, _ProviderMetadata> providers =
      new Map<Symbol, _ProviderMetadata>();
  final Map<Symbol, Object> instances = new Map<Symbol, Object>();

  final List<Symbol> resolving = new List<Symbol>();

  Injector([List<Module> modules, bool allowImplicitInjection = true])
      : this._fromParent(modules, null,
                         allowImplicitInjection: allowImplicitInjection);

  Injector._fromParent(List<Module> modules, Injector this.parent,
      {bool this.allowImplicitInjection: true}) {
    if (modules == null) {
      modules = <Module>[];
    }
    modules.forEach((module) {
      providers.addAll(module._mappings);
    });
    Module injectorModule = new Module();
    injectorModule.value(Injector, this);
    providers.addAll(injectorModule._mappings);
  }

  String _error(message, [appendDependency]) {
    if (appendDependency != null) {
      resolving.add(appendDependency);
    }

    String graph = resolving.map(getSymbolName).join(' -> ');

    resolving.clear();

    return '$message (resolving $graph)';
  }

  dynamic _getInstanceBySymbol(Symbol typeName, {bool cache: true,
      bool direct: false, Map<Type, dynamic> locals, getInstanceBySymbol,
      Injector requester}) {
    _checkTypeConditions(typeName);

    if (resolving.contains(typeName)) {
      throw new CircularDependencyError(
          _error('Cannot resolve a circular dependency!', typeName));
    }

    // TODO(pavelgj): Think of a simpler way.
    if (!direct) {
      getInstanceBySymbol =
          _wrapGetInstanceBySymbol(_getInstanceBySymbol, requester);
    }

    var providerWithInjector = _getProviderForSymbol(typeName);
    var metadata = providerWithInjector.provider;
    var visible = metadata.visibility(requester, providerWithInjector.injector);

    if (visible && instances.containsKey(typeName)) {
      return instances[typeName];
    }

    if (providerWithInjector.injector != this || !visible) {
      var injector = providerWithInjector.injector;
      if (!visible) {
        injector = providerWithInjector.injector.parent.
            _getProviderForSymbol(typeName).injector;
      }
      return injector._getInstanceBySymbol(typeName, cache: cache,
          direct: direct, getInstanceBySymbol: getInstanceBySymbol,
          requester: requester);
    }

    var value;
    try {
      value = metadata.creation(typeName, requester,
          providerWithInjector.injector, direct, () {
        resolving.add(typeName);
        var val = metadata.provider.get(getInstanceBySymbol, _error);
        resolving.removeLast();
        return val;
      });
    } catch(e) {
      resolving.clear();
      throw;
    }
    if (cache) {
      providerWithInjector.injector.instances[typeName] = value;
    }
    return value;
  }

  /**
   *  Wraps getInstanceBySymbol function with a requster value to be easily
   *  down to the providers.
   */
  Function _wrapGetInstanceBySymbol(Function getInstanceBySymbol,
                                    Injector requster) {
    return (Symbol typeName) {
      return getInstanceBySymbol(typeName, requester: requster);
    };
  }

  /// Returns a pair for provider and the injector where it's defined.
  _ProviderWithDefiningInjector _getProviderForSymbol(Symbol typeName) {
    if (providers.containsKey(typeName)) {
      return new _ProviderWithDefiningInjector(providers[typeName], this);
    }

    if (parent != null) {
      return parent._getProviderForSymbol(typeName);
    }

    if (!allowImplicitInjection) {
      throw new NoProviderError(_error('No provider found for '
          '${getSymbolName(typeName)}!', typeName));
    }

    // create a provider for implicit types
    return new _ProviderWithDefiningInjector(
        new _ProviderMetadata(new _TypeProvider(typeName)), this);
  }

  void _checkTypeConditions(Symbol typeName) {
    if (_PRIMITIVE_TYPES.contains(typeName)) {
      throw new NoProviderError(_error('Cannot inject a primitive type '
          'of ${getSymbolName(typeName)}!', typeName));
    }
  }


  // PUBLIC API

  /**
   * Get an instance for given token ([Type]).
   *
   * If the injector already has an instance for this token, it returns this
   * instance. Otherwise, injector resolves all its dependencies, instantiate
   * new instance and returns this instance.
   *
   * If there is no binding for given token, injector asks parent injector.
   *
   * If there is no parent injector, an implicit binding is used. That is,
   * the token ([Type]) is instantiated.
   */
  dynamic get(Type type) {
    return _getInstanceBySymbol(getTypeSymbol(type), requester: this);
  }

  /**
   * Get an instance for given token ([Symbol]).
   *
   * See [Injector.get] for more.
   */
  dynamic getBySymbol(Symbol symbol) => _getInstanceBySymbol(symbol);

  /**
   * Create an instance for given token ([Type]).
   *
   * This method behaves similarly to [Injector.get], but it ALWAYS creates
   * a new instance, which is not cached.
   *
   * It also allows passing map of locals to override any bindings.
   */
  dynamic instantiate(Type type, [Map<Type, dynamic> locals]) {
    Injector injector = this;

    if (locals != null && locals.isNotEmpty) {
      Module localsModule = new Module();
      for (Type key in locals.keys) {
        localsModule.value(key, locals[key]);
      }
      injector = createChild([localsModule]);
    }
    var symbol = getTypeSymbol(type);
    var wrappedGetInstance =
        _wrapGetInstanceBySymbol(injector._getInstanceBySymbol, this);
    var value = injector._getInstanceBySymbol(symbol, cache: false,
        direct: true,
        getInstanceBySymbol: wrappedGetInstance,
        requester: this);
    instances[symbol] = value;
    return value;
  }

  /**
   * Invoke given function and inject all its arguments.
   *
   * Returns whatever the function returns.
   */
  dynamic invoke(Function fn) {
    ClosureMirror cm = reflect(fn);
    MethodMirror mm = cm.function;
    List args = mm.parameters.map((ParameterMirror parameter) {
      return _getInstanceBySymbol(parameter.type.simpleName);
    }).toList();

    try {
      return cm.apply(args, null).reflectee;
    } catch (e) {
      if (e is MirroredUncaughtExceptionError) {
        throw "${e}\nORIGINAL STACKTRACE\n${e.stacktrace}";
      }
      throw;
    }

  }

  /**
   * Create a child injector.
   *
   * Child injector can override any bindings by adding additional modules.
   *
   * It also accepts a list of tokens that a new instance should be forced.
   * That means, even if some parent injector already has an instance for this
   * token, there will be a new instance created in the child injector.
   */
  // TODO(vojta): fix this hackery of passing list of Symbol or Type
  Injector createChild(List<Module> modules,
      [List<dynamic> forceNewInstances]) {
    if (forceNewInstances != null) {
      Module forceNew = new Module();
      forceNewInstances.forEach((typeOrSymbol) {
        if (typeOrSymbol is Type) {
          typeOrSymbol = getTypeSymbol(typeOrSymbol);
        }

        forceNew._symbolMetaProvider(typeOrSymbol,
            _getProviderForSymbol(typeOrSymbol).provider);
      });

      modules = modules.toList(); // clone
      modules.add(forceNew);
    }

    return new Injector._fromParent(modules, this);
  }
}

class _ProviderWithDefiningInjector {
  final _ProviderMetadata provider;
  final Injector injector;
  _ProviderWithDefiningInjector(this.provider, this.injector);
}
