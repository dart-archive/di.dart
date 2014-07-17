import 'package:di/di.dart';
import 'package:di/dynamic_injector.dart';
import 'package:di/annotations.dart';
import 'dart:html';

@Injectable()
class Application {
  run() {
    print('Success');
  }
}

main() {
  Module module = new Module();
  module.bind(Application);
  new DynamicInjector(modules: [module]).get(Application).run();
}
