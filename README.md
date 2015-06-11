[![Build Status](https://travis-ci.org/angular/di.dart.svg?branch=master)](https://travis-ci.org/angular/di.dart)

# Dependency Injection (DI) framework

## Installation

Add dependency to your pubspec.yaml.

    dependencies:
      di: ">=3.3.4 <4.0.0"

Then, run `pub install`.

Import di.

    import 'package:di/di.dart';

## Example

```dart
import 'package:di/di.dart';

abstract class Engine {
  go();
}

class Fuel {}

class V8Engine implements Engine {
  Fuel fuel;
  V8Engine(this.fuel);

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
  var injector = new ModuleInjector([new Module()
      ..bind(Fuel)
      ..bind(GenericCar)
      ..bind(ElectricCar)
      ..bind(Engine, toFactory: (fuel) => new V8Engine(fuel), inject: [Fuel])
      ..bind(Engine, toImplementation: ElectricEngine, withAnnotation: const Electric())
  ]);
  injector.get(GenericCar).drive(); // Vroom...
  injector.get(ElectricCar).drive(); // Hum...
}
```

## Contributing

Refer to the guidelines for [contributing to AngularDart](http://goo.gl/nrXVgm).
