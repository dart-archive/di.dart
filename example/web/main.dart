import 'package:di/di.dart';
import 'package:di/annotations.dart';

@Injectable()
class Application {
  run() {
    print('Success');
  }
}

main() {
  Module module = new Module();
  module.bind(Application);
  new ModuleInjector([module]).get(Application).run();
}
