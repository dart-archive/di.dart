library di.base_injector;

import 'provider.dart';
import 'error_helper.dart';

import 'package:collection/collection.dart';
import 'package:di/di.dart';
import 'package:di/key.dart';
import 'dart:collection';

List<Key> _PRIMITIVE_TYPES = new UnmodifiableListView(<Key>[
  new Key(num), new Key(int), new Key(double), new Key(String),
  new Key(bool)
]);

abstract class BaseInjector implements Injector, ObjectFactory {

  @override
  final String name;

  @override
  final BaseInjector parent;

  Injector _root;

  List<Provider> _providers;

  /**
   * _instances is a List when implicit injection is not allowed
   * for performance because all types would have been seen and the
   * List would not need to be expanded. In dynamic injection with
   * implicit injection turned on it is a Map instead.
   */
  List<Object> _instancesList;
  Map<int, Object> _instancesMap;

  @override
  final bool allowImplicitInjection;

  Iterable<Type> _typesCache;

  Iterable<Type> get _types {
    if (_providers == null) return [];

    if (_typesCache == null) {
      _typesCache = _providers
          .where((p) => p != null)
          .map((p) => p.type);
    }
    return _typesCache;
  }

  BaseInjector({List<Module> modules, String name,
           bool allowImplicitInjection: false})
      : this.fromParent(modules, null,
          name: name, allowImplicitInjection: allowImplicitInjection);

  BaseInjector.fromParent(List<Module> modules,
      BaseInjector this.parent, {this.name, this.allowImplicitInjection: false}) {
    _root = parent == null ? this : parent._root;
    var injectorId = new Key(Injector).id;
    _providers = new List(Key.numInstances);

    if (allowImplicitInjection) {
      _instancesMap = new HashMap<int, Object>();
    } else {
      _instancesList = new List(Key.numInstances);
    }
    if (modules != null) {
      modules.forEach((module) {
        module.updateListWithBindings(_providers);
      });
    }
    _providers[injectorId] = new ValueProvider(Injector, this);
  }

  @override
  Injector get root => _root;

  @override
  Set<Type> get types {
    var types = new Set<Type>();
    for (var node = this; node != null; node = node.parent) {
      types.addAll(node._types);
    }
    return types;
  }

  @override
  Object getInstanceByKey(Key key, Injector requester, ResolutionContext resolving) {
    assert(_checkKeyConditions(key, resolving));

    // Do not bother checking the array until we are fairly deep.
    if (resolving.depth > 30 && resolving.ancestorKeys.contains(key)) {
      throw new CircularDependencyError(
          error(resolving, 'Cannot resolve a circular dependency!', key));
    }

    var providerWithInjector = _getProviderWithInjectorForKey(key, resolving);
    var provider = providerWithInjector.provider;
    var injector = providerWithInjector.injector;
    var visible = provider.visibility == null ||
        provider.visibility(requester, injector);

    assert(allowImplicitInjection || key.id < _instancesList.length);
    if (visible){
      var instance = allowImplicitInjection ?
              _instancesMap[key.id] : _instancesList[key.id];
      if (instance != null){
        return instance;
      }
    }

    if (injector != this || !visible) {
      if (!visible) {
        if (injector.parent == null) {
          throw new NoProviderError(
              error(resolving, 'No provider found for ${key}!', key));
        }
        injector = injector.parent
            ._getProviderWithInjectorForKey(key, resolving).injector;
      }
      return injector.getInstanceByKey(key, requester, resolving);
    }

    resolving = new ResolutionContext(resolving.depth + 1, key, resolving);
    var value = provider.get(this, requester, this, resolving);

    // cache the value.
    if (allowImplicitInjection == true) {
      providerWithInjector.injector._instancesMap[key.id] = value;
    } else {
      providerWithInjector.injector._instancesList[key.id] = value;
    }
    return value;
  }

  /**
   * Finds the nearest ancestor injector that binds a [Provider] to [key] and
   * returns that [Provider] and its binding [Injector].  If there is no such
   * [Injector], then
   *
   * - if [allowImplicitInjection] is true for the root injector (not this
   *   injector), returns a default [Provider] and the root injector.
   * - if [allowImplicitInjector] is false for the root injector, throws
   *   [NoProviderError].
   *
   * [resolving] is only used for error reporting.
   */
  _ProviderWithInjector _getProviderWithInjectorForKey(
      Key key, ResolutionContext resolving) {
    if (key.id < _providers.length) {
      var provider = _providers[key.id];
      if (provider != null) {
        return new _ProviderWithInjector(provider, this);
      }
    }
    if (parent != null) {
      return parent._getProviderWithInjectorForKey(key, resolving);
    }
    if (allowImplicitInjection) {
      return new _ProviderWithInjector(new TypeProvider(key.type), this);
    }
    throw new NoProviderError(
        error(resolving, 'No provider found for ${key}!', key));
  }

  bool _checkKeyConditions(Key key, ResolutionContext resolving) {
    if (_PRIMITIVE_TYPES.contains(key)) {
      throw new NoProviderError(
          error(resolving,
                'Cannot inject a primitive type of ${key.type}!', key));
    }
    return true;
  }

  @override
  dynamic get(Type type, [Type annotation]) =>
      getInstanceByKey(new Key(type, annotation), this, ResolutionContext.ROOT);

  @override
  dynamic getByKey(Key key) =>
      getInstanceByKey(key, this, ResolutionContext.ROOT);

  @override
  Injector createChild(List<Module> modules,
                       {List forceNewInstances, String name}) =>
      createChildWithResolvingHistory(modules, ResolutionContext.ROOT,
          forceNewInstances: forceNewInstances,
          name: name);

  Injector createChildWithResolvingHistory(
                        List<Module> modules,
                        ResolutionContext resolving,
                        {List forceNewInstances, String name}) {
    if (forceNewInstances != null) {
      Module forceNew = new Module();
      forceNewInstances.forEach((key) {
        if (key is Type) {
          key = new Key(key);
        } else if (key is! Key) {
          throw 'forceNewInstances must be List<Key|Type>';
        }
        var providerWithInjector =
            _getProviderWithInjectorForKey(key, resolving);
        var provider = providerWithInjector.provider;
        forceNew.bindByKey(key,
            toFactory: (Injector inj) =>
                provider.get(this, inj, inj as ObjectFactory, resolving),
            visibility: provider.visibility);
      });

      modules = modules.toList(); // clone
      modules.add(forceNew);
    }

    return newFromParent(modules, name);
  }

  newFromParent(List<Module> modules, String name);

  Object newInstanceOf(Type type, ObjectFactory factory, Injector requestor,
                       ResolutionContext resolving);
}

class _ProviderWithInjector {
  final Provider provider;
  final BaseInjector injector;
  _ProviderWithInjector(this.provider, this.injector);
}

/**
 * A node in a depth-first search tree of the dependency DAG.
 */
class ResolutionContext {
  static final ResolutionContext ROOT = new ResolutionContext(0, null, null);

  /// Distance from the [ROOT].
  final int depth;
  /// Key at this node or null if this is the [ROOT].
  final Key key;
  /// Parent node or null if this is the [ROOT].  This node is a dependency of
  /// the parent.
  final ResolutionContext parent;

  ResolutionContext(this.depth, this.key, this.parent);

  /// Returns the [key]s of the ancestors of this node (including this node) in
  /// the order that ascends the tree.  Note that [ROOT] has no [key].
  List<Key> get ancestorKeys {
    var keys = [];
    for (var node = this; node.parent != null; node = node.parent) {
      keys.add(node.key);
    }
    return keys;
  }
}
