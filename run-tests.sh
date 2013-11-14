#!/bin/sh -v

# run type factories generator for tests
./test_tf_gen.sh

# run tests in dart
dart --checked test/main.dart

# run dart2js on tests
dart2js -c test/main.dart -o test/main.dart.js

# run tests in node
node test/main.dart.js
