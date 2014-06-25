import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:di/di.dart';
import 'package:di/src/reflector_static.dart';
import 'generated_files/factories.dart';

import 'dart:math';

class LargeBenchmark extends BenchmarkBase {
  var injectorFactory;
  Injector rootInjector;
  Injector leafInjector;
  var leafKey;
  var rng = new Random();
  var numInjectors = 1;
  var allLeaves = [];

  LargeBenchmark(name, this.injectorFactory) : super("Large" + name);

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
  GetFromRoot() : super('FromRoot', (m) => new ModuleInjector(m));

  run() {
    leafInjector.getByKey(key999);
  }
}

class GetFromLeaf extends LargeBenchmark {
  GetFromLeaf() : super('FromLeaf', (m) => new ModuleInjector(m));

  run() {
    leafInjector.getByKey(leafKey);
  }
}

main() {
  Module.DEFAULT_REFLECTOR = new GeneratedTypeFactories(typeFactories, parameterKeys);
  new GetFromRoot().report();
  new GetFromLeaf().report();
}
