library di.reflector;

import "../key.dart";

abstract class TypeReflector {
  /**
   * Returns a factory function that knows how to construct an instance of a type.
   *
   * This interface is type based because there is only one factory for each
   * type, no matter what the annotations are. However, the parameters returned
   * are keys because annotations matter in that case so the injector knows
   * what to inject. This leads to some performance loss from type comparison
   * and key creation in DynamicTypeFactories but TypeReflector should only be
   * used during module binding.
   */
  Function factoryFor(Type type);

  /**
   * Returns keys of the items that must be injected into the corresponding
   * Factory that TypeReflector.factoryFor returns.
   */
  List<Key> parameterKeysFor(Type type);

  /**
   * Adds these factories and parameterKeys to the reflector, so that future calls
   * to factoryFor and parameterKeysFor will return these new values.
   *
   * Overwrites in static implementation, no-op in dynamic implementation
   */
  void addAll(Map<Type, Function> factories, Map<Type, List<Key>> parameterKeys);
  void add(Type type, Function factory, List<Key> parameterKeys);
}
