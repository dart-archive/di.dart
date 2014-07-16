library di.reflector_null;

import '../key.dart';
import 'reflector.dart';
import 'errors.dart';

TypeReflector getReflector() => new NullReflector();

class NullReflector extends TypeReflector {
  factoryFor(Type type) => throw new NullReflectorError();
  parameterKeysFor(Type type) => throw new NullReflectorError();
  addAll(Map<Type, Function> factories, Map<Type, List<Key>> parameterKeys) =>
      throw new NullReflectorError();
  add(Type type, Function factory, List<Key> parameterKeys) =>
      throw new NullReflectorError();
}

class NullReflectorError extends BaseError {
  NullReflectorError()
      : super("Module.DEFAULT_REFLECTOR not initialized for dependency injection."
              "http://goo.gl/XFXx9G");
}
