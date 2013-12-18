#!/bin/sh -v
set -e

# run type factories generator for tests
./test_tf_gen.sh

# run tests in dart
dart --checked test/main.dart

# run dart2js on tests
mkdir -p out
dart2js -c test/main.dart -o out/main.dart.js

# run tests in node
node out/main.dart.js
