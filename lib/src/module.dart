library di.module;

import "../key.dart";
import "../check_bind_args.dart" show checkBindArgs;
import "reflector.dart";
import "reflector_dynamic.dart";
import "errors.dart" show PRIMITIVE_TYPES;

DEFAULT_VALUE(_) => null;
IDENTITY(p) => p;

class Binding {
  Key key;
  List<Key> parameterKeys;
  Function factory;
  static bool printInjectWarning = true;

  _checkPrimitive(Key key) {
    if (PRIMITIVE_TYPES.contains(key)) {
      throw "Cannot bind primitive type '${key.type}'.";
    }
    return true;
  }

  void bind(k, TypeReflector reflector, {toValue: DEFAULT_VALUE,
          Function toFactory: DEFAULT_VALUE, Type toImplementation,
          List inject: const[], toInstanceOf}) {
    key = k;
    assert(_checkPrimitive(k));
    if (inject.length == 1 && isNotSet(toFactory)) {
      if (printInjectWarning) {
        try {
          throw [];
        } catch (e, stackTrace) {
          print("bind(${k.type}): Inject list without toFactory is deprecated. "
                "Use `toInstanceOf: Type|Key` instead. "
                "Called from:\n$stackTrace");
        }
        printInjectWarning = false;
      }
      toFactory = IDENTITY;
    }
    assert(checkBindArgs(toValue, toFactory, toImplementation, inject, toInstanceOf));

    if (toInstanceOf != null) {
      toFactory = IDENTITY;
      inject = [toInstanceOf];
    }
    if (isSet(toValue)) {
      factory = () => toValue;
      parameterKeys = const [];
    } else if (isSet(toFactory)) {
      factory = toFactory;
      parameterKeys = inject.map((t) {
        if (t is Key) return t;
        if (t is Type) return new Key(t);
        throw "inject must be Keys or Types. '$t' is not an instance of Key or Type.";
      }).toList(growable: false);
    } else {
      var implementationType = toImplementation == null ? key.type : toImplementation;
      parameterKeys = reflector.parameterKeysFor(implementationType);
      factory = reflector.factoryFor(implementationType);
    }
  }
}

bool isSet(val) => !identical(val, DEFAULT_VALUE);
bool isNotSet(val) => !isSet(val);

/**
 * Module contributes configuration information to an [Injector] by providing
 * a collection of type bindings that specify how each type is created.
 *
 * When an injector is created, it copies its configuration information from a
 * module. Defining additional type bindings after an injector is created has
 * no effect on that injector.
 */
class Module {
  static TypeReflector DEFAULT_REFLECTOR = getReflector();

  /**
   * A [TypeReflector] for the module to look up constructors for types when
   * toFactory and toValue are not specified. This is done with mirroring or
   * pre-generated typeFactories.
   */
  final TypeReflector reflector;

  Module(): reflector = DEFAULT_REFLECTOR;

  /**
   * Use a custom reflector instead of the default. Useful for testing purposes.
   */
  Module.withReflector(this.reflector);

  Map<Key, Binding> bindings = new Map<Key, Binding>();

  /**
   * Copies all bindings of [module] into this one. Overwriting when conflicts are found.
   */
  void install(Module module) => bindings.addAll(module.bindings);

  /**
   * Registers a binding for a given [type].
   *
   * The default behavior is to simply instantiate the type.
   *
   * The following parameters can be specified:
   *
   * * [toImplementation]: The given type will be instantiated using the [new]
   *   operator and the resulting instance will be injected.
   * * [toFactory]: The result of the factory function called with the types of [inject] as
   *   arguments is the value that will be injected.
   * * [toValue]: The given value will be injected.
   * * [toInstanceOf]: An instance of the given type will be fetched with DI. This is shorthand for
   *   toFactory: (x) => x, inject: [X].
   * * [withAnnotation]: Type decorated with additional annotation.
   *
   * Up to one (0 or 1) of the following parameters can be specified at the
   * same time: [toImplementation], [toFactory], [toValue], [toInstanceOf].
   */
  void bind(Type type, {dynamic toValue: DEFAULT_VALUE,
      Function toFactory: DEFAULT_VALUE, Type toImplementation,
      List inject: const [], toInstanceOf, Type withAnnotation}) {
    bindByKey(new Key(type, withAnnotation), toValue: toValue, toInstanceOf: toInstanceOf,
        toFactory: toFactory, toImplementation: toImplementation, inject: inject);
  }

  /**
   * Same as [bind] except it takes [Key] instead of
   * [Type] [withAnnotation] combination. Faster.
   */
  void bindByKey(Key key, {dynamic toValue: DEFAULT_VALUE, toInstanceOf,
      Function toFactory: DEFAULT_VALUE, List inject: const [], Type toImplementation}) {

    var binding = new Binding();
    binding.bind(key, reflector, toValue: toValue, toFactory: toFactory, toInstanceOf: toInstanceOf,
                 toImplementation: toImplementation, inject: inject);
    bindings[key] = binding;
  }
}
