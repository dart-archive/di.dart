library di_static;

/// same as di.dart except without reflector_dynamic export (no mirror import)
export 'key.dart' show Key, key;
export 'src/injector.dart' show Injector, ModuleInjector;
export 'src/module.dart' show Binding, DEFAULT_VALUE;
export 'src/reflector.dart' show TypeReflector;
export 'src/errors.dart' hide BaseError;
export 'annotations.dart';
