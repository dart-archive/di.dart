library di.static_injector;

import 'errors.dart';
import 'module.dart';
import 'injector.dart';

typedef Object ObjectFactory(Type type);
typedef Object TypeFactory(ObjectFactory factory);


/**
 * Dynamic implementation of [Injector] that uses mirrors.
 */
class StaticInjector implements Injector {
  final String name;

  static const List<Type> _PRIMITIVE_TYPES = const <Type>[
    num, int, double, String, bool
  ];

  final StaticInjector parent;
  StaticInjector root;
  final Map<Type, TypeFactory> typeFactories;

  final Map<Type, _ProviderMetadata> providers =
      new Map<Type, _ProviderMetadata>();
  final Map<Type, Object> instances = new Map<Type, Object>();

  final List<Type> resolving = new List<Type>();

  final List<Type> _types = [];

  StaticInjector({List<Module> modules, String name,
                  bool allowImplicitInjection: false,
                  Map<Type, TypeFactory> typeFactories})
      : this._fromParent(modules, null, name: name, typeFactories: typeFactories);

  StaticInjector._fromParent(List<Module> modules,
      Injector this.parent, {this.name, this.typeFactories}) {
    if (parent == null) {
      root = this;
    } else {
      root = parent.root;
    }
    if (modules == null) {
      modules = <Module>[];
    }
    modules.forEach((module) {
      module.bindings.forEach(_registerBinding);
    });
    _registerBinding(Injector, new ValueBinding(this));
  }

  _registerBinding(Type type, Binding binding) {
    this._types.add(type);
    if (binding is ValueBinding) {
      providers[type] = new _ProviderMetadata.forValue(binding);
    } else if (binding is TypeBinding) {
      providers[type] = new _ProviderMetadata.forType(binding, this);
    } else if (binding is FactoryBinding) {
      providers[type] = new _ProviderMetadata.forFactory(binding);
    } else {
      throw 'Unknown binding type ${binding.runtimeType}';
    }
  }

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
    var metadata = providerWithInjector.providerMetadata;
    var visible =
        metadata.binding.visibility(requester, providerWithInjector.injector);

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
      value = metadata.binding.creationStrategy(requester,
          providerWithInjector.injector, () {
        resolving.add(typeName);
        var val = metadata.provider.get(getInstanceByType, _error);
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
    if (providers.containsKey(typeName)) {
      return new _ProviderWithDefiningInjector(providers[typeName], this);
    }

    if (parent != null) {
      return parent._getProviderForType(typeName);
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
        var metadata = providerWithInjector.providerMetadata;
        forceNew.factory(type,
            (StaticInjector inj) => metadata.provider.get(
                _wrapGetInstanceByType(inj._getInstanceByType, inj),
                inj._error),
            creation: metadata.binding.creationStrategy,
            visibility: metadata.binding.visibility);
      });

      modules = modules.toList(); // clone
      modules.add(forceNew);
    }

    return new StaticInjector._fromParent(modules, this, name: name);
  }
}

class _ProviderWithDefiningInjector {
  final _ProviderMetadata providerMetadata;
  final StaticInjector injector;
  _ProviderWithDefiningInjector(this.providerMetadata, this.injector);
}

abstract class _Provider {
  dynamic get(ObjectFactory getInstanceByType, error);
}

class _ValueProvider implements _Provider {
  dynamic value;

  _ValueProvider(value) {
    this.value = value;
  }

  dynamic get(getInstanceByType, error) {
    return value;
  }
}


class _TypeProvider implements _Provider {
  final Type type;
  StaticInjector injector;

  _TypeProvider(Type this.type, StaticInjector this.injector);

  dynamic get(getInstanceByType, error) {
    TypeFactory typeFactory = injector.root.typeFactories[type];
    if (typeFactory == null) {
      throw new NoProviderError(error('No type factory provided for '
          'for $type!'));
    }
    return typeFactory(getInstanceByType);
  }
}



class _FactoryProvider implements _Provider {
  final Function factoryFn;

  _FactoryProvider(Function this.factoryFn);

  dynamic get(getInstanceByType, error) {
    return Function.apply(factoryFn, [getInstanceByType(Injector)]);
  }
}

class _ProviderMetadata {
  _Provider provider;
  Binding binding;

  _ProviderMetadata.forValue(ValueBinding binding) {
    provider = new _ValueProvider(binding.value);
    this.binding = binding;
  }

  _ProviderMetadata.forType(TypeBinding binding, StaticInjector injector) {
    provider = new _TypeProvider(binding.type, injector);
    this.binding = binding;
  }

  _ProviderMetadata.forFactory(FactoryBinding binding) {
    provider = new _FactoryProvider(binding.factoryFn);
    this.binding = binding;
  }
}
