#!/bin/sh 
set -e

BENCHMARK=../benchmark_logger.dart-master/run.sh
ENDPOINT_URL=https://glowing-fire-326.firebaseio.com:443

# run tests in dart
dart benchmark/ideal_injector_benchmark.dart
$BENCHMARK $ENDPOINT_URL $(dart benchmark/no_injector_benchmark.dart)
$BENCHMARK $ENDPOINT_URL $(dart benchmark/ideal_injector_benchmark.dart)
$BENCHMARK $ENDPOINT_URL $(dart benchmark/module_benchmark.dart)
$BENCHMARK $ENDPOINT_URL $(dart benchmark/dynamic_injector_benchmark.dart)
$BENCHMARK $ENDPOINT_URL $(dart benchmark/static_injector_benchmark.dart)

# run dart2js on tests
mkdir -p out
dart2js --minify benchmark/ideal_injector_benchmark.dart -o out/no_injector_benchmark.dart.js
dart2js --minify benchmark/ideal_injector_benchmark.dart -o out/ideal_injector_benchmark.dart.js
dart2js --minify benchmark/module_benchmark.dart -o out/module_benchmark.dart.js
dart2js --minify benchmark/static_injector_benchmark.dart -o out/static_injector_benchmark.dart.js
dart2js --minify benchmark/dynamic_injector_benchmark.dart -o out/dynamic_injector_benchmark.dart.js 

# run tests in node
$BENCHMARK $ENDPOINT_URL $(node out/no_injector_benchmark.dart.js)
$BENCHMARK $ENDPOINT_URL $(node out/ideal_injector_benchmark.dart.js)
$BENCHMARK $ENDPOINT_URL $(node out/module_benchmark.dart.js)
$BENCHMARK $ENDPOINT_URL $(node out/dynamic_injector_benchmark.dart.js)
$BENCHMARK $ENDPOINT_URL $(node out/static_injector_benchmark.dart.js)
