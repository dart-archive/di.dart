import 'package:di/di.dart';
import 'package:di/di_dynamic.dart';
import 'dart:html';

@Injectable()
class Application {
  run() {
    window.alert("WORKS");
  }
}

main() {
  setupModuleTypeReflector();
  Module module = new Module();
  module.bind(Application);
  new ModuleInjector([module]).get(Application).run();
}
