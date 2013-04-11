import 'mirrors.dart';
import 'dart:async';
import 'dart:collection';

class NoProviderException implements Exception {
  final String message;

  const NoProviderException(this.message);
  const NoProviderException.forType(String typeName) : this('No provider for ${typeName}!');
}

class CircularDependencyException implements Exception {
  final String message;

  const CircularDependencyException(this.message);
}


abstract class Provider {
  dynamic get(getInstanceByTypeName);
}


class _ValueProvider implements Provider {
  dynamic value;

  _ValueProvider(value) {
    this.value = value;
  }

  dynamic get(getInstanceByTypeName) {
    return reflect(value);
  }
}


class _TypeProvider implements Provider {
  final String typeName;

  _TypeProvider(Type type) : this.typeName = type.toString();

  _TypeProvider.fromString(String this.typeName);

  dynamic get(getInstanceByTypeName) {
    ClassMirror cm = _getClassMirrorByTypeName(typeName);
    MethodMirror ctor = cm.constructors.values.first;

    resolveArgument(p) {
      return getInstanceByTypeName(p.type.simpleName);
    }

    var positionalArgs = ctor.parameters.map(resolveArgument).toList();
    var namedArgs = null;

    return deprecatedFutureValue(cm.newInstance(ctor.constructorName, positionalArgs, namedArgs));
  }
}


class _FactoryProvider implements Provider {
  final Function factoryFn;

  _FactoryProvider(Function this.factoryFn);

  dynamic get(getInstanceByTypeName) {
    ClosureMirror cm = reflect(factoryFn);
    MethodMirror mm = cm.function;

    resolveArgument(p) {
      return getInstanceByTypeName(p.type.simpleName);
    }

    var positionalArgs = mm.parameters.map(resolveArgument).toList();
    var namedArgs = null;

    return deprecatedFutureValue(cm.apply(positionalArgs, namedArgs));
  }
}


class Module extends HashMap<String, Provider> {

  void value(Type id, value) {
    this[id.toString()] = new _ValueProvider(value);
  }

  void type(Type id, Type type) {
    this[id.toString()] = new _TypeProvider(type);
  }

  void provider(Type id, Provider provider) {
    this[id.toString()] = provider;
  }

  void factory(Type id, Function factoryFn) {
    this[id.toString()] = new _FactoryProvider(factoryFn);
  }
}


// terrible hack because we can't get a qualified name from a Type
// dartbug.com/8041
// dartbug.com/9395
ClassMirror _getClassMirrorByTypeName (String typeName) {
  for (var lib in currentMirrorSystem().libraries.values) {
    if (lib.classes.containsKey(typeName)) {
      return lib.classes[typeName];
    }
  }
}


class Injector {
  final List<String> PRIMITIVE_TYPES = <String>['dynamic', 'num', 'String', 'bool'];

  final Injector parent;

  // should be <Type, Provider>
  Map<String, Provider> providers = new Map<String, Provider>();
  // should be <Type, dynamic>
  Map<String, dynamic> instances = new Map<String, dynamic>();

  List<String> resolving = new List<String>();
  
  Injector([List<Module> modules, Injector parent]) : this.parent = parent {

    if (?modules) {
      modules.forEach((module) {
        providers.addAll(module);
      });
    }
  }

  dynamic _getInstanceByTypeName(String typeName) {
    if (PRIMITIVE_TYPES.contains(typeName)) {
      String graph = resolving.join(' -> ') + ' -> ' + typeName;
      resolving.clear();
      throw new NoProviderException('Cannot inject a primitive type of ${typeName}! (resolving ${graph})');
    }

    if (instances.containsKey(typeName)) {
      return instances[typeName];
    }

    if (resolving.contains(typeName)) {
      String graph = resolving.join(' -> ') + ' -> ' + typeName;
      resolving.clear();
      throw new CircularDependencyException('Cannot resolve a circular dependency! (resolving ${graph})');
    }

    if (providers.containsKey(typeName)) {
      resolving.add(typeName);
      instances[typeName] = providers[typeName].get(_getInstanceByTypeName);
      resolving.removeLast();
    } else if (parent != null) {
      return parent._getInstanceByTypeName(typeName);
    } else {
      // implicit type provider, only root injector does that
      resolving.add(typeName);
      Provider provider = new _TypeProvider.fromString(typeName);
      instances[typeName] = provider.get(_getInstanceByTypeName);
      resolving.removeLast();
    }

    return instances[typeName];
  }

  Provider _getProviderForType(Type type) {
    String typeName = type.toString();

    if (providers.containsKey(typeName)) {
      return providers[typeName];
    }

    if (parent != null) {
      return parent._getProviderForType(typeName);
    }

    // create a provider for implicit types
    return new _TypeProvider(type);
  }

 
  // PUBLIC API
  dynamic get(Type type) {
    return _getInstanceByTypeName(type.toString()).reflectee;
  }

  Injector createChild(List<Module> modules, [List<Type> forceNewInstances]) {
    if (?forceNewInstances) {
      Module forceNew = new Module();
      forceNewInstances.forEach((type) {
        forceNew.provider(type, _getProviderForType(type));
      });

      modules = modules.toList(); // clone
      modules.add(forceNew);
    }

    return new Injector(modules, this);
  }
}
