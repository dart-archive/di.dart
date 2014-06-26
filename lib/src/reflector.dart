library di.reflector;

import "../key.dart";
import "errors.dart";
import "module.dart";

abstract class TypeReflector {
  /**
   * Returns a [Factory] that knows how to construct an instance of a type.
   *
   * This interface is type based because there is only one factory for each
   * type, no matter what the annotations are. However, the parameters returned
   * are keys because annotations matter in that case so the injector knows
   * what to inject. This leads to some performance loss from type comparison
   * and key creation in DynamicTypeFactories but TypeReflector should only be
   * used during module binding.
   */
  Factory factoryFor(Type type);

  /**
   * Returns keys of the items that must be injected into the corresponding
   * Factory that TypeReflector.factoryFor returns.
   */
  List<Key> parameterKeysFor(Type type);
}

class NullReflector extends TypeReflector {
  factoryFor(Type type) => throw new NullReflectorError();
  parameterKeysFor(Type type) => throw new NullReflectorError();
}

class NullReflectorError extends BaseError {
  NullReflectorError()
    : super("Module.DEFAULT_REFLECTOR not initialized for dependency injection."
            "http://goo.gl/XFXx9G");
}
