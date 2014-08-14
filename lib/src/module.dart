library di.module;

import 'reflector.dart' show TypeReflector;
import 'reflector_dynamic.dart';

import 'module_static.dart' as module_static;
export 'module_static.dart' hide Module;

class Module extends module_static.Module {
  static TypeReflector DEFAULT_REFLECTOR = getReflector();

  Module() : super.withReflector(getReflector());

  Module.withReflector(reflector) : super.withReflector(reflector);
}
