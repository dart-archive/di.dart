library di.dynamic_injector;

import 'mirrors.dart';
import 'errors.dart';
import 'module.dart';
import 'injector.dart';

// A hack that tells us if we're running in dart2js.
bool isJs = 1.0 is int;

/**
 * Dynamic implementation of [Injector] that uses mirrors.
 */
class DynamicInjector implements Injector {
  final bool allowImplicitInjection;
  final String name;

  final DynamicInjector parent;

  final Map<Symbol, _ProviderMetadata> providers =
      new Map<Symbol, _ProviderMetadata>();
  final Map<Symbol, Object> instances = new Map<Symbol, Object>();

  final List<Symbol> resolving = new List<Symbol>();

  final List<Type> _types = [];

  DynamicInjector({List<Module> modules, String name,
                   bool allowImplicitInjection: false})
      : this._fromParent(modules, null, name: name,
                         allowImplicitInjection: allowImplicitInjection);

  DynamicInjector._fromParent(List<Module> modules, Injector this.parent,
      {bool this.allowImplicitInjection: false, this.name}) {
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
    var symbol = getTypeSymbol(type);
    if (binding is ValueBinding) {
      providers[symbol] = new _ProviderMetadata.forValue(binding);
    } else if (binding is TypeBinding) {
      providers[symbol] = new _ProviderMetadata.forType(binding);
    } else if (binding is FactoryBinding) {
      providers[symbol] = new _ProviderMetadata.forFactory(binding);
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

    String graph = resolving.map(getSymbolSimpleName).join(' -> ');

    resolving.clear();

    return '$message (resolving $graph)';
  }

  dynamic _getInstanceBySymbol(Symbol typeName, Injector requester) {
    _checkTypeConditions(typeName);

    if (resolving.contains(typeName)) {
      throw new CircularDependencyError(
          _error('Cannot resolve a circular dependency!', typeName));
    }

    var providerWithInjector = _getProviderForSymbol(typeName);
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
            _getProviderForSymbol(typeName).injector;
      }
      return injector._getInstanceBySymbol(typeName, requester);
    }

    var getInstanceBySymbol =
        _wrapGetInstanceBySymbol(_getInstanceBySymbol, requester);
    var value;
    try {
      value = metadata.binding.creationStrategy(requester,
          providerWithInjector.injector, () {
        resolving.add(typeName);
        var val = metadata.provider.get(getInstanceBySymbol, _error);
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
   *  Wraps getInstanceBySymbol function with a requster value to be easily
   *  down to the providers.
   */
  ObjectFactory _wrapGetInstanceBySymbol(Function getInstanceBySymbol,
                                    Injector requester) {
    return (Symbol typeName) {
      return getInstanceBySymbol(typeName, requester);
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
          '${getSymbolSimpleName(typeName)}!', typeName));
    }

    // create a provider for implicit types
    return new _ProviderWithDefiningInjector(
        new _ProviderMetadata.forSymbol(typeName), this);
  }

  void _checkTypeConditions(Symbol typeName) {
    if (PRIMITIVE_TYPES.contains(typeName)) {
      throw new NoProviderError(_error('Cannot inject a primitive type '
          'of ${getSymbolSimpleName(typeName)}!', typeName));
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
      _getInstanceBySymbol(getTypeSymbol(type), this);

  /**
   * Invoke given function and inject all its arguments.
   *
   * Returns whatever the function returns.
   */
  dynamic invoke(Function fn) {
    ClosureMirror cm = reflect(fn);
    MethodMirror mm = cm.function;
    num position = 0;
    List args = mm.parameters.map((ParameterMirror parameter) {
      try {
        return _getInstanceBySymbol(parameter.type.qualifiedName, this);
      } on NoProviderError catch (e) {
        throw new NoProviderError(e.message + (isJs ? '' : ' at position $position source:\n ${mm.source}.'));
      } finally {
        position++;
      }
    }).toList();

    return cm.apply(args, null).reflectee;
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
  Injector createChild(List<Module> modules,
                       {List<Type> forceNewInstances, String name}) {
    if (forceNewInstances != null) {
      Module forceNew = new Module();
      forceNewInstances.forEach((Type type) {
        var providerWithInjector = _getProviderForSymbol(getTypeSymbol(type));
        var metadata = providerWithInjector.providerMetadata;
        forceNew.factory(type,
            (DynamicInjector inj) => metadata.provider.get(
                _wrapGetInstanceBySymbol(inj._getInstanceBySymbol, inj),
                inj._error),
            creation: metadata.binding.creationStrategy,
            visibility: metadata.binding.visibility);
      });

      modules = modules.toList(); // clone
      modules.add(forceNew);
    }

    return new DynamicInjector._fromParent(modules, this, name: name);
  }
}

class _ProviderWithDefiningInjector {
  final _ProviderMetadata providerMetadata;
  final DynamicInjector injector;
  _ProviderWithDefiningInjector(this.providerMetadata, this.injector);
}

typedef Object ObjectFactory(Symbol symbol);

abstract class _Provider {
  dynamic get(ObjectFactory getInstanceBySymbol, error);
}

class _ValueProvider implements _Provider {
  dynamic value;

  _ValueProvider(value) {
    this.value = value;
  }

  dynamic get(getInstanceBySymbol, error) {
    return value;
  }
}


class _TypeProvider implements _Provider {
  final ClassMirror classMirror;
  final Symbol typeName;

  _TypeProvider(Symbol typeName)
      : this.typeName = typeName,
        this.classMirror = getClassMirrorBySymbol(typeName);

  dynamic get(getInstanceBySymbol, error) {

    if (classMirror is TypedefMirror) {
      throw new NoProviderError(error('No implementation provided '
          'for ${getSymbolName(classMirror.qualifiedName)} typedef!'));
    }

    MethodMirror ctor = classMirror.declarations[classMirror.simpleName];

    resolveArgument(int pos) {
      ParameterMirror p = ctor.parameters[pos];
      try {
        return getInstanceBySymbol(p.type.qualifiedName);
      } on NoProviderError catch (e) {
        throw new NoProviderError(e.message + (isJs ? '' : ' at position $pos source:\n ${ctor.source}.'));
      }
    }

    var args = new List.generate(ctor.parameters.length, resolveArgument,
        growable: false);
    return classMirror.newInstance(ctor.constructorName, args).reflectee;
  }
}


class _FactoryProvider implements _Provider {
  final Function factoryFn;

  _FactoryProvider(Function this.factoryFn);

  dynamic get(getInstanceBySymbol, error) {
    return Function.apply(factoryFn,
        [getInstanceBySymbol(getTypeSymbol(Injector))]);
  }
}

class _ProviderMetadata {
  _Provider provider;
  Binding binding;

  _ProviderMetadata.forValue(ValueBinding binding) {
    provider = new _ValueProvider(binding.value);
    this.binding = binding;
  }

  _ProviderMetadata.forType(TypeBinding binding) {
    provider = new _TypeProvider(getTypeSymbol(binding.type));
    this.binding = binding;
  }

  _ProviderMetadata.forSymbol(Symbol symbol) {
    provider = new _TypeProvider(symbol);
    this.binding = new TypeBinding(null);
  }

  _ProviderMetadata.forFactory(FactoryBinding binding) {
    provider = new _FactoryProvider(binding.factoryFn);
    this.binding = binding;
  }
}
