library di.injector_delegate;

import 'base_injector.dart';
import 'package:di/di.dart';
import 'package:di/key.dart';

class InjectorDelagate implements Injector, ObjectFactory {
  BaseInjector _injector;
  List<Key> _resolving;

  InjectorDelagate(this._injector, this._resolving);

  @override
  bool get allowImplicitInjection => _injector.allowImplicitInjection;

  @override
  String get name => _injector.name;

  @override
  Injector get root => _injector.root;

  @override
  Set<Type> get types => _injector.types;

  @override
  Injector get parent => _injector.parent;

  @override
  dynamic get(Type type, [Type annotation]) =>
      _injector.getInstanceByKey(new Key(type, annotation), this, _resolving);

  @override
  dynamic getInstanceByKey(Key key, Injector requester, List<Key> resolving) =>
        _injector.getInstanceByKey(key, requester, resolving);

  @override
  dynamic getByKey(Key key) =>
      _injector.getInstanceByKey(key, this, _resolving);

  @override
  Injector createChild(List<Module> modules,
                       {List forceNewInstances, String name}) =>
      _injector.createChildWithResolvingHistory(modules, _resolving,
          forceNewInstances: forceNewInstances,
          name: name);

  @override
  newFromParent(List<Module> modules, String name) =>
      _injector.newFromParent(modules, name);

  @override
  Object newInstanceOf(Type type, ObjectFactory factory,
                       Injector requestor, resolving) =>
      _injector.newInstanceOf(type, factory, requestor, resolving);
}
