part of di;


class Injector {
  final List<Symbol> PRIMITIVE_TYPES = <Symbol>[new Symbol('dynamic'), new Symbol('num'), new Symbol('int'), new Symbol('double'), new Symbol('String'), new Symbol('bool')];

  final Injector parent;

  // should be <Type, Provider>
  Map<Symbol, Provider> providers = new Map<Symbol, Provider>();
  // should be <Type, dynamic>
  Map<Symbol, dynamic> instances = new Map<Symbol, dynamic>();

  List<Symbol> resolving = new List<Symbol>();

  Injector([List<Module> modules, Injector parent]) : this.parent = parent {

    if (?modules) {
      modules.forEach((module) {
        providers.addAll(module);
      });
    }

    // should be Injector type, not string
    instances[new Symbol('Injector')] = this;
  }

  String _error(message, [appendDependency]) {
    if (?appendDependency) {
      resolving.add(appendDependency);
    }

    String graph = resolving.map(formatSymbol).join(' -> ');

    resolving.clear();

    return '$message (resolving $graph)';
  }

  dynamic _getInstanceBySymbol(Symbol typeName) {
    if (PRIMITIVE_TYPES.contains(typeName)) {
      throw new NoProviderException(_error('Cannot inject a primitive type of ${formatSymbol(typeName)}!', typeName));
    }

    if (instances.containsKey(typeName)) {
      return instances[typeName];
    }

    if (resolving.contains(typeName)) {
      throw new CircularDependencyException(_error('Cannot resolve a circular dependency!', typeName));
    }

    if (providers.containsKey(typeName)) {
      resolving.add(typeName);
      instances[typeName] = providers[typeName].get(_getInstanceBySymbol, null);
      resolving.removeLast();
    } else if (parent != null) {
      return parent._getInstanceBySymbol(typeName);
    } else {
      // implicit type provider, only root injector does that
      resolving.add(typeName);
      Provider provider = new _TypeProvider.fromString(typeName);
      instances[typeName] = provider.get(_getInstanceBySymbol, _error);
      resolving.removeLast();
    }

    return instances[typeName];
  }

  Provider _getProviderForType(Type type) {
    Symbol typeName = reflectClass(type).simpleName;

    if (providers.containsKey(typeName)) {
      return providers[typeName];
    }

    if (parent != null) {
      return parent._getProviderForType(type);
    }

    // create a provider for implicit types
    return new _TypeProvider(type);
  }


  // PUBLIC API
  dynamic get(Type type) {
    return _getInstanceBySymbol(reflectClass(type).simpleName);
  }

  dynamic getBySymbol(Symbol name) {
    return _getInstanceBySymbol(name);
  }

  dynamic invoke(Function fn) {
    ClosureMirror cm = reflect(fn);
    MethodMirror mm = cm.function;
    List args = mm.parameters.map((parameter) {
      return _getInstanceBySymbol(parameter.type.simpleName);
    }).toList();
    return cm.apply(args, null).reflectee;
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
