#!/bin/sh -v
set -e

# run tests in dart
dart benchmark/injector_benchmark.dart

# run dart2js on tests
mkdir -p out
dart2js -c benchmark/injector_benchmark.dart   -o out/injector_benchmark.dart.js

# run tests in node
node out/injector_benchmark.dart.js
