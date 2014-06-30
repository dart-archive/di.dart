import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:di/di.dart';
import 'package:di/static_injector.dart';
import 'generated_classes.dart';

import 'dart:math';

class LargeBenchmark extends BenchmarkBase {
  var injectorFactory;
  Injector rootInjector;
  Injector leafInjector;
  var leafKey;
  var rng = new Random();
  var numInjectors = 1;
  var allLeaves = [];

  LargeBenchmark(name, this.injectorFactory) : super(name);

  setup() {
    var rootModule = new Module()
      ..bindByKey(key999)
      ..bindByKey(key998)
      ..bindByKey(key997)
      ..bindByKey(key996)
      ..bindByKey(key995);
    rootInjector = injectorFactory([rootModule]);

    createChildren (injector, depth, width) {
      if (depth <= 0){
        allLeaves.add(injector);
        return;
      }
      for (var i=0; i<width; i++){
        var module = new Module();
        for (var j=0; j<5; j++){
          leafKey = allKeys[rng.nextInt(995)];
          module.bindByKey(leafKey);
        }
        leafInjector = injector.createChild([module]);
        numInjectors++;
        createChildren(leafInjector, depth-1, width);
      }
    }

    createChildren(rootInjector, 5, 5);
    print("$numInjectors injectors created.");
  }
}

class GetFromRoot extends LargeBenchmark {
  GetFromRoot() : super('FromRoot', (m) => new StaticInjector(modules: m, typeFactories: typeFactories));

  run() {
    leafInjector.getByKey(key999);
  }
}

class GetFromLeaf extends LargeBenchmark {
  GetFromLeaf() : super('FromLeaf', (m) => new StaticInjector(modules: m, typeFactories: typeFactories));

  run() {
    leafInjector.getByKey(leafKey);
  }
}

main() {
  new GetFromRoot().report();
  new GetFromLeaf().report();
}
