library di.module;

import "../key.dart";
import "../check_bind_args.dart" show checkBindArgs;
import "reflector.dart";

DEFAULT_VALUE(_) => null;
IDENTITY(p) => p;

class Binding {
  Key key;
  List<Key> parameterKeys;
  Function factory;

  Binding();

  void bind(k, TypeReflector reflector, {dynamic toValue: DEFAULT_VALUE,
          Function toFactory: DEFAULT_VALUE, Type toImplementation,
          List inject: const[]}) {
    key = k;
    if (inject.length == 1 && isNotSet(toFactory)) {
      toFactory = IDENTITY;
    }
    assert(checkBindArgs(toValue, toFactory, toImplementation, inject));

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
bool isNotSet(val) => identical(val, DEFAULT_VALUE);

/**
 * Module contributes configuration information to an [Injector] by providing
 * a collection of type bindings that specify how each type is created.
 *
 * When an injector is created, it copies its configuration information from a
 * module. Defining additional type bindings after an injector is created have
 * no effect on that injector.
 */
class BaseModule {
  static TypeReflector DEFAULT_REFLECTOR = new NullReflector();
  final TypeReflector reflector;

  BaseModule(): reflector = DEFAULT_REFLECTOR;
  BaseModule.withReflector(this.reflector);

  Map<Key, Binding> bindings = new Map<Key, Binding>();

  /**
   * Copies all bindings of [module] into this one. Overwriting when conflicts are found.
   */
  install(BaseModule module) => module.bindings.forEach((key, binding) => bindings[key] = binding);

  /**
   * Registers a binding for a given [type].
   *
   * The default behavior is to simply instantiate the type.
   *
   * The following parameters can be specified:
   *
   * * [toImplementation]: The given type will be instantiated using the [new]
   *   operator and the resulting instance will be injected.
   * * [toFactory]: The result of the factory function is the value that will
   *   be injected.
   * * [toValue]: The given value will be injected.
   * * [withAnnotation]: Type decorated with additional annotation.
   *
   * Up to one (0 or 1) of the following parameters can be specified at the
   * same time: [toImplementation], [toFactory], [toValue].
   */
  void bind(Type type, {dynamic toValue: DEFAULT_VALUE,
      Function toFactory: DEFAULT_VALUE, Type toImplementation,
      List inject: const [], Type withAnnotation}) {
    bindByKey(new Key(type, withAnnotation), toValue: toValue,
        toFactory: toFactory, toImplementation: toImplementation, inject: inject);
  }

  /**
   * Same as [bind] except it takes [Key] instead of
   * [Type] [withAnnotation] combination. Faster.
   */
  void bindByKey(Key key, {dynamic toValue: DEFAULT_VALUE,
      Function toFactory: DEFAULT_VALUE, List inject: const [], Type toImplementation}) {

    var binding = new Binding();
    binding.bind(key, reflector, toValue: toValue, toFactory: toFactory,
                 toImplementation: toImplementation, inject: inject);
    bindings[key] = binding;
  }
}
