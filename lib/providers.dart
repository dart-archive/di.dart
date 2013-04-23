part of di;


abstract class Provider {
  dynamic get(getInstanceBySymbol, error);
}


class _ValueProvider implements Provider {
  dynamic value;

  _ValueProvider(value) {
    this.value = value;
  }

  dynamic get(getInstanceBySymbol, error) {
    return value;
  }
}


class _TypeProvider implements Provider {
  final ClassMirror classMirror;

  _TypeProvider(Type type) : this.classMirror = reflectClass(type);

  _TypeProvider.fromString(Symbol id) : this.classMirror = getClassMirrorBySymbol(id);

  dynamic get(getInstanceBySymbol, error) {

    if (classMirror is TypedefMirror) {
      throw new NoProviderException(error('No implementation provided for ${classMirror.simpleName} typedef!'));
    }

    MethodMirror ctor = classMirror.constructors.values.first;

    resolveArgument(p) {
      return getInstanceBySymbol(p.type.simpleName);
    }

    var positionalArgs = ctor.parameters.map(resolveArgument).toList();
    var namedArgs = null;

    return classMirror.newInstance(ctor.constructorName, positionalArgs, namedArgs).reflectee;
  }
}


class _FactoryProvider implements Provider {
  final Function factoryFn;

  _FactoryProvider(Function this.factoryFn);

  dynamic get(getInstanceBySymbol, error) {
    ClosureMirror cm = reflect(factoryFn);
    MethodMirror mm = cm.function;

    resolveArgument(p) {
      return getInstanceBySymbol(p.type.simpleName);
    }

    var positionalArgs = mm.parameters.map(resolveArgument).toList();
    var namedArgs = null;

    return cm.apply(positionalArgs, namedArgs).reflectee;
  }
}