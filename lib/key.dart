library di.key;

/**
 * Key to which an [Injector] binds a [Provider].  This is a pair consisting of
 * a [type] and an optional [annotation].
 */
class Key {
  static Map<Type, Map<Type, Key>> _typeToAnnotationToKey = {};
  static int _numInstances = 0;
  /// The number of instances of [Key] created.
  static int get numInstances => _numInstances;

  final Type type;
  /// Optional.
  final Type annotation;
  /// Assigned via auto-increment.
  final int id;

  int get hashCode => id;

  /**
   * Creates a new key or returns one from a cache if given the same inputs that
   * a previous call had.  E.g. `identical(new Key(t, a), new Key(t, a))` holds.
   */
  factory Key(Type type, [Type annotation]) {
    // Don't use Map.putIfAbsent -- too slow!
    var annotationToKey = _typeToAnnotationToKey[type];
    if (annotationToKey == null) {
      _typeToAnnotationToKey[type] = annotationToKey = {};
    }
    Key key = annotationToKey[annotation];
    if (key == null) {
      annotationToKey[annotation] =
          key = new Key._(type, annotation, _numInstances++);
    }
    return key;
  }

  Key._(this.type, this.annotation, this.id);

  String toString() {
    String asString = type.toString();
    if (annotation != null) {
      asString += ' annotated with: $annotation';
    }
    return asString;
  }
}
