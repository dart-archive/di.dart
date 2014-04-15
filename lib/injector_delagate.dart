part of di;

class InjectorDelagate implements Injector {
  Injector _injector;
  List<Key> _resolving;

  InjectorDelagate(this._injector, this._resolving);

  Injector get parent => _injector.parent;

  dynamic get(Type type, [Type annotation]) =>
      _injector.getInstanceByKey(new Key(type, annotation), this, _resolving);

  dynamic getByKey(Key key) =>
      _injector.getInstanceByKey(key, this, _resolving);

  dynamic getInstanceByKey(Key key, Injector requester, List<Key> resolving) =>
      _injector.getInstanceByKey(key, requester, resolving);

  Injector createChild(List<Module> modules,
                       {List forceNewInstances, String name}) =>
      _injector._createChildWithResolvingHistory(modules, _resolving,
          forceNewInstances: forceNewInstances,
          name: name);
}
