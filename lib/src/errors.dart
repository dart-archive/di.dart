library di.errors;

import '../key.dart';

abstract class BaseError extends Error {
  final String message;
  BaseError(this.message);
  String toString() => message;
}

class DynamicReflectorError extends BaseError {
  DynamicReflectorError(message) : super(message);
}

abstract class ResolvingError extends Error {

  List<Key> keys;
  ResolvingError(key): keys = [key];

  String get resolveChain {
    var keysToPrint = [];
    var seenKeys = new Set();
    for (Key key in keys.reversed) {
      keysToPrint.add(key);
      if (!seenKeys.add(key)) break;
    }

    StringBuffer buffer = new StringBuffer()
        ..write("(resolving ")
        ..write(keysToPrint.join(" -> "))
        ..write(")");
    return buffer.toString();
  }

  void appendKey(Key key) {
   keys.add(key);
  }

  String toString();
}

class NoProviderError extends ResolvingError {
  NoProviderError(key): super(key);

  static final List<Key> _PRIMITIVE_TYPES = <Key>[
      new Key(num), new Key(int), new Key(double), new Key(String),
      new Key(bool)
  ];

  String toString(){
    var root = keys.first;
    if (_PRIMITIVE_TYPES.contains(root)) {
      return "Cannot inject a primitive type of $root! $resolveChain";
    }
    return "No provider found for $root! $resolveChain";
  }
}

class CircularDependencyError extends ResolvingError {
  CircularDependencyError(key) : super(key);
  String toString() => "Cannot resolve a circular dependency! $resolveChain";
}

class NoGeneratedTypeFactoryError extends BaseError {
  NoGeneratedTypeFactoryError(Type type): super(type.toString());
  String toString() =>
      "Type '$message' not found in generated typeFactory maps. Is the type's "
      "constructor annotated for injection?";
}
