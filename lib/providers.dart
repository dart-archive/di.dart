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
  final Symbol typeName;

  _TypeProvider(Symbol typeName)
      : this.typeName = typeName,
        this.classMirror = getClassMirrorBySymbol(typeName);

  dynamic get(getInstanceBySymbol, error) {

    if (classMirror is TypedefMirror) {
      throw new NoProviderError(error('No implementation provided '
          'for ${getSymbolName(classMirror.qualifiedName)} typedef!'));
    }

    MethodMirror ctor = classMirror.constructors[classMirror.simpleName];

    resolveArgument(int pos) {
      ParameterMirror p = ctor.parameters[pos];
      return getInstanceBySymbol(p.type.qualifiedName);
    }

    var args = new List.generate(ctor.parameters.length, resolveArgument,
        growable: false);
    return classMirror.newInstance(ctor.constructorName, args).reflectee;
  }
}


class _FactoryProvider implements Provider {
  static final Map<Type, MethodMirror> _cachedMirrors = new HashMap();
  final Function factoryFn;

  _FactoryProvider(Function this.factoryFn);

  dynamic get(getInstanceBySymbol, error) {
    var parameters = _methodMirror.parameters;
    resolveArgument(int pos) {
      ParameterMirror p = parameters[pos];
      return getInstanceBySymbol(p.type.qualifiedName);
    }

    var args = new List.generate(parameters.length, resolveArgument,
        growable: false);
    return Function.apply(factoryFn, args);
  }

  MethodMirror get _methodMirror {
    _cachedMirrors.putIfAbsent(factoryFn.runtimeType, () {
      return reflect(factoryFn).function;
    });
    return _cachedMirrors[factoryFn.runtimeType];
  }
}
