library di.injector;

import 'module.dart';

abstract class Injector {

  /**
   * Returns the name of the injector or null of none is given.
   */
  String get name;

  /**
   * Returns the parent injector or null if root.
   */
  Injector get parent;

  /**
   * Get an instance for given token ([Type]).
   *
   * If the injector already has an instance for this token, it returns this
   * instance. Otherwise, injector resolves all its dependencies, instantiate
   * new instance and returns this instance.
   *
   * If there is no binding for given token, injector asks parent injector.
   *
   * If there is no parent injector, an implicit binding is used. That is,
   * the token ([Type]) is instantiated.
   */
  dynamic get(Type type);

  /**
   * Return a list of all types which the injector can return
   */
  Set<Type> get types;

  /**
   * Create a child injector.
   *
   * Child injector can override any bindings by adding additional modules.
   *
   * It also accepts a list of tokens that a new instance should be forced.
   * That means, even if some parent injector already has an instance for this
   * token, there will be a new instance created in the child injector.
   */
  Injector createChild(List<Module> modules, {List<Type> forceNewInstances,
                                              String name});
}
