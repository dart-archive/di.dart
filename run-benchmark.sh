#!/bin/sh -v
set -e

# run tests in dart
dart test/benchmark.dart

# run dart2js on tests
dart2js test/benchmark.dart -o test/benchmark.dart.js

# run tests in node
node test/benchmark.dart.js
