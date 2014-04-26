[![Build Status](https://drone.io/github.com/angular/di.dart/status.png)](https://drone.io/github.com/angular/di.dart/latest)

# Dependency Injection (DI) framework

## Installation

Add dependency to your pubspec.yaml.

    dependencies:
      di: ">=0.0.39 <0.1.0"

Then, run `pub install`.

Import di.

    import 'package:di/di.dart';
    import 'package:di/auto_injector.dart';

## Example

```dart
import 'package:di/di.dart';
import 'package:di/auto_injector.dart';

abstract class Engine {
  go();
}

class V8Engine implements Engine {
  go() {
    print('Vroom...');
  }
}

class ElectricEngine implements Engine {
  go() {
    print('Hum...');
  }
}

// Annotation
class Electric {
  const Electric();
}

class GenericCar {
  Engine engine;

  GenericCar(this.engine);

  drive() {
    engine.go();
  }
}

class ElectricCar {
  Engine engine;

  ElectricCar(@Electric() this.engine);

  drive() {
    engine.go();
  }
}

void main() {
  var injector = defaultInjector(modules: [new Module()
      ..bind(GenericCar)
      ..bind(ElectricCar)
      ..bind(Engine, toFactory: (i) => new V8Engine())
      ..bind(Engine, toImplementation: ElectricEngine, withAnnotation: Electric)
  ]);
  injector.get(GenericCar).drive();
  injector.get(ElectricCar).drive();
}
```

