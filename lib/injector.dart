part of di;

class Injector {

  /**
   * Name of the injector or null of none is given.
   */
  final String name;

  static const List<Type> _PRIMITIVE_TYPES = const <Type>[
    num, int, double, String, bool
  ];

  /**
   * Returns the parent injector or null if root.
   */
  final Injector parent;

  Injector _root;

  final Map<Type, _Provider> _providers =
      new Map<Type, _Provider>();
  final Map<Type, Object> instances = new Map<Type, Object>();

  final List<Type> resolving = new List<Type>();

  final bool allowImplicitInjection;

  /**
   * List of all types which the injector can return
   */
  final List<Type> _types = [];

  Injector({List<Module> modules, String name,
                  bool allowImplicitInjection: false})
      : this.fromParent(modules, null,
          name: name, allowImplicitInjection: allowImplicitInjection);

  Injector.fromParent(List<Module> modules,
      Injector this.parent, {this.name, this.allowImplicitInjection}) {
    if (parent == null) {
      _root = this;
    } else {
      _root = parent._root;
    }
    if (modules == null) {
      modules = <Module>[];
    }
    modules.forEach((module) {
      module._bindings.forEach(_registerBinding);
    });
    _registerBinding(Injector, new _ValueProvider(this));
  }

  _registerBinding(Type type, _Provider provider) {
    this._types.add(type);
    _providers[type] = provider;
  }

  Injector get root => _root;

  Set<Type> get types {
    var types = new Set.from(_types);
    var parent = this.parent;
    while (parent != null) {
      for(var type in parent._types) {
        if (!types.contains(type)) {
          types.add(type);
        }
      }
      parent = parent.parent;
    }
    return types;
  }

  String _error(message, [appendDependency]) {
    if (appendDependency != null) {
      resolving.add(appendDependency);
    }

    String graph = resolving.join(' -> ');

    resolving.clear();

    return '$message (resolving $graph)';
  }

  dynamic _getInstanceByType(Type typeName, Injector requester) {
    _checkTypeConditions(typeName);

    if (resolving.contains(typeName)) {
      throw new CircularDependencyError(
          _error('Cannot resolve a circular dependency!', typeName));
    }

    var providerWithInjector = _getProviderForType(typeName);
    var provider = providerWithInjector.provider;
    var visible = provider.visibility(requester, providerWithInjector.injector);

    if (visible && instances.containsKey(typeName)) {
      return instances[typeName];
    }

    if (providerWithInjector.injector != this || !visible) {
      var injector = providerWithInjector.injector;
      if (!visible) {
        injector = providerWithInjector.injector.parent.
            _getProviderForType(typeName).injector;
      }
      return injector._getInstanceByType(typeName, requester);
    }

    var getInstanceByType =
        _wrapGetInstanceByType(_getInstanceByType, requester);
    var value;
    try {
      value = provider.creationStrategy(requester,
          providerWithInjector.injector, () {
        resolving.add(typeName);
        var val = provider.get(this, getInstanceByType, _error);
        resolving.removeLast();
        return val;
      });
    } catch(e) {
      resolving.clear();
      rethrow;
    }

    // cache the value.
    providerWithInjector.injector.instances[typeName] = value;
    return value;
  }

  /**
   *  Wraps getInstanceByType function with a requster value to be easily
   *  down to the providers.
   */
  Function _wrapGetInstanceByType(Function getInstanceByType,
                                    Injector requester) {
    return (Type typeName) {
      return getInstanceByType(typeName, requester);
    };
  }

  /// Returns a pair for provider and the injector where it's defined.
  _ProviderWithDefiningInjector _getProviderForType(Type typeName) {
    if (_providers.containsKey(typeName)) {
      return new _ProviderWithDefiningInjector(_providers[typeName], this);
    }

    if (parent != null) {
      return parent._getProviderForType(typeName);
    }

    if (allowImplicitInjection) {
      return new _ProviderWithDefiningInjector(new _TypeProvider(typeName), this);
    }

    throw new NoProviderError(_error('No provider found for '
        '${typeName}!', typeName));
  }

  void _checkTypeConditions(Type typeName) {
    if (_PRIMITIVE_TYPES.contains(typeName)) {
      throw new NoProviderError(_error('Cannot inject a primitive type '
          'of $typeName!', typeName));
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
  dynamic get(Type type) =>
      _getInstanceByType(type, this);

  /**
   * Create a child injector.
   *
   * Child injector can override any bindings by adding additional modules.
   *
   * It also accepts a list of tokens that a new instance should be forced.
   * That means, even if some parent injector already has an instance for this
   * token, there will be a new instance created in the child injector.
   */
  Injector createChild(List<Module> modules,
                       {List<Type> forceNewInstances, String name}) {
    if (forceNewInstances != null) {
      Module forceNew = new Module();
      forceNewInstances.forEach((type) {
        var providerWithInjector = _getProviderForType(type);
        var provider = providerWithInjector.provider;
        forceNew.factory(type,
            (Injector inj) => provider.get(this,
                _wrapGetInstanceByType(inj._getInstanceByType, inj),
                inj._error),
            creation: provider.creationStrategy,
            visibility: provider.visibility);
      });

      modules = modules.toList(); // clone
      modules.add(forceNew);
    }

    return newFromParent(modules, name);
  }

  newFromParent(List<Module> modules, String name) {
    throw new UnimplementedError('This method must be overriden.');
  }

  Object newInstanceOf(Type type, ObjectFactory factory,
                       errorHandler(message, [appendDependency])) {
    throw new UnimplementedError('This method must be overriden.');
  }
}

class _ProviderWithDefiningInjector {
  final _Provider provider;
  final Injector injector;
  _ProviderWithDefiningInjector(this.provider, this.injector);
}
