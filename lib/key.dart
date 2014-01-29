part of di;

class Key {
  Type type;
  Set<Type> annotations;

  Key(this.type, {List<Type> annotations}) {
    this.annotations = ( annotations != null ?
        new HashSet.from(annotations) : new HashSet() );
  }

  // TODO: see if we can get a better hashCode algorithm.
  int get hashCode {
    int result = 17;
    result = 37 * result + type.hashCode;
    return result;
  }

  bool operator==(other) {
    return other is Key && other.type == type &&
        other.annotations.containsAll(annotations);
  }

  String toString() {
    String asString = type.toString();
    if (!annotations.isEmpty)
      asString += " annotated with: [" + annotations.join(", ") + "]";
    return asString;
  }
}