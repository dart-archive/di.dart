part of di;


abstract class Provider {
  dynamic get(getInstanceByTypeName, error);
}


class _ValueProvider implements Provider {
  dynamic value;

  _ValueProvider(value) {
    this.value = value;
  }

  dynamic get(getInstanceByTypeName, error) {
    return reflect(value);
  }
}


class _TypeProvider implements Provider {
  final String typeName;

  _TypeProvider(Type type) : this.typeName = type.toString();

  _TypeProvider.fromString(String this.typeName);

  dynamic get(getInstanceByTypeName, error) {
    ClassMirror cm = getClassMirrorByTypeName(typeName);

    if (cm is TypedefMirror) {
      throw new NoProviderException(error('No implementation provided for $typeName typedef!'));
    }

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

  dynamic get(getInstanceByTypeName, error) {
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