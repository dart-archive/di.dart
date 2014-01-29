part of di;

class Key {
  final Type type;
  final Set<Type> annotations;

  Key(this.type, {List<Type> annotations}) : this.annotations =
      (annotations != null ? annotations.toSet() : new HashSet()) {
  }

  int get hashCode {
    return 629 + type.hashCode;
  }

  bool operator==(other) {
    return other is Key && other.type == type &&
        other.annotations.length == annotations.length &&
        other.annotations.containsAll(annotations);
  }

  String toString() {
    String asString = type.toString();
    if (annotations.isNotEmpty)
      asString += " annotated with: [" + annotations.join(", ") + "]";
    return asString;
  }
}