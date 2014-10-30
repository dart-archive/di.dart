library di.reflector_dynamic;

import '../di.dart';
import 'mirrors.dart';

TypeReflector getReflector() => new DynamicTypeFactories();

class DynamicTypeFactories extends TypeReflector {
  /// caches of results calculated from mirroring
  final List<Function> _factories = new List<Function>();
  final List<List<Key>> _parameterKeys = new List<List<Key>>();
  final List<List> lists = new List.generate(26, (i) => new List(i));

  Iterable<ClassMirror> _injectableAnnotations;
  Set<Type> _injectableTypes;

  /**
   * Asserts that the injected classes are set up for static injection. While this is not required
   * for dynamic injection, asserting could help you catch error before switching to the static
   * version of the DI.
   *
   * The injected classes should either be annotated with one of the `Module.classAnnotations` or
   * listed in the `types` field of a `Module.libAnnotations`.
   */
  DynamicTypeFactories() {
    assert(() {
      var typesSymbol = new Symbol('types');
      if (Module.classAnnotations != null) {
        _injectableAnnotations = Module.classAnnotations.toSet().map((Type t) => reflectClass(t));
      }
      if (Module.libAnnotations != null) {
        _injectableTypes = new Set<Type>();
        currentMirrorSystem().libraries.forEach((uri, LibraryMirror lm) {
          lm.metadata.forEach((InstanceMirror im) {
            var cm = im.type;
            if (cm.hasReflectedType &&
                Module.libAnnotations.contains(cm.reflectedType) &&
                cm.declarations.containsKey(typesSymbol)) {
              _injectableTypes.addAll(im.getField(typesSymbol).reflectee);
            }
          });
        });
      }
      return true;
    });
  }

