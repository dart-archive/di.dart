library di.dynamic_injector;

import 'dart:mirrors';

import 'errors.dart';
import 'injector.dart';
import 'module.dart';
import 'reflected_type.dart';

// A hack that tells us if we're running in dart2js.
bool isJs = 1.0 is int;

const List<Type> PRIMITIVE_TYPES = const <Type>[
  num, int, double, String, bool
];

/**
 * Dynamic implementation of [Injector] that uses mirrors.
 */
class DynamicInjector implements Injector {
  final bool allowImplicitInjection;
  final String name;

  final DynamicInjector parent;

  final Map<Type, _ProviderMetadata> providers =
      new Map<Type, _ProviderMetadata>();
  final Map<Type, Object> instances = new Map<Type, Object>();

  final List<Type> resolving = new List<Type>();

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
    if (binding is ValueBinding) {
      providers[type] = new _ProviderMetadata.forValue(binding);
    } else if (binding is TypeBinding) {
      providers[type] = new _ProviderMetadata.forTypeBinding(binding);
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

  dynamic _getInstanceByType(Type type, Injector requester) {
    _checkTypeConditions(type);

    if (resolving.contains(type)) {
      throw new CircularDependencyError(
          _error('Cannot resolve a circular dependency!', type));
    }

    var providerWithInjector = _getProviderForType(type);
    var metadata = providerWithInjector.providerMetadata;
    var visible =
        metadata.binding.visibility(requester, providerWithInjector.injector);

    if (visible && instances.containsKey(type)) {
      return instances[type];
    }

    if (providerWithInjector.injector != this || !visible) {
      var injector = providerWithInjector.injector;
      if (!visible) {
        injector = providerWithInjector.injector.parent.
            _getProviderForType(type).injector;
      }
      return injector._getInstanceByType(type, requester);
    }

    var getInstanceByType =
        _wrapGetInstanceByType(_getInstanceByType, requester);
    var value;
    try {
      value = metadata.binding.creationStrategy(requester,
          providerWithInjector.injector, () {
        resolving.add(type);
        var val = metadata.provider.get(getInstanceByType, _error);
        resolving.removeLast();
        return val;
      });
    } catch(e) {
      resolving.clear();
      rethrow;
    }

    // cache the value.
    providerWithInjector.injector.instances[type] = value;
    return value;
  }

  /**
   *  Wraps getInstanceByType function with a requester value to be easily
   *  down to the providers.
   */
  ObjectFactory _wrapGetInstanceByType(Function getInstanceByType,
                                    Injector requester) {
    return (Type type) {
      return getInstanceByType(type, requester);
    };
  }

  /// Returns a pair for provider and the injector where it's defined.
  _ProviderWithDefiningInjector _getProviderForType(Type type) {
    if (providers.containsKey(type)) {
      return new _ProviderWithDefiningInjector(providers[type], this);
    }

    if (parent != null) {
      return parent._getProviderForType(type);
    }

    if (!allowImplicitInjection) {
      throw new NoProviderError(_error('No provider found for $type!', type));
    }

    // create a provider for implicit types
    return new _ProviderWithDefiningInjector(
        new _ProviderMetadata.forType(type), this);
  }

  void _checkTypeConditions(Type type) {
    if (PRIMITIVE_TYPES.contains(type)) {
      throw new NoProviderError(_error('Cannot inject a primitive type '
          'of $type!', type));
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
  dynamic get(Type type) => _getInstanceByType(type, this);

  /**
   * Invoke given function and inject all its arguments.
   *
   * Returns whatever the function returns.
   */
  dynamic invoke(Function fn) {
    ClosureMirror cm = reflect(fn);
    MethodMirror mm = cm.function;
    int position = 0;
    List args = mm.parameters.map((ParameterMirror parameter) {
      if (parameter.type is ClassMirror) {
        ClassMirror parameterClass = parameter.type;
        try {
          return _getInstanceByType(
              getReflectedTypeWorkaround(parameterClass), this);
        } on NoProviderError catch (e) {
          throw new NoProviderError(e.message +
              (isJs ? '' : ' at position $position source:\n ${mm.source}.'));
        } finally {
          position++;
        }
      }
      throw new NoProviderError(
          'Parameter type ${parameter.type} is not a class!' +
          (isJs ? '' : ' at position $position source:\n ${mm.source}.'));
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
        var providerWithInjector = _getProviderForType(type);
        var metadata = providerWithInjector.providerMetadata;
        forceNew.factory(type,
            (DynamicInjector inj) => metadata.provider.get(
                _wrapGetInstanceByType(inj._getInstanceByType, inj),
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

typedef Object ObjectFactory(Type type);

abstract class _Provider {
  dynamic get(ObjectFactory getInstanceByType, error);
}

class _ValueProvider implements _Provider {
  dynamic value;

  _ValueProvider(this.value);

  dynamic get(getInstanceByType, error) => value;
}


class _TypeProvider implements _Provider {
  final ClassMirror classMirror;
  final Type type;

  _TypeProvider(Type type)
      : this.type = type,
        this.classMirror = reflectClass(type);

  dynamic get(getInstanceByType, error) {

    if (classMirror is TypedefMirror) {
      throw new NoProviderError(error('No implementation provided '
          'for ${classMirror.qualifiedName} typedef!'));
    }

    MethodMirror ctor = classMirror.declarations[classMirror.simpleName];

    resolveArgument(int pos) {
      ParameterMirror p = ctor.parameters[pos];
      if (p.type is ClassMirror) {
        ClassMirror parameterClass = p.type;
        try {
          return getInstanceByType(
              getReflectedTypeWorkaround(parameterClass));
        } on NoProviderError catch (e) {
          throw new NoProviderError(e.message +
              (isJs ? '' : ' at position $pos source:\n ${ctor.source}.'));
        }
      }
      throw new NoProviderError('Parameter type ${p.type} is not a class!' +
          (isJs ? '' : ' at position $pos source:\n ${ctor.source}.'));
    }

    var args = new List.generate(ctor.parameters.length, resolveArgument,
        growable: false);
    return classMirror.newInstance(ctor.constructorName, args).reflectee;
  }
}


class _FactoryProvider implements _Provider {
  final Function factoryFn;

  _FactoryProvider(this.factoryFn);

  dynamic get(getInstanceByType, error) {
    return Function.apply(factoryFn,
        [getInstanceByType(Injector)]);
  }
}

class _ProviderMetadata {
  final _Provider provider;
  final Binding binding;

  _ProviderMetadata.forValue(ValueBinding binding)
      : this.provider = new _ValueProvider(binding.value),
        this.binding = binding;

  _ProviderMetadata.forTypeBinding(TypeBinding binding)
      : this.provider = new _TypeProvider(binding.type),
        this.binding = binding;

  _ProviderMetadata.forType(Type type)
      : this.provider = new _TypeProvider(type),
        this.binding = new TypeBinding(type);

  _ProviderMetadata.forFactory(FactoryBinding binding)
      : provider = new _FactoryProvider(binding.factoryFn),
        this.binding = binding;
}
