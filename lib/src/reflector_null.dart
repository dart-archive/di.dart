library di.reflector_null;

import '../key.dart';
import 'reflector.dart';
import 'errors.dart';

TypeReflector getReflector() => new NullReflector();

class NullReflector extends TypeReflector {
  Function factoryFor(Type type) => throw new NullReflectorError();

  List<Key> parameterKeysFor(Type type) => throw new NullReflectorError();

  void addAll(Map<Type, Function> factories, Map<Type, List<Key>> parameterKeys) =>
      throw new NullReflectorError();

  void add(Type type, Function factory, List<Key> parameterKeys) =>
      throw new NullReflectorError();
}

class NullReflectorError extends BaseError {
  NullReflectorError()
      : super("Module.DEFAULT_REFLECTOR not initialized for dependency injection."
              "http://goo.gl/XFXx9G");
}
