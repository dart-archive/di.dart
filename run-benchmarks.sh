#!/bin/sh 
set -e

MODULE_BENCHMARK_URL="https://glowing-fire-326.firebaseio.com:443/di/moduleInjector.json"
STATIC_INJECTOR_URL="https://glowing-fire-326.firebaseio.com:443/di/staticInjector.json"
DYNAMIC_INJECTOR_URL="https://glowing-fire-326.firebaseio.com:443/di/dynamicInjector.json"
# run tests in dart
dart benchmark/module_benchmark.dart $MODULE_BENCHMARK_URL
dart benchmark/dynamic_injector_benchmark.dart $DYNAMIC_INJECTOR_URL
dart benchmark/static_injector_benchmark.dart $STATIC_INJECTOR_URL

# run dart2js on tests
mkdir -p out
dart2js --minify benchmark/module_benchmark.dart --categories=Server -o out/module_benchmark.dart.js
dart2js --minify benchmark/static_injector_benchmark.dart  --categories=Server -o out/static_injector_benchmark.dart.js
dart2js --minify benchmark/dynamic_injector_benchmark.dart  --categories=Server -o out/dynamic_injector_benchmark.dart.js 

# run tests in node
node out/module_benchmark.dart.js $MODULE_BENCHMARK_URL
node out/dynamic_injector_benchmark.dart.js $DYNAMIC_INJECTOR_URL
node out/static_injector_benchmark.dart.js $STATIC_INJECTOR_URL
