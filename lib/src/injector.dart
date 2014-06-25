part of di;

Key _INJECTOR_KEY = new Key(Injector);

abstract class Injector {

  /**
   * The parent injector.
   */
  final Injector parent;

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
  dynamic get(Type type, [Type annotation])
      => getByKey(new Key(type, annotation));

  /**
   * Faster version of [get].
   */
  dynamic getByKey(Key key, [int depth]);

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
class RootInjector implements Injector {
  Injector get parent => null;
  List<Object> get _instances => null;
  dynamic getByKey(key) => throw new NoProviderError(key);
  const RootInjector();
}

class ModuleInjector extends Injector {

  static const rootInjector = const RootInjector();
  final Injector parent;
  String name;

  List<Binding> _bindings;
  List<Object> _instances;

  ModuleInjector(List<Module> modules, [Injector parent])
      : parent = parent == null ? rootInjector : parent,
        _bindings = new List<Binding>(Key.numInstances + 1), // + 1 for injector itself
        _instances = new List<Object>(Key.numInstances + 1) {

    if (modules != null) {
      modules.forEach((module) {
        module.bindings.forEach((Key key, Binding binding)
            => _bindings[key.id] = binding);
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

  dynamic getByKey(Key key, [int depth = 0]){
    var id = key.id;
    if (id < _instances.length) {
      var instance = _instances[id];
      if (instance != null) return instance;

      Binding binding = _bindings[id];
      if (binding != null) {
        if (depth > 42) throw new CircularDependencyError(key);
        try {
          var paramKeys = binding.parameterKeys;
          var length = paramKeys.length;
          var params = new List(length);
          for (var i = 0; i < length; i++) {
            params[i] = getByKey(paramKeys[i], depth + 1);
          }
          return _instances[id] = binding.factory(params);
        } on ResolvingError catch (e) {
          e.appendKey(key);
          rethrow; // to preserve stack trace
        }
      }
    }
    // recursion instead of iteration because it:
    // 1. tracks key history on the stack for error reporting
    // 2. allows different types of ancestor injectors with alternative implementations.
    // An alternative could be to recurse only when parent is not a ModuleInjector
    return _instances[id] = parent.getByKey(key);
  }

  @deprecated
  Injector createChild(List<Module> modules) {
    return new ModuleInjector(modules,this);
  }
}
