part of di;

class InjectorDelagate implements Injector {
  Injector _injector;
  List<Key> _resolving;

  InjectorDelagate(this._injector, this._resolving);

  Injector get parent => _injector.parent;

  dynamic get(Type type, [Type annotation]) =>
      _injector._getInstanceByKey(new Key(type, annotation), this, _resolving);

  dynamic getByKey(Key key) =>
      _injector._getInstanceByKey(key, this, _resolving);

  dynamic _getInstanceByKey(Key key, Injector requester, List<Key> resolving) =>
      _injector._getInstanceByKey(key, requester, resolving);

  String _error(resolving, message, [appendDependency]) =>
      _injector._error(resolving, message, appendDependency);

  Injector createChild(List<Module> modules,
                       {List forceNewInstances, String name}) =>
      _injector._createChildWithResolvingHistory(modules, _resolving,
          forceNewInstances: forceNewInstances,
          name: name);
}
