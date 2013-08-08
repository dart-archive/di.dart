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

    resolveArgument(ParameterMirror p) {
      return getInstanceBySymbol(p.type.qualifiedName);
    }

    var positionalArgs = ctor.parameters.map(resolveArgument).toList();
    var namedArgs = null;

    try {
      return classMirror.newInstance(ctor.constructorName, positionalArgs,
          namedArgs).reflectee;
    } catch (e) {
      if (e is MirroredUncaughtExceptionError) {
        throw "${e}\nORIGINAL STACKTRACE\n${e.stacktrace}";
      }
      rethrow;
    }
  }
}


class _FactoryProvider implements Provider {
  final Function factoryFn;

  _FactoryProvider(Function this.factoryFn);

  dynamic get(getInstanceBySymbol, error) {
    ClosureMirror cm = reflect(factoryFn);
    MethodMirror mm = cm.function;

    resolveArgument(p) {
      return getInstanceBySymbol(p.type.qualifiedName);
    }

    var positionalArgs = mm.parameters.map(resolveArgument).toList();
    var namedArgs = null;

    try {
      return cm.apply(positionalArgs, namedArgs).reflectee;
    } catch (e) {
      if (e is MirroredUncaughtExceptionError) {
        throw "${e}\nORIGINAL STACKTRACE\n${e.stacktrace}";
      }
      rethrow;
    }
  }
}
