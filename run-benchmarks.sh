#!/bin/sh -v
set -e

# run tests in dart
dart benchmark/module_benchmark.dart
dart benchmark/dynamic_injector_benchmark.dart
dart benchmark/static_injector_benchmark.dart

# run dart2js on tests
mkdir -p out
dart2js -c benchmark/module_benchmark.dart   -o out/module_benchmark.dart.js
dart2js -c benchmark/static_injector_benchmark.dart   -o out/static_injector_benchmark.dart.js
dart2js -c benchmark/dynamic_injector_benchmark.dart   -o out/dynamic_injector_benchmark.dart.js

# run tests in node
node out/module_benchmark.dart.js
node out/static_injector_benchmark.dart.js
node out/dynamic_injector_benchmark.dart.js
