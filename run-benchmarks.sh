#!/bin/sh 
set -e

BENCHMARK=../benchmark_logger.dart-master/run.sh
# run tests in dart
$BENCHMARK $(dart benchmark/module_benchmark.dart)
$BENCHMARK $(dart benchmark/dynamic_injector_benchmark.dart)
$BENCHMARK $(dart benchmark/static_injector_benchmark.dart)

# run dart2js on tests
mkdir -p out
dart2js benchmark/module_benchmark.dart -o out/module_benchmark.dart.js
dart2js benchmark/static_injector_benchmark.dart -o out/static_injector_benchmark.dart.js
dart2js benchmark/dynamic_injector_benchmark.dart -o out/dynamic_injector_benchmark.dart.js 

# run tests in node
$BENCHMARK $(node out/module_benchmark.dart.js)
$BENCHMARK $(node out/dynamic_injector_benchmark.dart.js)
$BENCHMARK $(node out/static_injector_benchmark.dart.js)
