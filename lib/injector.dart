part of di;


class Injector {
  final List<String> PRIMITIVE_TYPES = <String>['dynamic', 'num', 'int', 'double', 'String', 'bool'];

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

    // should be Injector type, not string
    instances['Injector'] = reflect(this);
  }

  String _error(message, [appendDependency]) {
    if (?appendDependency) {
      resolving.add(appendDependency);
    }

    String graph = resolving.join(' -> ');

    resolving.clear();

    return '$message (resolving $graph)';
  }

  dynamic _getInstanceByTypeName(String typeName) {
    if (PRIMITIVE_TYPES.contains(typeName)) {
      throw new NoProviderException(_error('Cannot inject a primitive type of ${typeName}!', typeName));
    }

    if (instances.containsKey(typeName)) {
      return instances[typeName];
    }

    if (resolving.contains(typeName)) {
      throw new CircularDependencyException(_error('Cannot resolve a circular dependency!', typeName));
    }

    if (providers.containsKey(typeName)) {
      resolving.add(typeName);
      instances[typeName] = providers[typeName].get(_getInstanceByTypeName, null);
      resolving.removeLast();
    } else if (parent != null) {
      return parent._getInstanceByTypeName(typeName);
    } else {
      // implicit type provider, only root injector does that
      resolving.add(typeName);
      Provider provider = new _TypeProvider.fromString(typeName);
      instances[typeName] = provider.get(_getInstanceByTypeName, _error);
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