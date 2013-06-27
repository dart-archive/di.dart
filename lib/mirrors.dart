library mirrors;

import 'dart:mirrors';
export 'dart:mirrors';

Map<Symbol, ClassMirror> _classMirrorCache = new Map<Symbol, ClassMirror>();

// Hack because we can't get a [ClassMirror] from a [Symbol].
ClassMirror getClassMirrorBySymbol(Symbol id) {
  var mirror = _classMirrorCache[id];
  if (mirror == null) {
    for (var lib in currentMirrorSystem().libraries.values) {
      if (lib.classes.containsKey(id)) {
        mirror = lib.classes[id];
      }
    }
    _classMirrorCache[id] = mirror;
  }
  return mirror;
}

String getSymbolName(Symbol symbol) => MirrorSystem.getName(symbol);

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

Symbol getTypeSymbol(Type type) => cachedReflectClass(type).simpleName;
