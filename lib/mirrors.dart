library mirrors;

import 'dart:mirrors';
export 'dart:mirrors';

Map<Symbol, ClassMirror> _classMirrorCache = new Map<Symbol, ClassMirror>();

const List<Symbol> PRIMITIVE_TYPES = const <Symbol>[
  const Symbol('dart.core.dynamic'), const Symbol('dart.core.num'),
  const Symbol('dart.core.int'), const Symbol('dart.core.double'),
  const Symbol('dart.core.String'), const Symbol('dart.core.bool')
];

const Map<String, String> _PRIMITIVE_TYPE_SIMPLE_NAMES = const {
  'dart.core.dynamic': 'dynamic',
  'dart.core.num': 'num',
  'dart.core.int': 'int',
  'dart.core.double': 'double',
  'dart.core.String': 'String',
  'dart.core.bool': 'bool'
};

// Hack because we can't get a [ClassMirror] from a [Symbol].
ClassMirror getClassMirrorBySymbol(Symbol id) {
  var mirror = _classMirrorCache[id];
  if (mirror == null) {
    for (var lib in currentMirrorSystem().libraries.values) {
      for (DeclarationMirror decl in lib.declarations.values) {
        if (decl is ClassMirror && decl.qualifiedName == id) {
          mirror = decl;
          break;
        }
      }
    }
    _classMirrorCache[id] = mirror;
  }
  return mirror;
}

String getSymbolName(Symbol symbol) => MirrorSystem.getName(symbol);

String getSymbolSimpleName(Symbol symbol) {
  if (PRIMITIVE_TYPES.contains(symbol)) {
    return _PRIMITIVE_TYPE_SIMPLE_NAMES[getSymbolName(symbol)];
  }
  return MirrorSystem.getName(getClassMirrorBySymbol(symbol).simpleName);
}

Map<Type, ClassMirror> _reflectionCache = new Map<Type, ClassMirror>();

/// Cached version of [reflectClass].
ClassMirror cachedReflectClass(Type type) {
  ClassMirror mirror = _reflectionCache[type];
  if (mirror == null) {
    mirror = reflectClass(type);
    _reflectionCache[type] = mirror;
  }
  return mirror;
}

Symbol getTypeSymbol(Type type) => cachedReflectClass(type).qualifiedName;
