library di.type_literal;

/**
* TypeLiteral is used to bind parameterized types.
*/
class TypeLiteral<T> {
  Type get type => T;
}