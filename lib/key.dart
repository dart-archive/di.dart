part of di;

class Key {
  final Type type;
  final Type annotation;

  Key(this.type, [this.annotation]);

  bool operator ==(other) =>
      other is Key && other.type == type && other.annotation == annotation;

  int get hashCode => type.hashCode + annotation.hashCode;

  String toString() => annotation == null ?
      type.toString() :
      '${type.toString()} annotated with: ${annotation.toString()}';
}
