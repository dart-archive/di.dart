#!/bin/sh
set -e

echo "Running generator..."
./test_tf_gen.sh

echo "Running tests in Dart..."
dart --checked test/main.dart
dart --checked test/transformer_test.dart

echo "Compiling tests to JavaScript with dart2js..."
mkdir -p out
dart2js --minify -c test/main.dart -o out/main.dart.js

echo "Running compiled tests in node..."
node out/main.dart.js

echo "Testing complete."
