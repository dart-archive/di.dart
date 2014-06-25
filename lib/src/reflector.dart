part of di;

// TODO: add toClosure in addition to toFactory
// TODO: write a verifier that toClosure signature matches inject attribute!
// TODO: write tests

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
    : super("No default dependency injection reflector set for Module. \n"
    "To use recommended behavior, which uses mirrors to resolve dependencies "
    "when transformers are off and generated type factories when transformers"
    "are enabled, add the following line to the main function before any modules"
    "are instantiated:\n"
    "setupModuleTypeReflector();\n"
    "with the import:\n"
    "import 'package:di/di_dynamic.dart';\n"
    "To always use static code generation instead, call the "
    "initializeGeneratedTypeFactories function provided by the transformer generated"
    "file instead.");
}
