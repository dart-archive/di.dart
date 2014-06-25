library di.dynamic_type_factories;

import 'di.dart';
import 'src/mirrors.dart';

TypeReflector setupModuleTypeReflector() => Module.DEFAULT_REFLECTOR = new DynamicTypeFactories();

class DynamicTypeFactories extends TypeReflector {
  /// caches of results calculated from mirroring
  final List<Factory> _factories = new List<Factory>();
  final List<List<Key>> _parameterKeys = new List<List<Key>>();

  Factory factoryFor(Type type) {
    var key = new Key(type);
    _resize(key.id);
    Factory factory = _factories[key.id];
    if (factory == null) {
      factory = _factories[key.id] = _generateFactory(type);
    }
    return factory;
  }

  List<Key> parameterKeysFor(Type type) {
    var key = new Key(type);
    _resize(key.id);
    List<Key> parameterKeys = _parameterKeys[key.id];
    if (parameterKeys == null) {
      parameterKeys = _parameterKeys[key.id] = _generateParameterKeys(type);
    }
    return parameterKeys;
  }

  _resize(int maxId) {
    if (_factories.length <= maxId) {
      _factories.length = maxId + 1;
      _parameterKeys.length = maxId + 1;
    }
  }

  Factory _generateFactory(Type type) {
    ClassMirror classMirror = _reflectClass(type);
    MethodMirror ctor = classMirror.declarations[classMirror.simpleName];
    return (List args) => classMirror.newInstance(ctor.constructorName, args).reflectee;
  }

  List<Key> _generateParameterKeys(Type type) {
    ClassMirror classMirror = _reflectClass(type);
    MethodMirror ctor = classMirror.declarations[classMirror.simpleName];

    return new List.generate(ctor.parameters.length, (int pos) {
      ParameterMirror p = ctor.parameters[pos];
      if (p.type.qualifiedName == #dynamic) {
        var name = MirrorSystem.getName(p.simpleName);
        throw new DynamicReflectorError("Error getting params for '$type': "
            "The '$name' parameter must be typed");
      }
      if (p.type is TypedefMirror) {
        throw new DynamicReflectorError("Typedef '${p.type}' in constructor "
            "'${classMirror.simpleName}' is not supported.");
      }
      if (p.metadata.length > 1) {
        throw new DynamicReflectorError(
            "Constructor '${classMirror.simpleName}' parameter $pos of type "
            "'${p.type}' can have only zero on one annotation, but it has "
            "'${p.metadata}'.");
      }
      var pType = (p.type as ClassMirror).reflectedType;
      var annotationType = p.metadata.isNotEmpty ? p.metadata.first.type.reflectedType : null;
      return new Key(pType, annotationType);
    }, growable:false);
  }

  ClassMirror _reflectClass(Type type) {
    ClassMirror classMirror = reflectType(type);
    if (classMirror is TypedefMirror) {
      throw new DynamicReflectorError('No implementation provided for '
          '${getSymbolName(classMirror.qualifiedName)} typedef!');
    }

    MethodMirror ctor = classMirror.declarations[classMirror.simpleName];

    if (ctor == null) {
      throw new DynamicReflectorError('Unable to find default constructor for $type. '
      'Make sure class has a default constructor.' + (1.0 is int ?
      'Make sure you have correctly configured @MirrorsUsed.' : ''));
    }
    return classMirror;
  }
}
