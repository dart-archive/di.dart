library di.injector;

import '../key.dart';
import 'module.dart';
import 'errors.dart';

final Key _INJECTOR_KEY = new Key(Injector);
class _Instance {
  final String name;

  static const _Instance EMPTY = const _Instance("EMPTY");
  static const _Instance CREATING = const _Instance("CREATING");

  const _Instance(this.name);
  String toString() => name;
}

abstract class Injector {

  final Injector parent = null;

  /**
   * Returns the instance associated with the given key (i.e. [type] and
   * [annotation]) according to the following rules.
   *
   * Let I be the nearest ancestor injector (possibly this one)
   * that has either a cached instance or a binding for [key]
   *
   * If there is no such I, then throw
   *   [NoProviderError].
   *
   * Once I is found, if I already created an instance for the key,
   * it is returned.  Otherwise, the typeFactory of the binding is
   * used to create an instance, using I as to resolve the dependencies.
   */
  dynamic get(Type type, [Type annotation]) =>
      getByKey(new Key(type, annotation));

  /**
   * Faster version of [get] by saving key creation time. Should be used instead if
   * a key instance is already available.
   */
  dynamic getByKey(Key key);

  /**
   * Creates a child injector.
   *
   * [modules] overrides bindings of the parent.
   */
  @deprecated
  Injector createChild(List<Module> modules);
}


/**
 * The RootInjector serves as an alternative to having a null parent for
 * injectors that have no parent. This allows us to bypass checking for a null
 * parent, and instead RootInjector will start the exception chain that reports
 * the resolution context tree when no providers are found.
 */
class RootInjector extends Injector {
  Injector get parent => null;
  List<Object> get _instances => null;
  dynamic getByKey(key, [depth]) => throw new NoProviderError(key);
  Injector createChild(m) => null;
}

class ModuleInjector extends Injector {

  static final rootInjector = new RootInjector();
  final Injector parent;

  List<Binding> _bindings;
  List<Object> _instances;

  ModuleInjector(List<Module> modules, [Injector parent])
      : parent = parent == null ? rootInjector : parent,
        _bindings = new List<Binding>(Key.numInstances + 1), // + 1 for injector itself
        _instances = new List.filled(Key.numInstances + 1, _Instance.EMPTY) {

    if (modules != null) {
      modules.forEach((module) {
        module.bindings.forEach((Key key, Binding binding) =>
            _bindings[key.id] = binding);
      });
    }
    _instances[_INJECTOR_KEY.id] = this;
  }

  Iterable<Type> _typesCache;

  Iterable<Type> get _types {
    if (_bindings == null) return [];

    if (_typesCache == null) {
      _typesCache = _bindings
          .where((p) => p != null)
          .map((p) => p.key.type);
    }
    return _typesCache;
  }

  Set<Type> get types {
    var types = new Set<Type>();
    for (var node = this; node.parent != null; node = node.parent) {
      types.addAll(node._types);
    }
    types.add(Injector);
    return types;
  }

  dynamic getByKey(Key key) {
    var id = key.id;
    if (id >= _instances.length) {
      throw new NoProviderError(key);
    }
    var instance = _instances[id];
    if (identical(instance, _Instance.CREATING)) {
      _instances[id] = _Instance.EMPTY;
      throw new CircularDependencyError(key);
    }
    if (!identical(instance, _Instance.EMPTY)) return instance;

    Binding binding = _bindings[id];
    // When binding is null, recurse instead of iterate because it:
    // 1. tracks key history on the stack for error reporting
    // 2. allows different types of ancestor injectors with alternative implementations.
    // An alternative could be to recurse only when parent is not a ModuleInjector
    if (binding == null) return _instances[id] = parent.getByKey(key);

    _instances[id] = _Instance.CREATING;
    try {
      var paramKeys = binding.parameterKeys;
      var length = paramKeys.length;
      var factory = binding.factory;

      if (length > 15) {
        var params = new List(length);
        for (var i = 0; i < length; i++) {
          params[i] = getByKey(paramKeys[i]);
        }
        return _instances[id] = Function.apply(factory, params);
      }

      var a1 = length >= 1 ? getByKey(paramKeys[0]) : null;
      var a2 = length >= 2 ? getByKey(paramKeys[1]) : null;
      var a3 = length >= 3 ? getByKey(paramKeys[2]) : null;
      var a4 = length >= 4 ? getByKey(paramKeys[3]) : null;
      var a5 = length >= 5 ? getByKey(paramKeys[4]) : null;
      var a6 = length >= 6 ? getByKey(paramKeys[5]) : null;
      var a7 = length >= 7 ? getByKey(paramKeys[6]) : null;
      var a8 = length >= 8 ? getByKey(paramKeys[7]) : null;
      var a9 = length >= 9 ? getByKey(paramKeys[8]) : null;
      var a10 = length >= 10 ? getByKey(paramKeys[9]) : null;
      var a11 = length >= 11 ? getByKey(paramKeys[10]) : null;
      var a12 = length >= 12 ? getByKey(paramKeys[11]) : null;
      var a13 = length >= 13 ? getByKey(paramKeys[12]) : null;
      var a14 = length >= 14 ? getByKey(paramKeys[13]) : null;
      var a15 = length >= 15 ? getByKey(paramKeys[14]) : null;

      switch (length) {
        case 0: return _instances[id] = factory();
        case 1: return _instances[id] = factory(a1);
        case 2: return _instances[id] = factory(a1, a2);
        case 3: return _instances[id] = factory(a1, a2, a3);
        case 4: return _instances[id] = factory(a1, a2, a3, a4);
        case 5: return _instances[id] = factory(a1, a2, a3, a4, a5);
        case 6: return _instances[id] = factory(a1, a2, a3, a4, a5, a6);
        case 7: return _instances[id] = factory(a1, a2, a3, a4, a5, a6, a7);
        case 8: return _instances[id] = factory(a1, a2, a3, a4, a5, a6, a7, a8);
        case 9: return _instances[id] = factory(a1, a2, a3, a4, a5, a6, a7, a8, a9);
        case 10: return _instances[id] = factory(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10);
        case 11: return _instances[id] = factory(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11);
        case 12: return _instances[id] = factory(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12);
        case 13: return _instances[id] = factory(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13);
        case 14: return _instances[id] = factory(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14);
        case 15: return _instances[id] = factory(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15);
      }
    } on ResolvingError catch (e) {
      _instances[id] = _Instance.EMPTY;
      e.appendKey(key);
      rethrow; // to preserve stack trace
    } catch (e) {
      _instances[id] = _Instance.EMPTY;
      rethrow;
    }
  }

  @deprecated
  Injector createChild(List<Module> modules) {
    return new ModuleInjector(modules,this);
  }
}
