import 'package:di/di.dart';
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:di/src/reflector_static.dart';

import 'injector_benchmark_common.dart';
import 'static_injector_benchmark.dart';

import 'dart:profiler';

/**
 * This benchmark creates the same objects as the StaticInjectorBenchmark
 * without using DI, to serve as a baseline for comparison.
 */
class CreateObjectsOnly extends BenchmarkBase {
  CreateObjectsOnly(name) : super(name);

  void run() {
    var b1 = new B(new D(), new E());
    var c1 = new C();
    var d1 = new D();
    var e1 = new E();

    var a = new A(b1, c1);
    var b = new B(d1, e1);

    var c = new A(b1, c1);
    var d = new B(d1, e1);
  }

  void teardown() {
    print(count);
  }
}

class CreateSingleInjector extends InjectorBenchmark {

  CreateSingleInjector(name, injectorFactory) : super(name, injectorFactory);

  void run() {
    Injector injector = new ModuleInjector([module]);

    var b1 = new B(new D(), new E());
    var c1 = new C();
    var d1 = new D();
    var e1 = new E();

    var a = new A(b1, c1);
    var b = new B(d1, e1);

    var c = new A(b1, c1);
    var d = new B(d1, e1);
  }
}

class CreateInjectorAndChild extends InjectorBenchmark {

  CreateInjectorAndChild(name, injectorFactory) : super(name, injectorFactory);

  void run() {
    Injector injector = new ModuleInjector([module]);
    var childInjector = injector.createChild([module]);

    var b1 = new B(new D(), new E());
    var c1 = new C();
    var d1 = new D();
    var e1 = new E();

    var a = new A(b1, c1);
    var b = new B(d1, e1);

    var c = new A(b1, c1);
    var d = new B(d1, e1);
  }
}

class InjectByKey extends InjectorBenchmark {

  InjectByKey(name, injectorFactory)
    : super(name, injectorFactory);

  void run() {
    var injector = new ModuleInjector([module]);
    var childInjector = new ModuleInjector([module], injector);

    injector.getByKey(KEY_A);
    injector.getByKey(KEY_B);

    childInjector.getByKey(KEY_A);
    childInjector.getByKey(KEY_B);
  }
}

main() {
  var oldTypeFactories = {
      A: (f) => new A(f(B), f(C)),
      B: (f) => new B(f(D), f(E)),
      C: (f) => new C(),
      D: (f) => new D(),
      E: (f) => new E(),
  };

  const PAD_LENGTH = 35;
  GeneratedTypeFactories generatedTypeFactories =
      new GeneratedTypeFactories(typeFactories, paramKeys);

  new CreateObjectsOnly("Create objects manually without DI".padRight(PAD_LENGTH)).report();
  new CreateSingleInjector('.. and create an injector'.padRight(PAD_LENGTH),
      generatedTypeFactories
  ).report();
  new CreateInjectorAndChild('.. and a child injector'.padRight(PAD_LENGTH),
      generatedTypeFactories
  ).report();
  new InjectorBenchmark('DI using ModuleInjector'.padRight(PAD_LENGTH),
      generatedTypeFactories
  ).report();
  new InjectByKey('.. and precompute keys'.padRight(PAD_LENGTH),
      generatedTypeFactories
  ).report();
}
