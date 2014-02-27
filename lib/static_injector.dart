library di.static_injector;

import 'di.dart';

/**
 * Static implementation of [Injector] that uses type factories
 */
class StaticInjector extends Injector {
  Map<Key, TypeFactory> typeFactories;

  StaticInjector({List<Module> modules, String name,
                 bool allowImplicitInjection: false, typeFactories})
      : super(modules: modules, name: name,
          allowImplicitInjection: allowImplicitInjection) {
    this.typeFactories = _extractTypeFactories(modules, typeFactories);
  }

  StaticInjector._fromParent(List<Module> modules, Injector parent, {name})
      : super.fromParent(modules, parent, name: name) {
    this.typeFactories = _extractTypeFactories(modules);
  }

  newFromParent(List<Module> modules, String name) {
    return new StaticInjector._fromParent(modules, this, name: name);
  }

  Object newInstanceOf(Type type, ObjectFactory getInstanceByKey,
                       Injector requestor, error) {
    TypeFactory typeFactory = _getFactory(new Key(type));
    if (typeFactory == null) {
      throw new NoProviderError(error('No type factory provided for $type!'));
    }
    return typeFactory((type, annotation) => getInstanceByKey(
        new Key(type, annotations: annotation), requestor));
  }

  TypeFactory _getFactory(Key key) {
    var cursor = this;
    while (cursor != null) {
      if (cursor.typeFactories.containsKey(key)) {
        return cursor.typeFactories[key];
      }
      cursor = cursor.parent;
    }
    return null;
  }
}

Map<Key, TypeFactory> _extractTypeFactories(List<Module> modules,
    [Map<Key, TypeFactory> initial = const {}]) {
  if (modules == null || modules.isEmpty) return initial;
  var tmp = new Map.from(initial == null ? {} : initial);
  modules.forEach((module) {
    module.typeFactories.forEach((key, factory) {
      tmp[key] = factory;
    });
  });
  return tmp;
}
