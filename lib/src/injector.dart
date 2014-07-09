import '../di.dart';

abstract class Injector {
  /**
   * Name of the injector or null if none was given.
   */
  @deprecated
  String get name;

  /**
   * The parent injector or null if root.
   */
  Injector get parent;

  /**
   * The root injector.
   */
  @deprecated
  Injector get root;

  /**
   * [Type]s of the [Provider]s explicitly bound to the injector or an ancestor.
   * If the root injector sets [allowImplicitInjection] to false, then this
   * is simply all the types that the injector can return.
   */
  Set<Type> get types;

  /**
   * Whether the injector allows injecting a type to which no [Provider] is
   * bound.  Note that this setting only matters for the root injector.
   */
  @deprecated
  bool get allowImplicitInjection;

  /**
   * Returns the instance associated with the given key (i.e. [type] and
   * [annotation]) according to the following rules.
   *
   * Let I be the nearest ancestor injector (possibly this one) that both
   *
   * - binds some [Provider] P to [key] and
   * - P's visibility declares that I is visible to this injector.
   *
   * If there is no such I, then
   *
   * - if [allowImplicitInjection] is true for the root injector, let I be the
   *   root injector and P be a default [Provider] for [type].
   * - if [allowImplicitInjection] is false for the root injector, throw
   *   [NoProviderError].
   *
   * Once I and P are found, if I already created an instance for the key,
   * it is returned.  Otherwise, P is used to create an instance, using I
   * as an [ObjectFactory] to resolve the necessary dependencies.
   */
  dynamic get(Type type, [Type annotation]);

  /**
   * See [get].
   */
  dynamic getByKey(Key key);

  /**
   * Creates a child injector.
   *
   * [modules] overrides bindings of the parent.
   *
   * [forceNewInstances] is a list, each element of which is a [Key] or a
   * [Type] (for convenience when no annotation is needed).  For each element K,
   * the child injector will have a new binding to the same [Provider] P that
   * the parent injector would have provided, that is, P is the [Provider] of
   * the nearest ancestor of the parent injector that binds K.  Note that this
   * differs from how [get] finds P in that visibility is not taken into
   * account.
   *
   * Thus, if a descendant D of the child requests an instance for K, the child
   * will mask any binding for K made by a proper ancestor injector, provided
   * that P's visibility reveals the child's binding to D.
   * For example, if the child has no proper descendant and P's visibility
   * deems that the child is visible to the child itself, then the first
   * request for the child to get an instance for K will trigger the creation of
   * a new instance.
   *
   * [name] is used for error reporting.
   */
  Injector createChild(List<Module> modules,
                       {List forceNewInstances, String name});
}
