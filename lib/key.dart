part of di;

int _uniqKey = 0;
Map<int, int> hashToKey = {};

class Key {
  final Type type;
  final Type annotation;
  int hashCode;
  int key;

  Key(this.type, [this.annotation]) {
    hashCode = type.hashCode + annotation.hashCode;
    key = hashToKey.putIfAbsent(hashCode, () => _uniqKey++);
  }

  bool operator ==(other) =>
      other is Key && other.hashCode == hashCode;


  String toString() {
    String asString = type.toString();
    if (annotation != null) {
      asString += ' annotated with: ${annotation.toString()}';
    }
    return asString;
  }
}
