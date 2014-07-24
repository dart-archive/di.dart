# 2.0.1

## Bug Fixes

- **bind:** It must accept a Key as well as a Type
  ([e01bcda6](https://github.com/angular/di.dart/commit/e01bcda6a0bb2522af03d34f08469969baed1d98),
   [#154](https://github.com/angular/di.dart/issues/154))

## Features

- **Binding:** Display call stack when usign deprecated bind() form
  ([f20b3ba7](https://github.com/angular/di.dart/commit/f20b3ba7ec45edc5b2f519974454da0e0e0f87df))

# 2.0.0

## Breaking Changes

### Calls to `StaticInjector` and `DynamicInjector` should be replaced with `ModuleInjector`
  - There are no longer `StaticInjectors` and `DynamicInjectors`. They have been replaced
    by a new `ModuleInjector` class that acts as both types of injectors.

### ModuleInjectors have no visibility
  - All bindings and instances of parent injectors are now visible in child injectors.
  - The optional argument `forceNewInstances` of `Injector.createChild` has been removed
    Instead, create a new module with bindings of the types that require new instances
    and pass that to the child injector, and the child injector will create new
    instances instead of returning the instance of the parent injector.

### Use `new ModuleInjector(modules, parent)` instead of `Injector.createChild(modules)`
  - The latter is still available but deprecated.
  - Injectors with no parent now have a dummy RootInjector instance as the parent
    Instead of checking “parent == null”, check for “parent == rootInjector”.

### Injectors no longer have a name field

### typeFactories have changed
  - Old type factories had the form `(injector) => new Instance(injector.get(dep1), … )`
  - New factories have the form:
    - `toFactory(a0, a1, …) => new Instance(a0, a1, …)`
  - When calling `Module.bind(toFactory: factory)`, there is an additional argument `inject`
    of a list of types or keys (preferred for performance) whose instances should be
    passed to the factory. The arguments passed to the factory function will be instances
    of the types in `inject`.

    Example:
    - Old code `module.bind(Car, toFactory: (i) => new Car(i.get(Engine)));`
    - New code
      - `module.bind(Car, toFactory: (engine) => new Car(engine), inject: [Engine]);`

    There is also some syntactic sugar for this special case.
    - Old code `module.bind(V8Engine, toFactory: (i) => i.get(Engine));`
    - New code `module.bind(V8Engine, toFactory: (e) => e, inject: [Engine]);`
    - With sugar `module.bind(V8Engine, toInstanceOf: Engine);`

### Modules have a `TypeReflector` instance attached
  - The `TypeReflector` is how the module will find the `toFactory` and `inject`
    arguments when not explicitly specified. This is either done with mirroring or code
    generation via transformers. Transformers will set the default to use code gen.
    For testing and other special purposes where a specific reflector is needed, use
    `new Module.withReflector(reflector)`.

### The transformer has been updated
  - Running the transformer will do the necessary code generation and edits to switch the
    default `TypeReflector` from mirroring to static factories. Enable transformer to use
    static factories, disable to use mirrors. More docs on the transformer can be found in
    `transformer.dart`
    
### Deprecated module methods removed
  - `.value`, `.type`, `.factory`, `.factoryByKey` are gone. Use `..bind`.

## Deprecations

- `module.bind()` calls specifying the `inject` parameter but no `toFactory` have been deprecated
  and will be removed in v3. Use the `toInstanceOf` parameter instead.
- The dynamic injector shim (dynamic_injector.dart) has been added to ensure backward compatibility
  with v1 and will be removed in v3.

# 1.2.3

## Features

- **module:** Expose DEFAULT_VALUE temporarily
  ([6f5d88a1](https://github.com/angular/di.dart/commit/6f5d88a16fbc7bc6658722326c1ef35d7848963e))

# 1.2.2

Reverted changes that tickled a Dart bug (to be fixed in 1.6)


# 1.2.1

Added missing library declaration to injector.

# 1.2.0

## Features

- **module:** allow v2 style toFactory binding with inject
  ([1ef6ba71](https://github.com/angular/di.dart/commit/1ef6ba7103e2aa81d30ad037666c1723834af203))


## Performance Improvements

- **injector:** inlined getProviderWithInjector
  ([d2a38b54](https://github.com/angular/di.dart/commit/d2a38b542fd773ec937ca8413fa388e30a58daa3))


# 1.1.0

## Performance Improvements

- **injector:** optimized module to injector instantiation
  ([62f22f15](https://github.com/angular/di.dart/commit/62f22f1566642cecc1b9f980475c94a7a88e9362))

# 1.0.0

Starting with this release DI is following [semver](http://semver.org).

## Bug Fixes

- **Key:** fixed bugs caused by hashCode collisions, and docs cleanup
  ([f673267d](https://github.com/angular/di.dart/commit/f673267dd2eb3a3058ec8657e4f034057e377c47),
   [#94](https://github.com/angular/di.dart/issues/94))
- **circular deps:** Improve error messages
  ([4ccdb1f0](https://github.com/angular/di.dart/commit/4ccdb1f0723c140bceb332a317884770c02ad4a8))


## Performance Improvements

- **Key:** don't use Map.putIfAbsent -- too slow
  ([0930b377](https://github.com/angular/di.dart/commit/0930b37747ebfd483db71a2b333601d77a437c10))
- **injector:** use separate structures to allow compiler optimizations
  ([f7b8af92](https://github.com/angular/di.dart/commit/f7b8af92aa903621b0dc4d1001d7329d77d698c0))


# 0.0.40

## Bug Fixes

- **module:** correctly handle null value binding
  ([ada47b36](https://github.com/angular/di.dart/commit/ada47b36f88ed4f31204baa647f957fe2547c355),
   [#93](https://github.com/angular/di.dart/issues/93))


# 0.0.39

## Bug Fixes

- **transformer:** Exception on parameterized types with implicit constructors
  ([ed0a2b02](https://github.com/angular/di.dart/commit/ed0a2b0222bb4bb3a4bd83173a3101d4196e6005))


## Features

- **module:** new binding syntax
  ([36357b5c](https://github.com/angular/di.dart/commit/36357b5c3ea0c9c81da404169166bf0aa0e957b5),
   [#90](https://github.com/angular/di.dart/issues/90))


## Breaking Changes

Module has a new API:
```dart
new Module()
    ..bind(Foo, toValue: new Foo())
    ..bind(Foo, toFactory: (i) => new Foo())
    ..bind(Foo, toImplementation: FooImpl);
```

Old methods `type`, `value` and `factory` were deprecated and will be removed in the next release.

# 0.0.38

## Fixes

- **key:** made Key part of di.dart again
  ([fe390ddf](https://github.com/angular/di.dart/commit/fe390ddf25c230e2c98cff0628297e42584f6945))


# 0.0.37

Combined with previous release (0.0.36) injector is on average 2x faster.

Before:
```
VM:
DynamicInjectorBenchmark(RunTime): 231.93784065870346 us.
StaticInjectorBenchmark(RunTime): 107.05491917353602 us.

dart2js:
DynamicInjectorBenchmark(RunTime): 2175 us.
StaticInjectorBenchmark(RunTime): 765.1109410864575 us.
```

After:

```
VM:
DynamicInjectorBenchmark(RunTime): 156.3721657544957 us.
StaticInjectorBenchmark(RunTime): 54.246114622040196 us.

dart2js:
DynamicInjectorBenchmark(RunTime): 1454.5454545454545 us.
StaticInjectorBenchmark(RunTime): 291.9281856663261 us.
```

## Bug Fixes

- **warnings:** refactored injector to fix analyzer warnings
  ([7d374b19](https://github.com/angular/di.dart/commit/7d374b196e795d9799c95a4e63cf497267604de9))

## Performance Improvements

- **injector:**
  - Make resolving a linked-list stored with the frame
  ([c588e662](https://github.com/angular/di.dart/commit/c588e662ab0f33dc645c8e170492c0c25c1085a5))
  - Do not closurize methods.
  ([5f47cbd0](https://github.com/angular/di.dart/commit/5f47cbd0dc28cb16e497baf5cfda3c6499f56eb5))
  - Do not check the circular dependency until we are 30 deep.
  ([1dedf6e3](https://github.com/angular/di.dart/commit/1dedf6e38fec4c3fc882ef59b4c4bf439d19ce0a))
  - Track resolving keys with the frame.
  ([17aeb4df](https://github.com/angular/di.dart/commit/17aeb4df59465c22cd73ae5c601cb8d0f872c57b))
- **resolvedTypes:** minor performance inmprovement in resolvedTypes
  ([ba16bde5](https://github.com/angular/di.dart/commit/ba16bde5084eb3a2291ca3d2fb38de06ac734b03))


# 0.0.36

## Performance Improvements

- **injector:**
  - skip _checkKeyConditions in dart2js
  ([6763552a](https://github.com/angular/di.dart/commit/6763552adccdc41ef1043930ea50e0425509e6c5))
  - +29%. Use an array for type lookup instead of a map.

