part of di;

/**
 * Maintains a set of bindings from [Type]... [Type]... [Key]...??
 */
abstract class Injector {
  /**
   * Name of the injector or null if none was given.
   */
  String get name;

  /**
   * The parent injector or null if root.
   */
  Injector get parent;

  /**
   * The root injector.
   */
  Injector get root;

  /**
   * Types the injector can return.
   */
  Set<Type> get types;

  /**
   * Whether the injector allows implicit injection -- resolving types
   * that were not explicitly bound in the module(s).
   */
  bool get allowImplicitInjection;

  /**
   * Gets the instance associated with the given key (i.e. [type] and
   * [annotation]).
   *
   * If the injector has already instantiated the instance, this returns it.
   * Otherwise the injector resolves its dependencies, instantiates it with a
   * [Provider] and returns it.
   *
   * The way the injector combines dependencies to instantiate the instance is
   * determined by the nearest ancestor injector that visibly binds the key to
   * a [Provider].  If no ancestor has such a binding, then
   * - if [allowImplicitInjection] is true, an implicit binding is used.  That
   *   is, an instance of type [type] is instantiated.
   * - if [allowImplicitInjection] is false, throws [NoProviderError].
   */
  dynamic get(Type type, [Type annotation]);

  /**
   * Gets the instance associated with [key].
   *
   * If the injector already has an instance for [key], it returns this
   * instance. Otherwise, the injector resolves all of its dependencies,
   * instantiates a new instance, and returns it.
   *
   * If there is no binding for given key, injector asks parent injector.
   */
  dynamic getByKey(Key key);

  /**
   * Creates a child injector.
   *
   * The child injector can override any bindings by adding additional [modules].
   *
   * It also accepts a list of tokens that a new instance should be forced.
   * That means, even if some parent injector already has an instance for this
   * token, there will be a new instance created in the child injector.
   */
  Injector createChild(List<Module> modules,
                       {List forceNewInstances, String name});
}
