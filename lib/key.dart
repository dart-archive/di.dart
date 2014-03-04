part of di;

class Key {
  final Type type;
  final Iterable<Type> annotations;
  int _hashCode;

  Key(this.type, {Iterable<Type> this.annotations: const []});

  int get hashCode {
    if (_hashCode != null) return _hashCode;
    int result = 629 + type.hashCode;
    if (annotations != null) {
      annotations.forEach((a) => result += a.hashCode);
    }
    _hashCode = result;
    return result;
  }

  bool operator==(other) {
    return other is Key && other.type == type &&
        other.annotations.length == annotations.length &&
        other.annotations.every(annotations.contains);
  }

  String toString() {
    String asString = type.toString();
    if (annotations.isNotEmpty) {
      asString += " annotated with: [" + annotations.join(", ") + "]";
    }
    return asString;
  }
}