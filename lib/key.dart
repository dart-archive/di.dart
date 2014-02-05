part of di;

class Key {
  final Type type;
  final UnmodifiableSetView<Type> annotations;
  int _hashCode;

  Key(this.type, {List<Type> annotations}) : this.annotations =
      new UnmodifiableSetView(annotations != null ? annotations.toSet() :
        new HashSet()) {
  }

  int get hashCode {
    if (_hashCode != null)
      return _hashCode;

    int result = 17;
    result = 37 * result + type.hashCode;
    annotations.forEach((a) => result += a.hashCode);
    _hashCode = result;

    return _hashCode;
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