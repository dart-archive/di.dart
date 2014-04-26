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

