part of di;

class Key {
  Type type;
  Type annotation;

  Key(this.type) {}

  Key.withAnnotation(this.type, this.annotation ) {}

  // Override hashCode using strategy from Effective Java, Chapter 11.
  int get hashCode {
    int result = 17;
    result = 37 * result + type.hashCode;
    result = 37 * result + annotation.hashCode;
    return result;
  }

  // You should generally implement operator== if you override hashCode.
  bool operator==(other) {
    if (other is! Key) return false;
    Key key = other;
    return (key.type == type && key.annotation == annotation);
  }

  String toString() {
    String asString = this.type.toString();
    if (this.annotation != null)
      asString += " annotated with: " + this.annotation.toString();
    return asString;
  }
}