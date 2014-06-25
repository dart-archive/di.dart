part of di;

abstract class BaseError extends Error {
  final String message;
  String toString() => message;
  BaseError(this.message);
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

    StringBuffer buffer = new StringBuffer();
    buffer.write("(resolving ");
    buffer.write(keysToPrint.join(' -> '));
    buffer.write(")");
    return buffer.toString();
  }

  void appendKey(Key key) {
   keys.add(key);
  }

  String toString();
}

class NoProviderError extends ResolvingError {
  static final List<Key> _PRIMITIVE_TYPES = <Key>[
      new Key(num), new Key(int), new Key(double), new Key(String),
      new Key(bool)
  ];
  final NoProviderError parent;

  String toString(){
    var root = keys.first;
    if (_PRIMITIVE_TYPES.contains(root)) {
      return 'Cannot inject a primitive type of $root! $resolveChain';
    }
    return "No provider found for $root! $resolveChain";
  }
  NoProviderError(key): super(key);
}

class CircularDependencyError extends ResolvingError {
  String toString() => "Cannot resolve a circular dependency! $resolveChain";
  CircularDependencyError(key) : super(key);
}

class NoParentError extends BaseError {
  NoParentError(message) : super(message);
}
