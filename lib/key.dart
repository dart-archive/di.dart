library di.key;

int _numKeyIds = 0;
int get numKeyIds => _numKeyIds;

Map<int, Key> _hashToKey = {};

/**
 * Key to which an [Injector] binds a [Provider].  This is a pair consisting of
 * a [type] and an optional [annotation].
 */
class Key {
  final Type type;
  /// Optional.
  final Type annotation;
  final int hashCode;
  /// Assigned via auto-increment.
  final int id;

  factory Key(Type type, [Type annotation]) {
    // This would be a dangerous hash code if the hash codes of Types were
    // likely to have arithmetic relations or if someone were tempted to
    // interchange type and annotation, but
    // (1) a type derives its hash code from its name, and Strings have large,
    // well-distributed hash codes; and
    // (2) we anticipate that no one will attempt to inject an annotation.
    var hashCode = type.hashCode + annotation.hashCode;
    var key = _hashToKey[hashCode];
    if (key != null) {
      if (key.type == type && key.annotation == annotation) {
        return key;
      } else {
        // We don't tolerate hash collisions at all.  If you have one, too bad,
        // you can't use di.
        throw new StateError(
            'hash collision: ${key.type}:${key.annotation} $type:$annotation');
      }
    }
    var key = new Key._newKey(type, annotation, _hashCode, _numKeyIds++);
    _hashToKey[hashCode] = key;
    return key;
  }

  Key._newKey(this.type, this.annotation, this.hashCode, this.id);

  bool operator ==(other) =>
      other is Key && other.hashCode == hashCode;

  String toString() {
    String asString = type.toString();
    if (annotation != null) {
      asString += ' annotated with: $annotation';
    }
    return asString;
  }
}
