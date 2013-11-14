#!/bin/sh

./test_tf_gen.sh
dart --checked test/main.dart
dart2js -c test/main.dart -o test/main.dart.js
node test/main.dart.js
