library di.module;

import 'dart:collection';

import 'injector.dart';

typedef dynamic FactoryFn(Injector injector);

/**
 * Creation strategy is asked to return an instance of the type after
 * [Injector.get] locates the defining injector that has no instance cached.
 * [directInstantation] is true when an instance is created directly from
 * [Injector.instantiate].
 */
typedef dynamic CreationStrategy(
  Injector requesting,
  Injector defining,
  dynamic factory()
);

/**
 * Visibility determines if the instance in the defining module is visible to
 * the requesting injector. If true is returned, then the instance from the
 * defining injector is provided. If false is returned, the injector keeps
 * walking up the tree to find another visible instance.
 */
typedef bool Visibility(Injector requesting, Injector defining);


/**
 * A collection of type bindings. Once the module is passed into the injector,
 * the injector creates a copy of the module and all subsequent changes to the
 * module have no effect.
 */
class Module {
  final Map<Type, Binding> _bindings = new HashMap<Type, Binding>();
  final List<Module> _childModules = <Module>[];

  /**
   * Compiles and returs bindings map by performing depth-first traversal of the
   * child (installed) modules.
   */
  Map<Type, Binding> get bindings {
    Map<Type, Binding> res = new HashMap<Type, Binding>();
    _childModules.forEach((child) => res.addAll(child.bindings));
    res.addAll(_bindings);
    return res;
  }

  /**
   * Register binding to a concrete value.
   *
   * The [value] is what actually will be injected.
   */
  void value(Type id, value,
      {CreationStrategy creation, Visibility visibility}) {
    _bindings[id] = new ValueBinding(value, creation, visibility);
  }

  /**
   * Register binding to a [Type].
   *
   * The [implementedBy] will be instantiated using [new] operator and the
   * resulting instance will be injected. If no type is provided, then it's
   * implied that [id] should be instantiated.
   */
  void type(Type id, {Type implementedBy, CreationStrategy creation,
      Visibility visibility}) {
    _bindings[id] = new TypeBinding(implementedBy == null ? id : implementedBy,
        creation, visibility);
  }

  /**
   * Register binding to a factory function.abstract
   *
   * The [factoryFn] will be called and all its arguments will get injected.
   * The result of that function is the value that will be injected.
   */
  void factory(Type id, FactoryFn factoryFn,
      {CreationStrategy creation, Visibility visibility}) {
    _bindings[id] = new FactoryBinding(factoryFn, creation, visibility);
  }

  /**
   * Installs another module into this module. Bindings defined on this module
   * take precidence over the installed module.
   */
  void install(Module module) => _childModules.add(module);
}

/** Deafault creation strategy is to instantiate on the defining injector. */
dynamic _defaultCreationStrategy(Injector requesting, Injector defining,
    dynamic factory()) => factory();

/** By default all values are visible to child injectors. */
bool _defaultVisibility(_, __) => true;


abstract class Binding {
  final CreationStrategy creationStrategy;
  final Visibility visibility;

  Binding(_creationStrategy, _visibility)
      : creationStrategy = _creationStrategy == null ?
            _defaultCreationStrategy : _creationStrategy,
        visibility = _visibility == null ?
            _defaultVisibility : _visibility;
}

class ValueBinding extends Binding {
  final Object value;

  ValueBinding(this.value, [CreationStrategy creationStrategy,
                            Visibility visibility])
      : super(creationStrategy, visibility);
}

class TypeBinding extends Binding {
  final Type type;

  TypeBinding(this.type, [CreationStrategy creationStrategy,
                          Visibility visibility])
      : super(creationStrategy, visibility);
}

class FactoryBinding extends Binding {
  final FactoryFn factoryFn;

  FactoryBinding(this.factoryFn, [CreationStrategy creationStrategy,
                                  Visibility visibility])
      : super(creationStrategy, visibility);
}