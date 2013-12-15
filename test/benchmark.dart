library di.bench;

import 'package:di/di.dart';
import 'package:di/dynamic_injector.dart';
import 'package:di/annotations.dart';
import 'package:benchmark_harness/benchmark_harness.dart';

class ClassA {}
class ClassB {}
class ClassC {}

var parent = new DynamicInjector(modules: [new Module()..type(ClassA)]);
var child = parent.createChild([new Module()..type(ClassB)]);
var grandChild = child.createChild([new Module()..type(ClassC)]);

class InjectorTypesBench extends BenchmarkBase {
  const InjectorTypesBench() : super("InjectorTypesBench");

  static void main() {
    new InjectorTypesBench().report();
  }

  // The benchmark code.
  void run() {
    var l = grandChild.types.length;
  }
}

main() {
  InjectorTypesBench.main();
}