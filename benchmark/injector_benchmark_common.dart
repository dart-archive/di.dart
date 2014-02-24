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
  var _testA;
  var _testB;

  InjectorBenchmark(name, this.injectorFactory, ScoreEmitter emitter) : super(name, emitter: emitter);

  void run() {
    Injector injector = injectorFactory([module]);
    _testA = injector.get(A);
    _testB = injector.get(B);

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

  teardown() {
    if ("${_testA}" != "A(B(D, E), C)") throw "Something went wrong";
    if ("${_testB}" != "B(D, E)") throw "Something went wrong";
  }
}

class A {
  B b;
  C c;
  A(this.b, this.c) {
    count++;
  }

  toString() {
    return "A(${b}, ${c})";
  }
}

class B {
  D d;
  E e;
  B(this.d, this.e) {
    count++;
  }

  toString() {
    return "B(${d}, ${e})";
  }
}

class C {
  C() {
    count++;
  }

  toString() {
    return "C";
  }
}

class D {
  D() {
    count++;
  }

  toString() {
    return "D";
  }
}

class E {
  E() {
    count++;
  }

  toString() {
    return "E";
  }
}