  Function factoryFor(Type type) {
    var key = new Key(type);
    _resize(key.id);
    Function factory = _factories[key.id];
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

  void _resize(int maxId) {
    if (_factories.length <= maxId) {
      _factories.length = maxId + 1;
      _parameterKeys.length = maxId + 1;
    }
  }

  Function _generateFactory(Type type) {
    ClassMirror classMirror = _reflectClass(type);

    assert(() {
      // TODO(vicb): Skip the assertion in JS where `ClassMirror.isSubtypeOf()` is not implemented
      if (!Module.assertAnnotations || 1.0 is int) return true;
      // Assert than:
      // - either the class is annotated with a subtype of any `_injectableAnnotations`,
      // - or the class type is an `_injectableTypes`.
      var hasClassAnnotation = classMirror.metadata.any((InstanceMirror im) {
           var cm = im.type;
           return _injectableAnnotations.any((ClassMirror c) => cm.isSubtypeOf(c));
         });
      if (!hasClassAnnotation && !_injectableTypes.contains(type)) {
        throw "The class '$type' should be annotated with one of "
              "'${_injectableAnnotations.map((cm) => cm.reflectedType).join(', ')}'";
      }
      return true;
    });

    MethodMirror ctor = classMirror.declarations[classMirror.simpleName];
    int length = ctor.parameters.length;
    Function create = classMirror.newInstance;
    Symbol name = ctor.constructorName;
    Function factory;
    if (length > 25) throw "Too many arguments in $name constructor for dynamic DI to handle :(";
    List l = lists[length];
    // script for this is in scripts/reflector_dynamic_script.dart
    switch (length) {
      case 0:
        return () {
          return create(name, l).reflectee;
        };
      case 1:
        return (a1) {
          l[0]=a1;
          return create(name, l).reflectee;
        };
      case 2:
        return (a1, a2) {
          l[0]=a1;l[1]=a2;
          return create(name, l).reflectee;
        };
      case 3:
        return (a1, a2, a3) {
          l[0]=a1;l[1]=a2;l[2]=a3;
          return create(name, l).reflectee;
        };
      case 4:
        return (a1, a2, a3, a4) {
          l[0]=a1;l[1]=a2;l[2]=a3;l[3]=a4;
          return create(name, l).reflectee;
        };
      case 5:
        return (a1, a2, a3, a4, a5) {
          l[0]=a1;l[1]=a2;l[2]=a3;l[3]=a4;l[4]=a5;
          return create(name, l).reflectee;
        };
      case 6:
        return (a1, a2, a3, a4, a5, a6) {
          l[0]=a1;l[1]=a2;l[2]=a3;l[3]=a4;l[4]=a5;l[5]=a6;
          return create(name, l).reflectee;
        };
      case 7:
        return (a1, a2, a3, a4, a5, a6, a7) {
          l[0]=a1;l[1]=a2;l[2]=a3;l[3]=a4;l[4]=a5;l[5]=a6;l[6]=a7;
          return create(name, l).reflectee;
        };
      case 8:
        return (a1, a2, a3, a4, a5, a6, a7, a8) {
          l[0]=a1;l[1]=a2;l[2]=a3;l[3]=a4;l[4]=a5;l[5]=a6;l[6]=a7;l[7]=a8;
          return create(name, l).reflectee;
        };
      case 9:
        return (a1, a2, a3, a4, a5, a6, a7, a8, a9) {
          l[0]=a1;l[1]=a2;l[2]=a3;l[3]=a4;l[4]=a5;l[5]=a6;l[6]=a7;l[7]=a8;l[8]=a9;
          return create(name, l).reflectee;
        };
      case 10:
        return (a1, a2, a3, a4, a5, a6, a7, a8, a9, a10) {
          l[0]=a1;l[1]=a2;l[2]=a3;l[3]=a4;l[4]=a5;l[5]=a6;l[6]=a7;l[7]=a8;l[8]=a9;l[9]=a10;
          return create(name, l).reflectee;
        };
      case 11:
        return (a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11) {
          l[0]=a1;l[1]=a2;l[2]=a3;l[3]=a4;l[4]=a5;l[5]=a6;l[6]=a7;l[7]=a8;l[8]=a9;l[9]=a10;l[10]=a11;
          return create(name, l).reflectee;
        };
      case 12:
        return (a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12) {
          l[0]=a1;l[1]=a2;l[2]=a3;l[3]=a4;l[4]=a5;l[5]=a6;l[6]=a7;l[7]=a8;l[8]=a9;l[9]=a10;l[10]=a11;l[11]=a12;
          return create(name, l).reflectee;
        };
      case 13:
        return (a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13) {
          l[0]=a1;l[1]=a2;l[2]=a3;l[3]=a4;l[4]=a5;l[5]=a6;l[6]=a7;l[7]=a8;l[8]=a9;l[9]=a10;l[10]=a11;l[11]=a12;l[12]=a13;
          return create(name, l).reflectee;
        };
      case 14:
        return (a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14) {
          l[0]=a1;l[1]=a2;l[2]=a3;l[3]=a4;l[4]=a5;l[5]=a6;l[6]=a7;l[7]=a8;l[8]=a9;l[9]=a10;l[10]=a11;l[11]=a12;l[12]=a13;l[13]=a14;
          return create(name, l).reflectee;
        };
      case 15:
        return (a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15) {
          l[0]=a1;l[1]=a2;l[2]=a3;l[3]=a4;l[4]=a5;l[5]=a6;l[6]=a7;l[7]=a8;l[8]=a9;l[9]=a10;l[10]=a11;l[11]=a12;l[12]=a13;l[13]=a14;l[14]=a15;
          return create(name, l).reflectee;
        };
      case 16:
        return (a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16) {
          l[0]=a1;l[1]=a2;l[2]=a3;l[3]=a4;l[4]=a5;l[5]=a6;l[6]=a7;l[7]=a8;l[8]=a9;l[9]=a10;l[10]=a11;l[11]=a12;l[12]=a13;l[13]=a14;l[14]=a15;l[15]=a16;
          return create(name, l).reflectee;
        };
      case 17:
        return (a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17) {
          l[0]=a1;l[1]=a2;l[2]=a3;l[3]=a4;l[4]=a5;l[5]=a6;l[6]=a7;l[7]=a8;l[8]=a9;l[9]=a10;l[10]=a11;l[11]=a12;l[12]=a13;l[13]=a14;l[14]=a15;l[15]=a16;l[16]=a17;
          return create(name, l).reflectee;
        };
      case 18:
        return (a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18) {
          l[0]=a1;l[1]=a2;l[2]=a3;l[3]=a4;l[4]=a5;l[5]=a6;l[6]=a7;l[7]=a8;l[8]=a9;l[9]=a10;l[10]=a11;l[11]=a12;l[12]=a13;l[13]=a14;l[14]=a15;l[15]=a16;l[16]=a17;l[17]=a18;
          return create(name, l).reflectee;
        };
      case 19:
        return (a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19) {
          l[0]=a1;l[1]=a2;l[2]=a3;l[3]=a4;l[4]=a5;l[5]=a6;l[6]=a7;l[7]=a8;l[8]=a9;l[9]=a10;l[10]=a11;l[11]=a12;l[12]=a13;l[13]=a14;l[14]=a15;l[15]=a16;l[16]=a17;l[17]=a18;l[18]=a19;
          return create(name, l).reflectee;
        };
      case 20:
        return (a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20) {
          l[0]=a1;l[1]=a2;l[2]=a3;l[3]=a4;l[4]=a5;l[5]=a6;l[6]=a7;l[7]=a8;l[8]=a9;l[9]=a10;l[10]=a11;l[11]=a12;l[12]=a13;l[13]=a14;l[14]=a15;l[15]=a16;l[16]=a17;l[17]=a18;l[18]=a19;l[19]=a20;
          return create(name, l).reflectee;
        };
      case 21:
        return (a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21) {
          l[0]=a1;l[1]=a2;l[2]=a3;l[3]=a4;l[4]=a5;l[5]=a6;l[6]=a7;l[7]=a8;l[8]=a9;l[9]=a10;l[10]=a11;l[11]=a12;l[12]=a13;l[13]=a14;l[14]=a15;l[15]=a16;l[16]=a17;l[17]=a18;l[18]=a19;l[19]=a20;l[20]=a21;
          return create(name, l).reflectee;
        };
      case 22:
        return (a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22) {
          l[0]=a1;l[1]=a2;l[2]=a3;l[3]=a4;l[4]=a5;l[5]=a6;l[6]=a7;l[7]=a8;l[8]=a9;l[9]=a10;l[10]=a11;l[11]=a12;l[12]=a13;l[13]=a14;l[14]=a15;l[15]=a16;l[16]=a17;l[17]=a18;l[18]=a19;l[19]=a20;l[20]=a21;l[21]=a22;
          return create(name, l).reflectee;
        };
      case 23:
        return (a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23) {
          l[0]=a1;l[1]=a2;l[2]=a3;l[3]=a4;l[4]=a5;l[5]=a6;l[6]=a7;l[7]=a8;l[8]=a9;l[9]=a10;l[10]=a11;l[11]=a12;l[12]=a13;l[13]=a14;l[14]=a15;l[15]=a16;l[16]=a17;l[17]=a18;l[18]=a19;l[19]=a20;l[20]=a21;l[21]=a22;l[22]=a23;
          return create(name, l).reflectee;
        };
      case 24:
        return (a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24) {
          l[0]=a1;l[1]=a2;l[2]=a3;l[3]=a4;l[4]=a5;l[5]=a6;l[6]=a7;l[7]=a8;l[8]=a9;l[9]=a10;l[10]=a11;l[11]=a12;l[12]=a13;l[13]=a14;l[14]=a15;l[15]=a16;l[16]=a17;l[17]=a18;l[18]=a19;l[19]=a20;l[20]=a21;l[21]=a22;l[22]=a23;l[23]=a24;
          return create(name, l).reflectee;
        };
      case 25:
        return (a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25) {
          l[0]=a1;l[1]=a2;l[2]=a3;l[3]=a4;l[4]=a5;l[5]=a6;l[6]=a7;l[7]=a8;l[8]=a9;l[9]=a10;l[10]=a11;l[11]=a12;l[12]=a13;l[13]=a14;l[14]=a15;l[15]=a16;l[16]=a17;l[17]=a18;l[18]=a19;l[19]=a20;l[20]=a21;l[21]=a22;l[22]=a23;l[23]=a24;l[24]=a25;
          return create(name, l).reflectee;
        };
    }
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
      ClassMirror pTypeMirror = (p.type as ClassMirror);
      var pType = pTypeMirror.reflectedType;
      var annotationType = p.metadata.isNotEmpty ? p.metadata.first.type.reflectedType : null;
      return new Key(pType, annotationType);
    }, growable:false);
  }

  ClassMirror _reflectClass(Type type) {
    ClassMirror classMirror = reflectType(type);
    if (classMirror is TypedefMirror) {
      throw new DynamicReflectorError("No implementation provided for "
                                      "${getSymbolName(classMirror.qualifiedName)} typedef!");
    }

    MethodMirror ctor = classMirror.declarations[classMirror.simpleName];

    if (ctor == null) {
      throw new DynamicReflectorError("Unable to find default constructor for $type. "
          "Make sure class has a default constructor." + (1.0 is int ?
          "Make sure you have correctly configured @MirrorsUsed." : ""));
    }
    return classMirror;
  }

  void addAll(Map<Type, Function> factories, Map<Type, List<Key>> parameterKeys) => null;
  void add(Type type, Function factory, List<Key> parameterKeys) => null;
}
