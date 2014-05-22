library di.injector_benchmark_common;

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:di/di.dart';

int count = 0;

class InjectorBenchmark extends BenchmarkBase {
  var injectorFactory;
  var module;

  InjectorBenchmark(name, this.injectorFactory) : super(name);

  void run() {
    Injector injector = injectorFactory([module]);
    injector.get(A);
    injector.get(B);

    var childInjector = injector.createChild([module]);
    childInjector.get(A);
    childInjector.get(B);
  }

  setup() {
    module = new Module()
      ..bind(A)
      ..bind(B)
      ..bind(C)
      ..bind(C, withAnnotation: AnnOne, toImplementation: COne )
      ..bind(D)
      ..bind(E)
      ..bind(E, withAnnotation: AnnTwo, toImplementation: ETwo )
      ..bind(F)
      ..bind(G);
  }

  teardown() {
    print(count);
  }
}

class AnnOne {
  const AnnOne();
}

class AnnTwo {
  const AnnTwo();
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

class COne {
  COne() {
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

class ETwo {
  ETwo() {
    count++;
  }
}

class F {
  F(@AnnOne() C c, D d) {
    count++;
  }
}

class G {
  G(@AnnTwo() E) {
    count++;
  }
}
