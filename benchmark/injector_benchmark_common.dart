library di.injector_benchmark_common;

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:di/di.dart';

int count = 0;

class NoInjectorBenchmark extends BenchmarkBase {
  NoInjectorBenchmark(name, emitter) : super(name, emitter: emitter);

  void run() {
    new A(new B(new D(), new E()), new C());
    new B(new D(), new E());
  }
}

class IdealFunctionBasedInjector {
  var factories;

  IdealFunctionBasedInjector() {
    factories = {
      A: (i) => new A(i.get(B), i.get(C)),
          B: (i) => new B(i.get(D), i.get(E)),
          C: (i) => new C(),
          D: (i) => new D(),
          E: (i) => new E()
    };
  }

  get(type) {
    return factories[type](this);
  }
}

class IdealObjectBasedInjector {
  var factories;

  IdealObjectBasedInjector() {
    factories = {
      A: new A(this.get(B), this.get(C)),
      B: new B(this.get(D), this.get(E)),
      C: new C(),
      D: new D(),
      E: new E()
    };
  }

  get(type) {
    return factories[type];
  }
}

class IdealizedHashMapBasedInjectorBenchmark extends BenchmarkBase {
  var injectorFactory;

  IdealizedHashMapBasedInjectorBenchmark(name, emitter) : super(name, emitter: emitter);

  void run() {
    var injector = new IdealFunctionBasedInjector();
    injector.get(A);
    injector.get(B);
  }
}

class InjectorBenchmark extends BenchmarkBase {
  var injectorFactory;
  var module;

  InjectorBenchmark(name, this.injectorFactory, ScoreEmitter emitter) : super(name, emitter: emitter);

  void run() {
    Injector injector = injectorFactory([module]);
    injector.get(A);
    injector.get(B);

    // TODO(@marko): figure out what to do with this!
//    var childInjector = injector.createChild([module]);
//    childInjector.get(A);
//    childInjector.get(B);
  }

  setup() {
    module = new Module()
      ..type(A)
      ..type(B)
      ..type(C)
      ..type(D)
      ..type(E);
  }

  teardown() { }
}

class A {
  A(B b, C c) {
    count++;
  }
}

class B {
  B(D b, E c) {
    count++;
  }
}

class C {
  C() {
    count++;
  }
}

class D {
  D() {
    count++;
  }
}

class E {
  E() {
    count++;
  }
}
