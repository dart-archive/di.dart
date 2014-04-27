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

  /**
   * Instance controlled in the sense that 2 [Key]s with the same [type] and
   * [annotation] will be identical.
   */
  factory Key(Type type, [Type annotation]) {
    var annotationToKey = _typeToAnnotationToKey.putIfAbsent(type, () => {});
    return annotationToKey.putIfAbsent(
        annotation, () => new Key._(type, annotation, _numInstances++));
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
