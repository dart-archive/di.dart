import 'src/module.dart';
import 'src/reflector.dart';
import 'src/reflector_dynamic.dart';

class Module extends BaseModule {
  static TypeReflector DEFAULT_REFLECTOR = new DynamicTypeFactories();
  final TypeReflector reflector;
  Module(): this.reflector = DEFAULT_REFLECTOR;
}
